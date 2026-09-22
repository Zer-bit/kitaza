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

  Future<List<StoreProfile>> readStores() async {
    final rows = await _db.query('stores', orderBy: 'rowid');
    return rows.map(StoreProfile.fromRow).toList(growable: false);
  }

  /// For a staff member who can no longer see the money side of the store:
  /// removes the expenses and withdrawals the phone held, except their own
  /// entries still waiting to upload.
  Future<void> forgetPrivateRecords(String storeId) async {
    for (final (table, queued) in const [
      ('expenses', 'expenses'),
      ('owner_withdrawals', 'withdrawals'),
    ]) {
      await _db.rawDelete(
        'DELETE FROM $table WHERE store_id = ? AND id NOT IN '
        '(SELECT entity_id FROM sync_queue WHERE entity = ?)',
        [storeId, queued],
      );
    }
  }

  Future<StoreProfile?> readFirstStore() async {
    final rows = await _db.query('stores', limit: 1);
    return rows.isEmpty ? null : StoreProfile.fromRow(rows.first);
  }

  /// Moves every row from a local-only store to the store the cloud created
  /// for it. Row ids stay exactly as they were, which is what lets the
  /// existing outbox upload the whole history without translation.
  Future<void> adoptCloudStore({
    required String fromStoreId,
    required StoreProfile store,
    required OwnerAccount owner,
  }) async {
    for (final table in const [
      'products',
      'sales',
      'expenses',
      'owner_withdrawals',
      'stock_movements',
      'sync_queue',
    ]) {
      await _db.update(
        table,
        {'store_id': store.id},
        where: 'store_id = ?',
        whereArgs: [fromStoreId],
      );
    }

    await _db.delete('stores');
    await _db.delete('owners');
    await saveStore(store);
    await saveOwner(owner);
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
