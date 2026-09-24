import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

extension KeepFor on Ref {
  /// Keeps this provider's result for [duration] after the last screen stops
  /// watching it.
  ///
  /// Moving between tabs closes one screen and opens another. Without this,
  /// every return to a tab starts from nothing: a spinner, the same query
  /// again, and a fade back in. With it, a tab visited in the last few
  /// minutes opens with its figures already there, and anything that changed
  /// meanwhile is fetched and swapped in place.
  void keepFor(Duration duration) {
    final link = keepAlive();
    Timer? release;
    onCancel(() => release = Timer(duration, link.close));
    onResume(() => release?.cancel());
    onDispose(() => release?.cancel());
  }
}

/// Long enough to cover going back and forth between tabs while serving a
/// customer; short enough that nothing is held for a store left alone.
const Duration tabDataLifetime = Duration(minutes: 5);
