import 'storage_mode.dart';

/// Build-time configuration. Supplied with `--dart-define` so one binary can
/// point at staging or production without a code change.
abstract final class AppConfig {
  static const String appName = 'Kitaza';

  static const String apiBaseUrl = String.fromEnvironment(
    'KITAZA_API_URL',
    defaultValue: 'http://10.0.2.2:8080/api/v1',
  );

  static const String realtimeBaseUrl = String.fromEnvironment(
    'KITAZA_WS_URL',
    defaultValue: 'ws://10.0.2.2:8080',
  );

  static const StorageMode defaultStorageMode = StorageMode.local;

  static const Duration requestTimeout = Duration(seconds: 15);
  static const Duration syncInterval = Duration(minutes: 2);

  /// Local database file name, kept stable across releases.
  static const String databaseFile = 'kitaza.db';

  /// Must match the newest step in `SchemaMigrations`.
  static const int databaseVersion = 4;
}
