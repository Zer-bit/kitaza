import 'package:sqflite/sqflite.dart';

import '../../models/owner_account.dart';
import '../../models/store_profile.dart';

class SessionDao {
  const SessionDao(this._db);

  final DatabaseExecutor _db;

  Future<void> saveOwner(OwnerAccount owner) => _db.insert(
    'owners',
    owner.toRow(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );

  Future<void> saveStore(StoreProfile store) => _db.insert(
    'stores',
    store.toRow(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );

  Future<OwnerAccount?> readOwner() async {
    final rows = await _db.query('owners', limit: 1);
    return rows.isEmpty ? null : OwnerAccount.fromRow(rows.first);
  }

  Future<StoreProfile?> readStore(String storeId) async {
    final rows = await _db.query(
      'stores',
      where: 'id = ?',
      whereArgs: [storeId],
      limit: 1,
    );
    return rows.isEmpty ? null : StoreProfile.fromRow(rows.first);
  }

  Future<StoreProfile?> readFirstStore() async {
    final rows = await _db.query('stores', limit: 1);
    return rows.isEmpty ? null : StoreProfile.fromRow(rows.first);
  }

  /// Wipes business data on sign-out. Runs in one transaction so the device is
  /// never left half-cleared.
  Future<void> wipe(Database db) async {
    await db.transaction((txn) async {
      for (final table in const [
        'sync_queue',
        'sale_items',
        'sales',
        'expenses',
        'owner_withdrawals',
        'stock_movements',
        'products',
        'stores',
        'owners',
      ]) {
        await txn.delete(table);
      }
    });
  }
}
