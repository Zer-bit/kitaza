import 'storage_mode.dart';

/// Build-time configuration. Supplied with `--dart-define` so one binary can
/// point at staging or production without a code change.
abstract final class AppConfig {
  static const String appName = 'Kitaza';

  /// Where the emulator reaches a server running on the developer's own
  /// machine. Useless on a real phone, which is the point of
  /// [pointsAtDeveloperMachine].
  static const String _developerApi = 'http://10.0.2.2:8080/api/v1';

  static const String apiBaseUrl = String.fromEnvironment(
    'KITAZA_API_URL',
    defaultValue: _developerApi,
  );

  static const String realtimeBaseUrl = String.fromEnvironment(
    'KITAZA_WS_URL',
    defaultValue: 'ws://10.0.2.2:8080',
  );

  /// True when nobody told the build where the API lives. Cloud mode then
  /// tries to reach a laptop that is not there, which looks exactly like a
  /// bad connection. Settings says so plainly rather than leaving an owner
  /// to guess.
  static bool get pointsAtDeveloperMachine => apiBaseUrl == _developerApi;

  static const StorageMode defaultStorageMode = StorageMode.local;

  static const Duration requestTimeout = Duration(seconds: 15);
  static const Duration syncInterval = Duration(minutes: 2);

  /// Local database file name, kept stable across releases.
  static const String databaseFile = 'kitaza.db';

  /// Must match the newest step in `SchemaMigrations`.
  static const int databaseVersion = 4;
}
