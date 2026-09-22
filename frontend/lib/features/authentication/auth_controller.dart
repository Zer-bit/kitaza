import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/auth_session.dart';
import '../../data/repositories/session_repository.dart';

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

  Future<void> signOut({bool eraseLocalData = false}) async {
    state = const AsyncValue.loading();
    await ref
        .read(sessionRepositoryProvider)
        .signOut(eraseLocalData: eraseLocalData);
    state = const AsyncValue.data(null);
  }

  /// Keeps the previous session visible while a request is in flight, so the
  /// UI does not flash an empty state on a slow network.
  Future<void> _attempt(Future<AuthSession> Function() action) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(action);
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthSession?>(AuthController.new);

/// The signed-in store, or null. Screens watch this instead of reaching into
/// the async state.
final currentSessionProvider = Provider<AuthSession?>(
  (ref) => ref.watch(authControllerProvider).value,
);
