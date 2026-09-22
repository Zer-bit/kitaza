import 'package:sqflite/sqflite.dart';

import '../../models/stock_movement.dart';

class StockMovementDao {
  const StockMovementDao(this._db);

  final DatabaseExecutor _db;

  /// Records the movement and moves the product's running total to match.
  /// Returns the signed change that was applied.
  Future<double> apply(String storeId, StockMovement movement) async {
    final rows = await _db.query(
      'products',
      columns: ['stock_quantity'],
      where: 'id = ?',
      whereArgs: [movement.productId],
      limit: 1,
    );
    if (rows.isEmpty) return 0;

    final onHand = (rows.first['stock_quantity'] as num?)?.toDouble() ?? 0;
    final delta = switch (movement.kind) {
      StockMovementKind.stockIn => movement.quantity,
      StockMovementKind.stockOut ||
      StockMovementKind.spoilage => -movement.quantity,
      StockMovementKind.adjustment => movement.quantity - onHand,
    };

    await _db.insert(
      'stock_movements',
      movement.toRow(storeId, appliedDelta: delta),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    await _db.rawUpdate(
      'UPDATE products SET stock_quantity = stock_quantity + ?, updated_at = ? WHERE id = ?',
      [delta, DateTime.now().toUtc().toIso8601String(), movement.productId],
    );

    return delta;
  }
}
