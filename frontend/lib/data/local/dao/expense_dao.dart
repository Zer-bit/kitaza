import 'package:sqflite/sqflite.dart';

import '../../models/expense.dart';

class ExpenseDao {
  const ExpenseDao(this._db);

  final DatabaseExecutor _db;

  Future<void> upsert(String storeId, Expense expense) => _db.insert(
    'expenses',
    {...expense.toRow(), 'store_id': storeId},
    conflictAlgorithm: ConflictAlgorithm.replace,
  );

  Future<List<Expense>> recent(
    String storeId, {
    DateTime? from,
    DateTime? to,
    String? category,
    int limit = 50,
    int offset = 0,
  }) async {
    final where = StringBuffer('store_id = ? AND deleted_at IS NULL');
    final args = <Object?>[storeId];

    if (from != null) {
      where.write(' AND occurred_at >= ?');
      args.add(from.toUtc().toIso8601String());
    }
    if (to != null) {
      where.write(' AND occurred_at < ?');
      args.add(to.toUtc().toIso8601String());
    }
    if (category != null) {
      where.write(' AND category = ?');
      args.add(category);
    }

    final rows = await _db.query(
      'expenses',
      where: where.toString(),
      whereArgs: args,
      orderBy: 'occurred_at DESC',
      limit: limit,
      offset: offset,
    );

    return rows.map(Expense.fromRow).toList(growable: false);
  }

  Future<void> softDelete(String expenseId) {
    final now = DateTime.now().toUtc().toIso8601String();
    return _db.update(
      'expenses',
      {'deleted_at': now, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [expenseId],
    );
  }
}
