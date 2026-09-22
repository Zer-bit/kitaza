import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/config/storage_mode.dart';
import '../../core/storage/preferences_store.dart';
import '../../core/storage/secure_token_store.dart';
import '../local/dao/session_dao.dart';
import '../local/database/local_database.dart';
import '../models/auth_session.dart';
import '../models/owner_account.dart';
import '../models/store_profile.dart';
import '../remote/auth_api.dart';
import 'store_scope.dart';

/// Owns everything about "who is using this device".
///
/// The rule that shapes this class: a device that has been set up once should
/// open straight into the dashboard forever after. Local mode has nothing to
/// check; cloud mode holds a six-month refresh token and renews it silently.
class SessionRepository {
  SessionRepository({
    required this._sessionDao,
    required this._preferences,
    required this._tokens,
    required this._authApi,
    required this._database,
  });

  final SessionDao _sessionDao;
  final PreferencesStore _preferences;
  final SecureTokenStore _tokens;
  final AuthApi _authApi;
  final LocalDatabase _database;

  static const Uuid _uuid = Uuid();

  /// Called once at startup. Returns null only when the device has never been
  /// set up, or when a cloud session was explicitly signed out.
  Future<AuthSession?> restore() async {
    if (!_preferences.readOnboarded()) return null;

    final mode = StorageMode.parse(_preferences.readStorageMode());
    final owner = await _sessionDao.readOwner();
    final storeId = _preferences.readActiveStoreId();
    if (owner == null || storeId == null) return null;

    final store = await _sessionDao.readStore(storeId);
    if (store == null) return null;

    if (mode == StorageMode.local) {
      return AuthSession(owner: owner, store: store, mode: mode);
    }

    final refreshToken = await _tokens.readRefreshToken();
    if (refreshToken == null) return null;

    // The access token may well be stale. That is fine: the interceptor
    // refreshes it on the first call that needs it, and the owner sees the
    // dashboard immediately either way.
    return AuthSession(
      owner: owner,
      store: store,
      mode: mode,
      accessToken: await _tokens.readAccessToken(),
      refreshToken: refreshToken,
    );
  }

  /// Sets up a device that will never talk to a server. No password, because
  /// there is nothing remote to protect and a forgotten one would lock the
  /// owner out of their own records.
  Future<AuthSession> startLocal({
    required String ownerName,
    required String storeName,
  }) async {
    final owner = OwnerAccount(id: _uuid.v4(), fullName: ownerName.trim());
    final store = StoreProfile(id: _uuid.v4(), name: storeName.trim());

    await _persist(owner, store, StorageMode.local);

    return AuthSession(owner: owner, store: store, mode: StorageMode.local);
  }

  Future<AuthSession> register({
    required String email,
    required String password,
    required String fullName,
    required String storeName,
  }) async {
    final body = await _authApi.register(
      email: email.trim(),
      password: password,
      fullName: fullName.trim(),
      storeName: storeName.trim(),
      deviceTag: await _deviceTag(),
    );

    return _acceptCloudSession(body);
  }

  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    final body = await _authApi.signIn(
      email: email.trim(),
      password: password,
      deviceTag: await _deviceTag(),
    );

    return _acceptCloudSession(body);
  }

  /// Moves a store that has only ever lived on this device into the cloud,
  /// either as a new account or into an existing one.
  ///
  /// Local rows keep their ids and are re-scoped to the cloud store's id.
  /// Every local write was already queued in the outbox, so the first sync
  /// uploads the complete history - including the stock ledger - through the
  /// same tested path as any other push.
  Future<AuthSession> upgradeToCloud({
    required String email,
    required String password,
    required bool createAccount,
    required String fullName,
    required String storeName,
  }) async {
    final localStoreId = _preferences.readActiveStoreId();

    final body = createAccount
        ? await _authApi.register(
            email: email.trim(),
            password: password,
            fullName: fullName.trim(),
            storeName: storeName.trim(),
            deviceTag: await _deviceTag(),
          )
        : await _authApi.signIn(
            email: email.trim(),
            password: password,
            deviceTag: await _deviceTag(),
          );

    final session = AuthSession.fromJson(body, mode: StorageMode.cloud);

    await _tokens.saveTokens(
      accessToken: session.accessToken ?? '',
      refreshToken: session.refreshToken ?? '',
    );

    await _database.db.transaction((txn) async {
      await SessionDao(txn).adoptCloudStore(
        fromStoreId: localStoreId ?? '',
        store: session.store,
        owner: session.owner,
      );
    });

    await _preferences.clearSyncCursor();
    await _persist(session.owner, session.store, StorageMode.cloud);
    return session;
  }

  /// Signing out always clears this device.
  ///
  /// In cloud mode the records are safe on the server and come back with a
  /// full download on the next sign-in. Leaving them - and the outbox - behind
  /// would mean the next person to sign in on this phone uploads the previous
  /// owner's unsent entries into their own store. Callers warn about unsent
  /// changes before getting here.
  Future<void> signOut() async {
    final refreshToken = await _tokens.readRefreshToken();
    if (refreshToken != null) {
      try {
        await _authApi.signOut(refreshToken);
      } on Object {
        // Signing out locally must succeed even with no connection.
      }
    }

    await _tokens.clear();
    await _preferences.clearSession();
    await _sessionDao.wipe(_database.db);
  }

  Future<AuthSession> _acceptCloudSession(Map<String, dynamic> body) async {
    final session = AuthSession.fromJson(body, mode: StorageMode.cloud);

    await _tokens.saveTokens(
      accessToken: session.accessToken ?? '',
      refreshToken: session.refreshToken ?? '',
    );
    await _persist(session.owner, session.store, StorageMode.cloud);

    return session;
  }

  Future<void> _persist(
    OwnerAccount owner,
    StoreProfile store,
    StorageMode mode,
  ) async {
    await _sessionDao.saveOwner(owner);
    await _sessionDao.saveStore(store);
    await _preferences.writeStorageMode(mode.name);
    await _preferences.writeActiveStoreId(store.id);
    await _preferences.writeOnboarded(true);
  }

  /// A human-readable label so an owner can recognise their own devices in a
  /// future "signed-in devices" screen.
  Future<String> _deviceTag() async {
    if (kIsWeb) return 'web';
    return Platform.operatingSystem;
  }
}

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepository(
    sessionDao: SessionDao(ref.watch(databaseProvider)),
    preferences: ref.watch(preferencesStoreProvider),
    tokens: ref.watch(secureTokenStoreProvider),
    authApi: ref.watch(authApiProvider),
    database: ref.watch(localDatabaseProvider),
  );
});
