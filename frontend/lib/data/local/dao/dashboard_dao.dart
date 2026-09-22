import 'package:sqflite/sqflite.dart';

import '../../../core/formatting/centavos.dart';
import '../../models/dashboard_summary.dart';

class SalesTotals {
  const SalesTotals({
    required this.salesTotal,
    required this.costTotal,
    required this.saleCount,
  });

  final double salesTotal;
  final double costTotal;
  final int saleCount;

  static const SalesTotals zero = SalesTotals(
    salesTotal: 0,
    costTotal: 0,
    saleCount: 0,
  );
}

/// Computes the dashboard numbers straight from SQLite. This is what makes the
/// home screen work with the phone in airplane mode, and it uses the same
/// formulas as the server so the two never disagree.
class DashboardDao {
  const DashboardDao(this._db);

  final DatabaseExecutor _db;

  Future<SalesTotals> salesTotals(
    String storeId,
    DateTime from,
    DateTime to,
  ) async {
    final rows = await _db.rawQuery(
      '''
      SELECT COALESCE(SUM(total_amount), 0) AS sales_total,
             COALESCE(SUM(cost_amount), 0)  AS cost_total,
             COUNT(*)                       AS sale_count
      FROM sales
      WHERE store_id = ? AND deleted_at IS NULL
        AND occurred_at >= ? AND occurred_at < ?
      ''',
      [storeId, from.toUtc().toIso8601String(), to.toUtc().toIso8601String()],
    );

    final row = rows.first;
    return SalesTotals(
      salesTotal: Centavos.toPesos((row['sales_total'] as num?)?.toInt() ?? 0),
      costTotal: Centavos.toPesos((row['cost_total'] as num?)?.toInt() ?? 0),
      saleCount: (row['sale_count'] as int?) ?? 0,
    );
  }

  Future<double> expensesTotal(String storeId, DateTime from, DateTime to) =>
      _sumAmount('expenses', storeId, from, to);

  Future<double> withdrawalsTotal(String storeId, DateTime from, DateTime to) =>
      _sumAmount('owner_withdrawals', storeId, from, to);

  Future<BestSeller?> bestSeller(
    String storeId,
    DateTime from,
    DateTime to,
  ) async {
    final rows = await _db.rawQuery(
      '''
      SELECT i.product_name        AS product_name,
             SUM(i.quantity)       AS quantity_sold,
             SUM(i.line_total)     AS revenue
      FROM sale_items i
      JOIN sales s ON s.id = i.sale_id
      WHERE s.store_id = ? AND s.deleted_at IS NULL
        AND s.occurred_at >= ? AND s.occurred_at < ?
      GROUP BY i.product_name
      ORDER BY revenue DESC
      LIMIT 1
      ''',
      [storeId, from.toUtc().toIso8601String(), to.toUtc().toIso8601String()],
    );

    if (rows.isEmpty) return null;

    final row = rows.first;
    return BestSeller(
      productName: row['product_name'] as String,
      quantitySold: readDouble(row['quantity_sold']),
      revenue: Centavos.toPesos((row['revenue'] as num?)?.toInt() ?? 0),
    );
  }

  /// The table name comes from this class only, never from user input.
  Future<double> _sumAmount(
    String table,
    String storeId,
    DateTime from,
    DateTime to,
  ) async {
    final rows = await _db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) AS total FROM $table
      WHERE store_id = ? AND deleted_at IS NULL
        AND occurred_at >= ? AND occurred_at < ?
      ''',
      [storeId, from.toUtc().toIso8601String(), to.toUtc().toIso8601String()],
    );

    return Centavos.toPesos((rows.first['total'] as num?)?.toInt() ?? 0);
  }
}
