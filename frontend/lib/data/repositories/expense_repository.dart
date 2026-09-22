import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../local/dao/expense_dao.dart';
import '../local/dao/sync_queue_dao.dart';
import '../models/expense.dart';
import '../models/expense_category.dart';
import 'store_scope.dart';

class ExpenseRepository {
  const ExpenseRepository({required this._db, required this._storeId});

  final Database _db;
  final String _storeId;

  static const Uuid _uuid = Uuid();

  Future<List<Expense>> history({
    DateTime? from,
    DateTime? to,
    ExpenseCategory? category,
    int limit = 50,
    int offset = 0,
  }) {
    return ExpenseDao(_db).recent(
      _storeId,
      from: from,
      to: to,
      category: category?.wireName,
      limit: limit,
      offset: offset,
    );
  }

  Future<Expense> record({
    required ExpenseCategory category,
    required double amount,
    String? description,
    DateTime? occurredAt,
  }) async {
    final expense = Expense(
      id: _uuid.v4(),
      category: category,
      description: description?.trim().isEmpty ?? true
          ? null
          : description!.trim(),
      amount: amount,
      occurredAt: occurredAt ?? DateTime.now().toUtc(),
    );

    await _db.transaction((txn) async {
      await ExpenseDao(txn).upsert(_storeId, expense);
      await SyncQueueDao(txn)
          .enqueue(QueuedEntity.expenses, expense.id, expense.toPushJson());
    });

    return expense;
  }

  Future<void> remove(String expenseId) async {
    await _db.transaction((txn) async {
      await ExpenseDao(txn).softDelete(expenseId);
      await SyncQueueDao(txn).enqueueDeletion(
        DeletedEntity.expense,
        QueuedEntity.expenses,
        expenseId,
      );
    });
  }
}

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository(
    db: ref.watch(databaseProvider),
    storeId: ref.watch(activeStoreIdProvider),
  );
});
