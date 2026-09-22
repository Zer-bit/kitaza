/// A failure already translated into something worth showing an owner. The
/// technical cause is kept for logs but never put on screen.
class AppFailure implements Exception {
  const AppFailure(this.message, {this.cause, this.isRetryable = true});

  final String message;
  final Object? cause;
  final bool isRetryable;

  const AppFailure.offline()
    : message =
          'You are offline. Your entry is saved on this device and '
          'will sync when you reconnect.',
      cause = null,
      isRetryable = false;

  const AppFailure.unauthorized()
    : message = 'Your session expired. Please sign in again.',
      cause = null,
      isRetryable = false;

  @override
  String toString() => 'AppFailure($message)';
}
