import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/remote/session_signal.dart';
import '../../data/repositories/sync_coordinator.dart';
import 'auth_controller.dart';

/// How often a cloud phone re-reads its stores and permissions when nothing
/// has prompted it to.
const Duration accountCheckInterval = Duration(minutes: 15);

/// Keeps this phone's idea of its stores and permissions current while it is
/// signed in to the cloud: on opening, every quarter hour, and at once when
/// the store's live connection says the owner changed someone's access.
///
/// A change of access is followed by a sync, which is what brings - or takes
/// away - the figures the new permissions allow.
final accountWatcherProvider = Provider<void>((ref) {
  final active = ref.watch(
    currentSessionProvider.select(
      (session) => session != null && session.isCloud && !session.ended,
    ),
  );
  if (!active) return;

  var disposed = false;
  Future<void> check() async {
    try {
      final changed = await ref
          .read(authControllerProvider.notifier)
          .refreshAccount();
      if (changed && !disposed) {
        await ref.read(syncCoordinatorProvider.notifier).syncNow(force: true);
      }
    } on Object {
      // Offline, most likely. The last known access stands until next time.
    }
  }

  unawaited(Future.microtask(check));
  final timer = Timer.periodic(accountCheckInterval, (_) => check());
  ref.listen(accessChangedSignalProvider, (_, _) => check());

  ref.onDispose(() {
    disposed = true;
    timer.cancel();
  });
});
