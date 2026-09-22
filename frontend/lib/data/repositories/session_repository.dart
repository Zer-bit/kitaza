import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../core/config/storage_mode.dart';
import '../../core/device/device_identity.dart';
import '../../core/storage/preferences_store.dart';
import '../../core/storage/secure_token_store.dart';
import '../local/dao/session_dao.dart';
import '../models/access_grant.dart';
import '../models/auth_session.dart';
import '../models/owner_account.dart';
import '../models/store_profile.dart';
import '../remote/auth_api.dart';
import 'store_scope.dart';

/// What changed when the server re-described this phone's access.
class AccountRefresh {
  const AccountRefresh({required this.session, required this.accessChanged});

  final AuthSession session;
  final bool accessChanged;
}

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
    required this._db,
    required this._device,
  });

  final SessionDao _sessionDao;
  final PreferencesStore _preferences;
  final SecureTokenStore _tokens;
  final AuthApi _authApi;
  final Database _db;
  final DeviceIdentity _device;

  static const Uuid _uuid = Uuid();

  /// Called once at startup. Returns null only when the device has never been
  /// set up, or was deliberately cleared.
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

    final access =
        AccessGrant.decode(_preferences.readAccess()) ??
        AccessGrant.owner(owner.fullName);
    final stores = await _sessionDao.readStores();
    final refreshToken = await _tokens.readRefreshToken();

    // The access token may well be stale. That is fine: the interceptor
    // refreshes it on the first call that needs it, and the owner sees the
    // dashboard immediately either way. No refresh token at all means the
    // server ended this session, which the owner has to see and act on.
    return AuthSession(
      owner: owner,
      store: store,
      stores: stores,
      mode: mode,
      access: access,
      accessToken: await _tokens.readAccessToken(),
      refreshToken: refreshToken,
      ended: refreshToken == null,
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

    await _persist(owner, [store], store, StorageMode.local);

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
      device: await _label(),
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
      device: await _label(),
    );

    return _acceptCloudSession(body);
  }

  /// A staff member's phone joining the store whose owner gave them [code].
  Future<AuthSession> joinStore(String code) async {
    final body = await _authApi.join(code: code.trim(), device: await _label());
    return _acceptCloudSession(body);
  }

  /// Re-reads stores and access from the server, so a store added on another
  /// phone appears here and a permission the owner changed takes effect
  /// without signing out.
  ///
  /// A staff member who gains or loses profit access has their store
  /// downloaded again from scratch: gaining it brings the costs and expenses
  /// the server withheld, and losing it overwrites the costs this phone had.
  /// Expenses and withdrawals they may no longer see are removed.
  Future<AccountRefresh> refreshAccount(AuthSession current) async {
    final body = await _authApi.account();
    final fresh = AuthSession.fromJson(
      body,
      mode: current.mode,
      preferredStoreId: current.store.id,
    );

    final before = current.access;
    final after = fresh.access;
    final seesCostsChanged =
        before.can(Permission.viewProfit) != after.can(Permission.viewProfit);

    if (after.isStaff && seesCostsChanged) {
      if (!after.can(Permission.viewProfit)) {
        await _sessionDao.forgetPrivateRecords(fresh.store.id);
      }
      await _preferences.clearSyncCursor(fresh.store.id);
    }

    await _saveStores(fresh.stores);
    await _sessionDao.saveOwner(fresh.owner);
    await _preferences.writeAccess(after.encode());
    await _preferences.writeActiveStoreId(fresh.store.id);

    return AccountRefresh(
      session: current.copyWith(
        store: fresh.store,
        stores: fresh.stores,
        access: after,
      ),
      accessChanged: before != after,
    );
  }

  /// Opens another of the owner's stores. Its records stay on the phone
  /// alongside the others, so switching back is instant and works offline.
  Future<void> switchStore(StoreProfile store) async {
    await _sessionDao.saveStore(store);
    await _preferences.writeActiveStoreId(store.id);
  }

  Future<void> rememberStore(StoreProfile store) =>
      _sessionDao.saveStore(store);

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
    final device = await _label();

    final body = createAccount
        ? await _authApi.register(
            email: email.trim(),
            password: password,
            fullName: fullName.trim(),
            storeName: storeName.trim(),
            device: device,
          )
        : await _authApi.signIn(
            email: email.trim(),
            password: password,
            device: device,
          );

    final signedIn = AuthSession.fromJson(body, mode: StorageMode.cloud);
    // An existing account may hold several stores; the upgrade always makes
    // a new one or joins the first, and the local records go there.
    final session = signedIn.copyWith(store: signedIn.stores.first);

    await _tokens.saveTokens(
      accessToken: session.accessToken ?? '',
      refreshToken: session.refreshToken ?? '',
    );

    await _db.transaction((txn) async {
      await SessionDao(txn).adoptCloudStore(
        fromStoreId: localStoreId ?? '',
        store: session.store,
        owner: session.owner,
      );
    });

    await _preferences.clearAllSyncCursors();
    await _persist(
      session.owner,
      session.stores,
      session.store,
      StorageMode.cloud,
      access: session.access,
    );
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

    await _clearDevice();
  }

  /// Accepts a session from the server. If someone else was signed in on
  /// this phone before - the previous session having ended - their records
  /// are cleared first; the same person signing back in keeps theirs,
  /// including anything not yet uploaded.
  Future<AuthSession> _acceptCloudSession(Map<String, dynamic> body) async {
    final session = AuthSession.fromJson(
      body,
      mode: StorageMode.cloud,
      preferredStoreId: _preferences.readActiveStoreId(),
    );

    if (!await _isSamePersonAsBefore(session)) await _clearDevice();

    await _tokens.saveTokens(
      accessToken: session.accessToken ?? '',
      refreshToken: session.refreshToken ?? '',
    );
    await _persist(
      session.owner,
      session.stores,
      session.store,
      StorageMode.cloud,
      access: session.access,
    );

    return session;
  }

  Future<bool> _isSamePersonAsBefore(AuthSession incoming) async {
    if (!_preferences.readOnboarded()) return true;

    final previousOwner = await _sessionDao.readOwner();
    if (previousOwner == null) return true;

    final previousAccess =
        AccessGrant.decode(_preferences.readAccess()) ??
        AccessGrant.owner(previousOwner.fullName);

    return StorageMode.parse(_preferences.readStorageMode()).isCloud &&
        previousOwner.id == incoming.owner.id &&
        previousAccess.isSamePersonAs(incoming.access);
  }

  Future<void> _clearDevice() async {
    await _tokens.clear();
    await _preferences.clearSession();
    await _sessionDao.wipe(_db);
  }

  Future<void> _persist(
    OwnerAccount owner,
    List<StoreProfile> stores,
    StoreProfile active,
    StorageMode mode, {
    AccessGrant? access,
  }) async {
    await _sessionDao.saveOwner(owner);
    await _saveStores(stores.isEmpty ? [active] : stores);
    if (access != null) await _preferences.writeAccess(access.encode());
    await _preferences.writeStorageMode(mode.name);
    await _preferences.writeActiveStoreId(active.id);
    await _preferences.writeOnboarded(true);
  }

  Future<void> _saveStores(List<StoreProfile> stores) async {
    for (final store in stores) {
      await _sessionDao.saveStore(store);
    }
  }

  Future<DeviceLabel> _label() async =>
      (tag: _device.tag, name: await _device.name());
}

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepository(
    sessionDao: SessionDao(ref.watch(databaseProvider)),
    preferences: ref.watch(preferencesStoreProvider),
    tokens: ref.watch(secureTokenStoreProvider),
    authApi: ref.watch(authApiProvider),
    db: ref.watch(databaseProvider),
    device: ref.watch(deviceIdentityProvider),
  );
});
