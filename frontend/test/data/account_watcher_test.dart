import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitaza_app/data/models/auth_session.dart';
import 'package:kitaza_app/data/remote/session_signal.dart';
import 'package:kitaza_app/data/repositories/session_repository.dart';
import 'package:kitaza_app/data/repositories/sync_coordinator.dart';
import 'package:kitaza_app/features/authentication/account_watcher.dart';
import 'package:kitaza_app/features/authentication/auth_controller.dart';

import '../support/team_fakes.dart';

/// Hands back a cloud session and counts how often the server is asked
/// what this phone may do.
class _FakeSessions implements SessionRepository {
  _FakeSessions(this.session);

  final AuthSession session;
  int refreshes = 0;
  bool changes = true;

  @override
  Future<AuthSession?> restore() async => session;

  @override
  Future<AccountRefresh> refreshAccount(AuthSession current) async {
    refreshes++;
    return AccountRefresh(session: current, accessChanged: changes);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _CountingCoordinator extends SyncCoordinator {
  int syncs = 0;

  @override
  SyncStatus build() => const SyncStatus();

  @override
  Future<void> syncNow({bool force = false}) async => syncs++;
}

void main() {
  late _FakeSessions sessions;
  late _CountingCoordinator coordinator;

  ProviderContainer start(AuthSession session) {
    sessions = _FakeSessions(session);
    final container = ProviderContainer(
      overrides: [
        sessionRepositoryProvider.overrideWithValue(sessions),
        syncCoordinatorProvider.overrideWith(
          () => coordinator = _CountingCoordinator(),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<void> settle() async {
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  test(
    'a staff phone re-reads its access on opening and when told to',
    () async {
      final container = start(staffMember({}));
      await container.read(authControllerProvider.future);
      container.listen(accountWatcherProvider, (_, _) {});
      container.read(syncCoordinatorProvider);
      await settle();
      expect(sessions.refreshes, 1, reason: 'on opening');

      // The owner changed Liza's permissions; the live connection says so.
      container.read(accessChangedSignalProvider.notifier).raise();
      await settle();

      expect(sessions.refreshes, 2);
      expect(
        coordinator.syncs,
        2,
        reason: 'a change of access is followed by a download',
      );
    },
  );

  test('nothing changed, nothing downloaded', () async {
    final container = start(cloudOwner());
    await container.read(authControllerProvider.future);
    sessions.changes = false;
    container.listen(accountWatcherProvider, (_, _) {});
    container.read(syncCoordinatorProvider);
    await settle();

    expect(sessions.refreshes, 1);
    expect(coordinator.syncs, 0);
  });

  test('a phone the server signed out stops asking', () async {
    final container = start(cloudOwner(ended: true));
    await container.read(authControllerProvider.future);
    container.listen(accountWatcherProvider, (_, _) {});
    await settle();

    container.read(accessChangedSignalProvider.notifier).raise();
    await settle();

    expect(sessions.refreshes, 0);
  });
}
