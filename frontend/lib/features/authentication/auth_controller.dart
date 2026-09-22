import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/storage_mode.dart';
import '../../data/models/auth_session.dart';
import '../../data/repositories/session_repository.dart';
import '../../data/repositories/store_scope.dart';

/// The app's single source of truth for who is signed in.
///
/// `build` runs once at startup and resolves to the restored session, which is
/// what lets a returning device skip the sign-in screen entirely.
class AuthController extends AsyncNotifier<AuthSession?> {
  @override
  Future<AuthSession?> build() => ref.read(sessionRepositoryProvider).restore();

  Future<void> continueOffline({
    required String ownerName,
    required String storeName,
  }) async {
    await _attempt(
      () => ref
          .read(sessionRepositoryProvider)
          .startLocal(ownerName: ownerName, storeName: storeName),
    );
  }

  Future<void> signIn({required String email, required String password}) async {
    await _attempt(
      () => ref
          .read(sessionRepositoryProvider)
          .signIn(email: email, password: password),
    );
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    required String storeName,
  }) async {
    await _attempt(
      () => ref
          .read(sessionRepositoryProvider)
          .register(
            email: email,
            password: password,
            fullName: fullName,
            storeName: storeName,
          ),
    );
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
    final session = await ref
        .read(sessionRepositoryProvider)
        .upgradeToCloud(
          email: email,
          password: password,
          createAccount: createAccount,
          fullName: current?.owner.fullName ?? 'Owner',
          storeName: current?.store.name ?? 'My store',
        );

    _adopt(session);
    state = AsyncValue.data(session);
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    await ref.read(sessionRepositoryProvider).signOut();
    ref.read(activeStoreIdProvider.notifier).clear();
    state = const AsyncValue.data(null);
  }

  /// Keeps the previous session visible while a request is in flight, so the
  /// UI does not flash an empty state on a slow network.
  Future<void> _attempt(Future<AuthSession> Function() action) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(action);
    if (result.value case final session?) _adopt(session);
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
