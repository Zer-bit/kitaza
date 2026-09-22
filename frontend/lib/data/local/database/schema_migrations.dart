import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Every change to the local schema since version 1, in order.
///
/// A new install builds version 1 and then runs these same steps, exactly as
/// an upgrading phone does, so the two can never end up with different
/// schemas. A step is never edited once released: fixes go in a new step.
abstract final class SchemaMigrations {
  static const Map<int, List<String>> _steps = {
    2: [
      // Crash and error reports, kept until they reach the server or the
      // owner sends them to support. One row per distinct error; repeats
      // bump `occurrences` instead of adding rows.
      '''
      CREATE TABLE error_reports (
        id          TEXT PRIMARY KEY,
        fingerprint TEXT NOT NULL,
        error_type  TEXT NOT NULL,
        message     TEXT NOT NULL,
        stack       TEXT,
        occurrences INTEGER NOT NULL DEFAULT 1,
        first_seen  TEXT NOT NULL,
        last_seen   TEXT NOT NULL,
        app_version TEXT NOT NULL,
        platform    TEXT NOT NULL
      )
      ''',
      'CREATE UNIQUE INDEX error_reports_fingerprint_idx ON error_reports (fingerprint)',
    ],
  };

  static int get latestVersion => _steps.keys.fold(
    1,
    (latest, version) => version > latest ? version : latest,
  );

  static Future<void> migrate(DatabaseExecutor db, int from, int to) async {
    for (var version = from + 1; version <= to; version++) {
      for (final statement in _steps[version] ?? const <String>[]) {
        await db.execute(statement);
      }
    }
  }
}
