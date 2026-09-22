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

  /// The account is paused until it is paid. Nothing is wrong with the
  /// entry; it waits on the phone.
  paused,
}

/// A failure already translated into something worth showing an owner. The
/// technical cause is kept for logs but never put on screen.
class AppFailure implements Exception {
  const AppFailure(
    this.message, {
    this.kind = FailureKind.rejected,
    this.code,
    this.cause,
  });

  final String message;
  final FailureKind kind;

  /// The server's machine-readable error code, such as `conflict`, so the
  /// screen can explain it in the owner's language.
  final String? code;
  final Object? cause;

  /// Whether waiting and trying again could succeed.
  bool get isTransient =>
      kind == FailureKind.offline || kind == FailureKind.server;

  const AppFailure.offline()
    : message =
          'You are offline. Your entry is saved on this device and '
          'will sync when you reconnect.',
      kind = FailureKind.offline,
      code = null,
      cause = null;

  const AppFailure.unauthorized()
    : message = 'Your session expired. Please sign in again.',
      kind = FailureKind.unauthorized,
      code = null,
      cause = null;

  @override
  String toString() => 'AppFailure(${kind.name}: $message)';
}
