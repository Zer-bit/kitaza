import 'package:sqflite/sqflite.dart';

import '../../models/sale.dart';
import '../../models/sale_line.dart';

class SaleDao {
  const SaleDao(this._db);

  final DatabaseExecutor _db;

  /// Writes the sale, its lines and the stock deduction together. Called
  /// inside a transaction by the repository.
  Future<void> insert(String storeId, Sale sale) async {
    await _db.insert('sales', {
      ...sale.toRow(),
      'store_id': storeId,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    await _db.delete('sale_items', where: 'sale_id = ?', whereArgs: [sale.id]);

    final batch = _db.batch();
    for (final line in sale.lines) {
      batch.insert('sale_items', line.toRow());

      if (line.productId != null) {
        batch.rawUpdate(
          'UPDATE products SET stock_quantity = stock_quantity - ?, updated_at = ? WHERE id = ?',
          [
            line.quantity,
            DateTime.now().toUtc().toIso8601String(),
            line.productId,
          ],
        );
      }
    }
    await batch.commit(noResult: true);
  }

  Future<List<Sale>> recent(
    String storeId, {
    DateTime? from,
    DateTime? to,
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

    final rows = await _db.query(
      'sales',
      where: where.toString(),
      whereArgs: args,
      orderBy: 'occurred_at DESC',
      limit: limit,
      offset: offset,
    );

    return rows.map(Sale.fromRow).toList(growable: false);
  }

  Future<List<SaleLine>> linesFor(String saleId) async {
    final rows = await _db.query(
      'sale_items',
      where: 'sale_id = ?',
      whereArgs: [saleId],
    );
    return rows.map(SaleLine.fromRow).toList(growable: false);
  }

  /// Attaches lines to a page of sales with one extra query instead of one
  /// per row, which keeps the history list smooth while scrolling.
  Future<Map<String, List<SaleLine>>> linesForAll(List<String> saleIds) async {
    if (saleIds.isEmpty) return const {};

    final placeholders = List.filled(saleIds.length, '?').join(', ');
    final rows = await _db.rawQuery(
      'SELECT * FROM sale_items WHERE sale_id IN ($placeholders)',
      saleIds,
    );

    final grouped = <String, List<SaleLine>>{};
    for (final row in rows) {
      final line = SaleLine.fromRow(row);
      grouped.putIfAbsent(line.saleId, () => []).add(line);
    }
    return grouped;
  }

  /// Voiding restores stock so a mistyped sale does not leave the count wrong.
  Future<void> voidSale(String saleId) async {
    final lines = await linesFor(saleId);
    final now = DateTime.now().toUtc().toIso8601String();

    final batch = _db.batch();
    batch.update(
      'sales',
      {'deleted_at': now, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [saleId],
    );

    for (final line in lines) {
      if (line.productId == null) continue;
      batch.rawUpdate(
        'UPDATE products SET stock_quantity = stock_quantity + ?, updated_at = ? WHERE id = ?',
        [line.quantity, now, line.productId],
      );
    }

    await batch.commit(noResult: true);
  }
}
