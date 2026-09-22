import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A counter that every read-side provider watches. Any write - local, pulled
/// from the cloud, or announced over the websocket - bumps it, and the screens
/// that care refresh themselves.
///
/// Cheaper and far easier to follow than having each screen subscribe to a
/// stream per table.
class DataRevision extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state = state + 1;
}

final dataRevisionProvider = NotifierProvider<DataRevision, int>(
  DataRevision.new,
);
