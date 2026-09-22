import 'dart:async';

/// Delays an action until typing pauses. Used on product search so a
/// low-end phone is not running a query on every keystroke.
class Debouncer {
  Debouncer({this.delay = const Duration(milliseconds: 250)});

  final Duration delay;
  Timer? _timer;

  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() => _timer?.cancel();
}
