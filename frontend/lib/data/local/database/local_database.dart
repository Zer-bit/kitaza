import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../core/config/app_config.dart';
import 'schema_statements.dart';

/// Opens and configures the on-device SQLite database. Every read and write in
/// the app goes through here, online or not.
class LocalDatabase {
  LocalDatabase._(this.db);

  final Database db;

  static Future<LocalDatabase> open() async {
    _initialiseDesktopSupport();

    final directory = await getApplicationDocumentsDirectory();
    final path = p.join(directory.path, AppConfig.databaseFile);

    final database = await openDatabase(
      path,
      version: AppConfig.databaseVersion,
      onConfigure: _configure,
      onCreate: _create,
      onUpgrade: _upgrade,
    );

    return LocalDatabase._(database);
  }

  static Future<void> _configure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
    // WAL keeps a slow report query from blocking the cashier ringing up a
    // sale, and NORMAL sync is the right durability trade for a phone.
    await db.execute('PRAGMA journal_mode = WAL');
    await db.execute('PRAGMA synchronous = NORMAL');
    await db.execute('PRAGMA temp_store = MEMORY');
  }

  static Future<void> _create(Database db, int version) => applySchema(db);

  /// Creates the full schema on an already-open database. Public so tests can
  /// build the same structure against an in-memory database.
  static Future<void> applySchema(Database db) async {
    final batch = db.batch();
    for (final statement in SchemaStatements.createTables) {
      batch.execute(statement);
    }
    for (final statement in SchemaStatements.createIndexes) {
      batch.execute(statement);
    }
    await batch.commit(noResult: true);
  }

  /// No migrations yet. Each future schema change adds one numbered step here
  /// rather than rebuilding the file, so nobody loses their history.
  static Future<void> _upgrade(Database db, int from, int to) async {}

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
