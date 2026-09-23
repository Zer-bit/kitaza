import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/storage_mode.dart';
import '../../data/models/access_grant.dart';
import '../../data/models/auth_session.dart';
import '../../data/models/store_profile.dart';
import '../../data/models/subscription.dart';
import '../../data/remote/session_signal.dart';
import '../../data/remote/team_api.dart';
import '../../data/repositories/session_repository.dart';
import '../../data/repositories/store_scope.dart';
import '../../data/repositories/sync_coordinator.dart';

/// The app's single source of truth for who is signed in.
///
/// `build` runs once at startup and resolves to the restored session, which is
/// what lets a returning device skip the sign-in screen entirely.
class AuthController extends AsyncNotifier<AuthSession?> {
  @override
  Future<AuthSession?> build() {
    ref.listen(sessionLostSignalProvider, (_, _) => sessionEnded());
    return ref.read(sessionRepositoryProvider).restore();
  }

  SessionRepository get _sessions => ref.read(sessionRepositoryProvider);

  Future<void> continueOffline({
    required String ownerName,
    required String storeName,
  }) async {
    await _attempt(
      () => _sessions.startLocal(ownerName: ownerName, storeName: storeName),
    );
  }

  Future<void> signIn({required String email, required String password}) async {
    await _attempt(() => _sessions.signIn(email: email, password: password));
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    required String storeName,
  }) async {
    await _attempt(
      () => _sessions.register(
        email: email,
        password: password,
        fullName: fullName,
        storeName: storeName,
      ),
    );
  }

  /// A staff member joining with the code their owner shared.
  Future<void> joinStore(String code) async {
    await _attempt(() => _sessions.joinStore(code));
  }

  /// Moves this device's local-only store into the cloud. Unlike sign-in, the
  /// current session stays in place until the upgrade succeeds, so a failure
  /// leaves the owner exactly where they were. Failures are rethrown for the
  /// screen to explain.
  Future<void> upgradeToCloud({
    required String email,
    required String password,
    required bool createAccount,
  }) async {
    final current = state.value;
    final session = await _sessions.upgradeToCloud(
      email: email,
      password: password,
      createAccount: createAccount,
      fullName: current?.owner.fullName ?? 'Owner',
      storeName: current?.store.name ?? 'My store',
    );

    _adopt(session);
    state = AsyncValue.data(session);
  }

  /// Opens another of the owner's stores on this phone.
  Future<void> switchStore(StoreProfile store) async {
    final current = state.value;
    if (current == null || current.store.id == store.id) return;

    await _sessions.switchStore(store);
    final switched = current.copyWith(store: store);
    _adopt(switched);
    state = AsyncValue.data(switched);
  }

  /// Creates a store on the server and switches to it. Needs a connection;
  /// failures are rethrown for the screen to explain.
  Future<void> addStore({
    required String name,
    required String businessType,
  }) async {
    final current = state.value;
    if (current == null) return;

    final store = await ref
        .read(teamApiProvider)
        .addStore(name: name.trim(), businessType: businessType);
    await _sessions.rememberStore(store);

    state = AsyncValue.data(
      current.copyWith(stores: [...current.stores, store]),
    );
    await switchStore(store);
  }

  Future<void> renameStore(StoreProfile store, String name) async {
    final current = state.value;
    if (current == null) return;

    final renamed = await ref
        .read(teamApiProvider)
        .updateStore(store.id, name: name.trim());
    await _rememberStore(current, renamed);
  }

  /// Turns this store's share of the anonymous comparisons on or off.
  Future<void> setBenchmarkSharing(bool sharing) async {
    final current = state.value;
    if (current == null || !current.isCloud || !current.access.isOwner) return;

    final updated = await ref
        .read(teamApiProvider)
        .updateStore(current.store.id, shareBenchmarks: sharing);
    await _rememberStore(current, updated);
  }

  Future<void> _rememberStore(AuthSession current, StoreProfile store) async {
    await _sessions.rememberStore(store);

    state = AsyncValue.data(
      current.copyWith(
        store: current.store.id == store.id ? store : current.store,
        stores: [
          for (final existing in current.stores)
            existing.id == store.id ? store : existing,
        ],
      ),
    );
  }

  /// Picks up stores and permission changes made elsewhere. Returns whether
  /// what this phone may do changed. Failures are left to the caller: this
  /// runs in the background and a stale answer is fine until the next try.
  Future<bool> refreshAccount() async {
    final current = state.value;
    if (current == null || !current.isCloud || current.ended) return false;

    final refreshed = await _sessions.refreshAccount(current);
    if (!ref.mounted || state.value?.owner.id != current.owner.id) {
      return false;
    }
    _adopt(refreshed.session);
    state = AsyncValue.data(refreshed.session);
    return refreshed.accessChanged;
  }

  /// Moves this phone to free, offline use, keeping every record on it.
  Future<void> leaveCloud() async {
    final current = state.value;
    if (current == null || !current.isCloud || !current.access.isOwner) return;

    final local = await _sessions.leaveCloud(current);
    _adopt(local);
    state = AsyncValue.data(local);
  }

  /// The server refused to renew this phone's session: it was signed out
  /// from another device, or its staff member was removed. The records stay
  /// until someone signs back in or chooses to clear them.
  void sessionEnded() {
    final current = state.value;
    if (current == null || !current.isCloud || current.ended) return;
    state = AsyncValue.data(current.copyWith(ended: true));
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    await _sessions.signOut();
    ref.read(activeStoreIdProvider.notifier).clear();
    state = const AsyncValue.data(null);
  }

  /// Keeps the previous session visible while a request is in flight, so the
  /// UI does not flash an empty state on a slow network. Riverpod carries the
  /// previous value into the loading and error states, which is also what
  /// keeps a signed-out phone on its sign-in form after a wrong password.
  Future<void> _attempt(Future<AuthSession> Function() action) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(action);
    if (result.value case final session?) {
      _adopt(session);
      // Signing back in as the same person keeps the store id, so the
      // coordinator would not rebuild on its own after a lost session.
      ref.invalidate(syncCoordinatorProvider);
    }
    state = result;
  }

  /// Points every store-scoped provider at the new session before any screen
  /// that depends on it is shown.
  void _adopt(AuthSession session) {
    ref.read(storageModeProvider.notifier).select(session.mode);
    ref.read(activeStoreIdProvider.notifier).select(session.store.id);
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthSession?>(AuthController.new);

/// The signed-in store, or null. Screens watch this instead of reaching into
/// the async state.
final currentSessionProvider = Provider<AuthSession?>(
  (ref) => ref.watch(authControllerProvider).value,
);

/// Whether this device syncs, for screens that only need a yes or no.
final isCloudModeProvider = Provider<bool>(
  (ref) => ref.watch(storageModeProvider) == StorageMode.cloud,
);

/// Who is using this phone. An offline phone, or no session, is the owner.
final currentAccessProvider = Provider<AccessGrant>((ref) {
  final session = ref.watch(currentSessionProvider);
  return session?.access ?? const AccessGrant.owner('');
});

/// Whether this phone may offer [Permission]. Screens hide what the answer
/// rules out; the server refuses it regardless.
final canProvider = Provider.family<bool, Permission>(
  (ref, permission) => ref.watch(currentAccessProvider).can(permission),
);

/// Staff, stores and devices are managed by the owner, from a cloud account.
final isCloudOwnerProvider = Provider<bool>((ref) {
  final session = ref.watch(currentSessionProvider);
  return session != null && session.isCloud && session.access.isOwner;
});

/// The owner's plan. Unlimited offline and on servers that do not charge.
final subscriptionProvider = Provider<Subscription>(
  (ref) =>
      ref.watch(currentSessionProvider)?.subscription ??
      const Subscription.unlimited(),
);
