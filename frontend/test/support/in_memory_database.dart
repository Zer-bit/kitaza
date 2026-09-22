import 'package:kitaza_app/data/local/database/local_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// A throwaway database with the real schema, so tests exercise the same SQL
/// the app runs rather than a simplified stand-in.
///
/// Widget tests pass [sameIsolate]: they run on a simulated clock, and
/// sqflite's default background isolate never answers there.
Future<Database> openTestDatabase({bool sameIsolate = false}) async {
  sqfliteFfiInit();
  final factory = sameIsolate
      ? databaseFactoryFfiNoIsolate
      : databaseFactoryFfi;

  final db = await factory.openDatabase(
    inMemoryDatabasePath,
    // Without this, every in-memory open returns the same shared database,
    // and two simulated devices would silently be one.
    options: OpenDatabaseOptions(version: 1, singleInstance: false),
  );

  await LocalDatabase.applySchema(db);
  await db.insert('stores', {
    'id': testStoreId,
    'name': 'Test Store',
    'business_type': 'sari_sari',
    'currency_code': 'PHP',
  });

  return db;
}

const String testStoreId = 'store-under-test';
