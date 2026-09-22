import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../local/dao/sync_queue_dao.dart';
import '../local/dao/withdrawal_dao.dart';
import '../models/owner_withdrawal.dart';
import 'store_scope.dart';

class WithdrawalRepository {
  const WithdrawalRepository({required this._db, required this._storeId});

  final Database _db;
  final String _storeId;

  static const Uuid _uuid = Uuid();

  Future<List<OwnerWithdrawal>> history({int limit = 50, int offset = 0}) =>
      WithdrawalDao(_db).recent(_storeId, limit: limit, offset: offset);

  Future<OwnerWithdrawal> record({
    required double amount,
    String? reason,
    DateTime? occurredAt,
  }) async {
    final withdrawal = OwnerWithdrawal(
      id: _uuid.v4(),
      amount: amount,
      reason: reason?.trim().isEmpty ?? true ? null : reason!.trim(),
      occurredAt: occurredAt ?? DateTime.now().toUtc(),
    );

    await _db.transaction((txn) async {
      await WithdrawalDao(txn).upsert(_storeId, withdrawal);
      await SyncQueueDao(txn).enqueue(
        QueuedEntity.withdrawals,
        withdrawal.id,
        withdrawal.toPushJson(),
        storeId: _storeId,
      );
    });

    return withdrawal;
  }

  Future<void> remove(String withdrawalId) async {
    await _db.transaction((txn) async {
      await WithdrawalDao(txn).softDelete(withdrawalId);
      await SyncQueueDao(txn).enqueueDeletion(
        DeletedEntity.withdrawal,
        QueuedEntity.withdrawals,
        withdrawalId,
        storeId: _storeId,
      );
    });
  }
}

final withdrawalRepositoryProvider = Provider<WithdrawalRepository>((ref) {
  return WithdrawalRepository(
    db: ref.watch(databaseProvider),
    storeId: ref.watch(activeStoreIdProvider),
  );
});
