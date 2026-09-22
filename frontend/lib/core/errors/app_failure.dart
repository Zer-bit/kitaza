/// What went wrong, in the terms the app acts on.
enum FailureKind {
  /// No network, or the server did not answer. Temporary: try again later.
  offline,

  /// The server is up but failing. Also temporary.
  server,

  /// The session is no longer valid. Needs the owner to sign in.
  unauthorized,

  /// The request itself was refused - bad input, a conflict. Retrying the
  /// same thing will get the same answer.
  rejected,
}

/// A failure already translated into something worth showing an owner. The
/// technical cause is kept for logs but never put on screen.
class AppFailure implements Exception {
  const AppFailure(
    this.message, {
    this.kind = FailureKind.rejected,
    this.cause,
  });

  final String message;
  final FailureKind kind;
  final Object? cause;

  /// Whether waiting and trying again could succeed.
  bool get isTransient =>
      kind == FailureKind.offline || kind == FailureKind.server;

  const AppFailure.offline()
    : message =
          'You are offline. Your entry is saved on this device and '
          'will sync when you reconnect.',
      kind = FailureKind.offline,
      cause = null;

  const AppFailure.unauthorized()
    : message = 'Your session expired. Please sign in again.',
      kind = FailureKind.unauthorized,
      cause = null;

  @override
  String toString() => 'AppFailure(${kind.name}: $message)';
}
