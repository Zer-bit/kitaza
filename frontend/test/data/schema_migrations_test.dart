import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kitaza_app/core/config/app_config.dart';
import 'package:kitaza_app/data/local/database/local_database.dart';
import 'package:kitaza_app/data/local/database/schema_migrations.dart';
import 'package:kitaza_app/data/local/database/schema_statements.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// A phone still on the first released schema, with a sale on it.
Future<String> _versionOnePhone(Directory folder) async {
  final path = p.join(folder.path, 'kitaza.db');
  final db = await databaseFactoryFfi.openDatabase(path);
  for (final statement in [
    ...SchemaStatements.createTables,
    ...SchemaStatements.createIndexes,
  ]) {
    await db.execute(statement);
  }
  await db.insert('stores', {'id': 's', 'name': 'Old Store'});
  await db.insert('sales', {
    'id': 'sale-1',
    'store_id': 's',
    'total_amount': 4200,
    'occurred_at': '2026-01-01T00:00:00Z',
    'updated_at': '2026-01-01T00:00:00Z',
  });
  await db.execute('PRAGMA user_version = 1');
  await db.close();
  return path;
}

Future<Database> _openAsTheAppWould(String path) =>
    databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: AppConfig.databaseVersion,
        singleInstance: false,
        onUpgrade: (db, from, to) => SchemaMigrations.migrate(db, from, to),
      ),
    );

Future<List<String>> _schemaOf(Database db) async {
  final rows = await db.rawQuery(
    "SELECT sql FROM sqlite_master WHERE sql IS NOT NULL AND name NOT LIKE 'sqlite_%' ORDER BY name",
  );
  return rows
      .map(
        (row) => (row['sql'] as String).replaceAll(RegExp(r'\s+'), ' ').trim(),
      )
      .toList();
}

void main() {
  late Directory folder;

  setUp(() async {
    sqfliteFfiInit();
    folder = await Directory.systemTemp.createTemp('kitaza-migrate');
  });
  tearDown(() => folder.delete(recursive: true));

  test('the app opens the newest schema version there is', () {
    expect(AppConfig.databaseVersion, SchemaMigrations.latestVersion);
  });

  test('an existing phone upgrades without losing a single sale', () async {
    final db = await _openAsTheAppWould(await _versionOnePhone(folder));
    addTearDown(db.close);

    final sales = await db.query('sales');
    expect(sales.single['total_amount'], 4200);
    expect(
      (await db.rawQuery('PRAGMA user_version')).first.values.first,
      AppConfig.databaseVersion,
    );
    expect(
      await db.query('error_reports'),
      isEmpty,
      reason: 'the new table exists',
    );
  });

  test(
    'a new install and an upgraded phone end up with the same schema',
    () async {
      final upgraded = await _openAsTheAppWould(await _versionOnePhone(folder));
      addTearDown(upgraded.close);

      final fresh = await databaseFactoryFfi.openDatabase(
        p.join(folder.path, 'fresh.db'),
        options: OpenDatabaseOptions(singleInstance: false),
      );
      addTearDown(fresh.close);
      await LocalDatabase.applySchema(fresh);

      expect(await _schemaOf(fresh), await _schemaOf(upgraded));
    },
  );
}
