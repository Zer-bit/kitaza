/// One distinct error seen on this phone, however many times it happened.
class ErrorReport {
  const ErrorReport({
    required this.id,
    required this.fingerprint,
    required this.errorType,
    required this.message,
    required this.occurrences,
    required this.firstSeen,
    required this.lastSeen,
    required this.appVersion,
    required this.platform,
    this.stack,
  });

  final String id;
  final String fingerprint;
  final String errorType;
  final String message;
  final String? stack;
  final int occurrences;
  final DateTime firstSeen;
  final DateTime lastSeen;
  final String appVersion;
  final String platform;

  factory ErrorReport.fromRow(Map<String, Object?> row) => ErrorReport(
    id: row['id'] as String,
    fingerprint: row['fingerprint'] as String,
    errorType: row['error_type'] as String,
    message: row['message'] as String,
    stack: row['stack'] as String?,
    occurrences: row['occurrences'] as int? ?? 1,
    firstSeen: DateTime.parse(row['first_seen'] as String),
    lastSeen: DateTime.parse(row['last_seen'] as String),
    appVersion: row['app_version'] as String,
    platform: row['platform'] as String,
  );

  Map<String, Object?> toJson() => {
    'fingerprint': fingerprint,
    'error_type': errorType,
    'message': message,
    'stack': stack,
    'occurrences': occurrences,
    'first_seen': firstSeen.toUtc().toIso8601String(),
    'last_seen': lastSeen.toUtc().toIso8601String(),
    'app_version': appVersion,
    'platform': platform,
  };

  /// Plain text for an owner to paste into a message to support.
  String toSupportText() => [
    '$errorType ($occurrences×, last ${lastSeen.toUtc().toIso8601String()})',
    message,
    'Kitaza $appVersion on $platform',
    if (stack != null) stack!.split('\n').take(12).join('\n'),
  ].join('\n');
}
