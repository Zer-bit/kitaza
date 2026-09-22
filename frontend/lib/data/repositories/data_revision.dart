import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'sync_coordinator.dart';

/// A counter that every read-side provider watches. Any change to local data
/// bumps it, and the screens that care refresh themselves.
///
/// Cheaper and far easier to follow than having each screen subscribe to a
/// stream per table.
class DataRevision extends Notifier<int> {
  @override
  int build() => 0;

  /// Data changed for a reason that needs no upload: a pull from the cloud,
  /// or a pull-to-refresh.
  void bump() => state = state + 1;

  /// The owner just wrote something on this device. Refresh the screens and
  /// get it into the outbox's next push.
  void localWrite() {
    bump();
    ref.read(syncCoordinatorProvider.notifier).schedulePush();
  }
}

final dataRevisionProvider = NotifierProvider<DataRevision, int>(
  DataRevision.new,
);
