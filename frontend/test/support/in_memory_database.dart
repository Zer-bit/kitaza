import 'package:kitaza_app/data/local/database/local_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// A throwaway database with the real schema, so tests exercise the same SQL
/// the app runs rather than a simplified stand-in.
Future<Database> openTestDatabase() async {
  sqfliteFfiInit();

  final db = await databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(version: 1),
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
