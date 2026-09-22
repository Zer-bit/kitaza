import '../core/errors/app_failure.dart';
import 'generated/app_localizations.dart';

extension FailureText on AppLocalizations {
  /// What to tell the owner about [error]. Known server error codes get the
  /// owner's language; anything unrecognised falls back to [fallback] rather
  /// than showing an English server message or a stack trace.
  String failure(Object? error, {String? fallback}) {
    if (error is! AppFailure) return fallback ?? errorGeneric;

    return switch (error.kind) {
      FailureKind.offline => errorOffline,
      FailureKind.server => errorServer,
      FailureKind.unauthorized => errorSessionExpired,
      FailureKind.rejected => switch (error.code) {
        'unauthorized' => errorWrongCredentials,
        'conflict' => errorEmailTaken,
        'too_many_requests' => errorTooManyAttempts,
        _ => fallback ?? errorGeneric,
      },
    };
  }
}
