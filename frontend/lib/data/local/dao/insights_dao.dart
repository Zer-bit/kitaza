import 'package:sqflite/sqflite.dart';

import '../../../core/formatting/centavos.dart';
import '../../models/product.dart';

/// One change to a product's stock, as the ledger recorded it: always a
/// signed difference, even for a count.
typedef StockChange = ({DateTime day, double change, bool isCount});

/// The history the suggestions are worked out from. Every query here is
/// scoped to one store and one window, and runs on the phone.
class InsightsDao {
  const InsightsDao(this._db);

  final DatabaseExecutor _db;

  Future<List<Product>> activeProducts(String storeId) async {
    final rows = await _db.query(
      'products',
      where: 'store_id = ? AND deleted_at IS NULL AND is_active = 1',
      whereArgs: [storeId],
      orderBy: 'name',
    );
    return rows.map(Product.fromRow).toList(growable: false);
  }

  /// How much of each product sold on each day.
  Future<Map<String, Map<DateTime, double>>> soldPerProductPerDay(
    String storeId,
    DateTime from,
  ) async {
    final rows = await _db.rawQuery(
      '''
      SELECT i.product_id                        AS product_id,
             date(s.occurred_at, 'localtime')    AS day,
             SUM(i.quantity)                     AS quantity
      FROM sale_items i
      JOIN sales s ON s.id = i.sale_id
      WHERE s.store_id = ? AND s.deleted_at IS NULL
        AND s.occurred_at >= ? AND i.product_id IS NOT NULL
      GROUP BY product_id, day
      ''',
      [storeId, from.toUtc().toIso8601String()],
    );

    final byProduct = <String, Map<DateTime, double>>{};
    for (final row in rows) {
      final product = row['product_id'] as String;
      final day = DateTime.parse(row['day'] as String);
      byProduct.putIfAbsent(product, () => {})[day] =
          (row['quantity'] as num?)?.toDouble() ?? 0;
    }
    return byProduct;
  }

  /// Deliveries, counts and spoilage, per product.
  ///
  /// Sales are left out: they are counted from the sale lines instead, and a
  /// cloud store's ledger holds a row for each of them as well.
  Future<Map<String, List<StockChange>>> stockChanges(
    String storeId,
    DateTime from,
  ) async {
    final rows = await _db.rawQuery(
      '''
      SELECT product_id,
             date(occurred_at, 'localtime') AS day,
             SUM(quantity)                  AS change,
             MAX(movement = 'adjustment')   AS has_count
      FROM stock_movements
      WHERE store_id = ? AND deleted_at IS NULL
        AND occurred_at >= ? AND movement <> 'sale'
      GROUP BY product_id, day
      ''',
      [storeId, from.toUtc().toIso8601String()],
    );

    final byProduct = <String, List<StockChange>>{};
    for (final row in rows) {
      final product = row['product_id'] as String;
      byProduct.putIfAbsent(product, () => []).add((
        day: DateTime.parse(row['day'] as String),
        change: (row['change'] as num?)?.toDouble() ?? 0,
        isCount: ((row['has_count'] as num?)?.toInt() ?? 0) == 1,
      ));
    }
    return byProduct;
  }

  /// What the store took each day, for the payday and weekday patterns.
  Future<Map<DateTime, double>> dailySales(
    String storeId,
    DateTime from,
  ) async {
    final rows = await _db.rawQuery(
      '''
      SELECT date(occurred_at, 'localtime') AS day,
             COALESCE(SUM(total_amount), 0) AS total
      FROM sales
      WHERE store_id = ? AND deleted_at IS NULL AND occurred_at >= ?
      GROUP BY day
      ''',
      [storeId, from.toUtc().toIso8601String()],
    );

    return {
      for (final row in rows)
        DateTime.parse(row['day'] as String): Centavos.toPesos(
          (row['total'] as num?)?.toInt() ?? 0,
        ),
    };
  }
}
