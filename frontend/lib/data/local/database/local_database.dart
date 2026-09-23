import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../core/config/app_config.dart';
import 'schema_migrations.dart';
import 'schema_statements.dart';

/// Opens and configures the on-device SQLite database. Every read and write in
/// the app goes through here, online or not.
class LocalDatabase {
  LocalDatabase._(this.db, this.path);

  final Database db;

  /// Where the database file lives, for backups.
  final String path;

  static Future<String> defaultPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return p.join(directory.path, AppConfig.databaseFile);
  }

  static Future<LocalDatabase> open() async {
    _initialiseDesktopSupport();

    final path = await defaultPath();

    final database = await openDatabase(
      path,
      version: AppConfig.databaseVersion,
      onConfigure: _configure,
      onCreate: _create,
      onUpgrade: _upgrade,
    );

    return LocalDatabase._(database, path);
  }

  static Future<void> _configure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
    // WAL keeps a slow report query from blocking the cashier ringing up a
    // sale, and NORMAL sync is the right durability trade for a phone.
    // journal_mode returns the resulting mode as a row, and Android's
    // execSQL rejects statements that return data, so this one must go
    // through rawQuery to work on both Android and desktop ffi.
    await db.rawQuery('PRAGMA journal_mode = WAL');
    await db.execute('PRAGMA synchronous = NORMAL');
    await db.execute('PRAGMA temp_store = MEMORY');
  }

  static Future<void> _create(Database db, int version) async {
    await _applyBaseSchema(db);
    await SchemaMigrations.migrate(db, 1, version);
  }

  /// Creates the latest schema on an already-open database. Public so tests
  /// build exactly what a new install builds.
  static Future<void> applySchema(Database db) async {
    await _applyBaseSchema(db);
    await SchemaMigrations.migrate(db, 1, SchemaMigrations.latestVersion);
  }

  /// The original version 1 schema, never changed after release.
  static Future<void> _applyBaseSchema(Database db) async {
    final batch = db.batch();
    for (final statement in SchemaStatements.createTables) {
      batch.execute(statement);
    }
    for (final statement in SchemaStatements.createIndexes) {
      batch.execute(statement);
    }
    await batch.commit(noResult: true);
  }

  /// Brings an existing phone's database forward without touching its data.
  static Future<void> _upgrade(Database db, int from, int to) =>
      SchemaMigrations.migrate(db, from, to);

  static void _initialiseDesktopSupport() {
    if (kIsWeb) return;
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  Future<void> close() => db.close();
}

final localDatabaseProvider = Provider<LocalDatabase>(
  (ref) => throw UnimplementedError('LocalDatabase is provided at startup'),
);
