import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Raised by the network layer when the server refuses to renew this phone's
/// session. The auth controller listens and shows the signed-out screen; the
/// network layer itself knows nothing about screens.
class SessionLostSignal extends Notifier<int> {
  @override
  int build() => 0;

  void raise() => state++;
}

final sessionLostSignalProvider = NotifierProvider<SessionLostSignal, int>(
  SessionLostSignal.new,
);

/// Raised when the store's live connection says access changed, so the phone
/// re-reads what it may do.
class AccessChangedSignal extends Notifier<int> {
  @override
  int build() => 0;

  void raise() => state++;
}

final accessChangedSignalProvider = NotifierProvider<AccessChangedSignal, int>(
  AccessChangedSignal.new,
);
