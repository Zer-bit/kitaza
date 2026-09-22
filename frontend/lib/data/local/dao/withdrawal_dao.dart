import 'package:sqflite/sqflite.dart';

import '../../models/owner_withdrawal.dart';

class WithdrawalDao {
  const WithdrawalDao(this._db);

  final DatabaseExecutor _db;

  Future<void> upsert(String storeId, OwnerWithdrawal withdrawal) => _db.insert(
    'owner_withdrawals',
    {...withdrawal.toRow(), 'store_id': storeId},
    conflictAlgorithm: ConflictAlgorithm.replace,
  );

  Future<List<OwnerWithdrawal>> recent(
    String storeId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final rows = await _db.query(
      'owner_withdrawals',
      where: 'store_id = ? AND deleted_at IS NULL',
      whereArgs: [storeId],
      orderBy: 'occurred_at DESC',
      limit: limit,
      offset: offset,
    );

    return rows.map(OwnerWithdrawal.fromRow).toList(growable: false);
  }

  Future<void> softDelete(String withdrawalId) {
    final now = DateTime.now().toUtc().toIso8601String();
    return _db.update(
      'owner_withdrawals',
      {'deleted_at': now, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [withdrawalId],
    );
  }
}
