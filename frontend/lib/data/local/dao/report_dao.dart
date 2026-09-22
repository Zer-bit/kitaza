import 'package:sqflite/sqflite.dart';

import '../../../core/formatting/centavos.dart';
import '../../models/expense_category.dart';
import '../../models/report_models.dart';

class ReportDao {
  const ReportDao(this._db);

  final DatabaseExecutor _db;

  /// Buckets by local calendar day. SQLite's `localtime` modifier uses the
  /// device's timezone, which is exactly the day boundary the owner means.
  Future<List<DailyProfitPoint>> dailyTrend(
    String storeId,
    DateTime from,
    DateTime to,
  ) async {
    final args = [
      storeId,
      from.toUtc().toIso8601String(),
      to.toUtc().toIso8601String(),
    ];

    final saleRows = await _db.rawQuery('''
      SELECT date(occurred_at, 'localtime')  AS day,
             COALESCE(SUM(total_amount), 0)  AS sales_total,
             COALESCE(SUM(cost_amount), 0)   AS cost_total
      FROM sales
      WHERE store_id = ? AND deleted_at IS NULL
        AND occurred_at >= ? AND occurred_at < ?
      GROUP BY day
      ''', args);

    final expenseRows = await _db.rawQuery('''
      SELECT date(occurred_at, 'localtime') AS day,
             COALESCE(SUM(amount), 0)       AS expenses_total
      FROM expenses
      WHERE store_id = ? AND deleted_at IS NULL
        AND occurred_at >= ? AND occurred_at < ?
      GROUP BY day
      ''', args);

    final byDay = <String, List<double>>{};
    for (final row in saleRows) {
      final day = row['day'] as String;
      byDay[day] = [
        Centavos.toPesos((row['sales_total'] as num?)?.toInt() ?? 0),
        Centavos.toPesos((row['cost_total'] as num?)?.toInt() ?? 0),
        0,
      ];
    }
    for (final row in expenseRows) {
      final day = row['day'] as String;
      final entry = byDay.putIfAbsent(day, () => [0, 0, 0]);
      entry[2] = Centavos.toPesos(
        (row['expenses_total'] as num?)?.toInt() ?? 0,
      );
    }

    final days = byDay.keys.toList()..sort();
    return days
        .map((day) {
          final values = byDay[day]!;
          return DailyProfitPoint(
            day: DateTime.parse(day),
            salesTotal: values[0],
            expensesTotal: values[2],
            netProfit: values[0] - values[1] - values[2],
          );
        })
        .toList(growable: false);
  }

  Future<List<ProductPerformance>> topProducts(
    String storeId,
    DateTime from,
    DateTime to, {
    int limit = 5,
  }) async {
    final rows = await _db.rawQuery(
      '''
      SELECT i.product_name                                   AS product_name,
             SUM(i.quantity)                                  AS quantity_sold,
             SUM(i.line_total)                                AS revenue,
             SUM(i.line_total - (i.unit_cost * i.quantity))   AS profit
      FROM sale_items i
      JOIN sales s ON s.id = i.sale_id
      WHERE s.store_id = ? AND s.deleted_at IS NULL
        AND s.occurred_at >= ? AND s.occurred_at < ?
      GROUP BY i.product_name
      ORDER BY profit DESC
      LIMIT ?
      ''',
      [
        storeId,
        from.toUtc().toIso8601String(),
        to.toUtc().toIso8601String(),
        limit,
      ],
    );

    return rows
        .map(
          (row) => ProductPerformance(
            productName: row['product_name'] as String,
            quantitySold: readDouble(row['quantity_sold']),
            revenue: Centavos.toPesos((row['revenue'] as num?)?.toInt() ?? 0),
            profit: Centavos.toPesos((row['profit'] as num?)?.round() ?? 0),
          ),
        )
        .toList(growable: false);
  }

  Future<List<ExpenseSlice>> expenseBreakdown(
    String storeId,
    DateTime from,
    DateTime to,
  ) async {
    final rows = await _db.rawQuery(
      '''
      SELECT category, SUM(amount) AS total_amount, COUNT(*) AS entry_count
      FROM expenses
      WHERE store_id = ? AND deleted_at IS NULL
        AND occurred_at >= ? AND occurred_at < ?
      GROUP BY category
      ORDER BY total_amount DESC
      ''',
      [storeId, from.toUtc().toIso8601String(), to.toUtc().toIso8601String()],
    );

    return rows
        .map(
          (row) => ExpenseSlice(
            category: ExpenseCategory.parse(row['category'] as String?),
            totalAmount: Centavos.toPesos(
              (row['total_amount'] as num?)?.toInt() ?? 0,
            ),
            entryCount: (row['entry_count'] as int?) ?? 0,
          ),
        )
        .toList(growable: false);
  }

  /// Raw rows for the anomaly check. Bounded so the scan stays cheap even on
  /// a store with years of history.
  Future<List<(String, double, DateTime, String?)>> expenseSamples(
    String storeId,
    DateTime since,
  ) async {
    final rows = await _db.rawQuery(
      '''
      SELECT category, amount, occurred_at, description
      FROM expenses
      WHERE store_id = ? AND deleted_at IS NULL AND occurred_at >= ?
      ORDER BY occurred_at DESC
      LIMIT 500
      ''',
      [storeId, since.toUtc().toIso8601String()],
    );

    return rows
        .map(
          (row) => (
            row['category'] as String,
            Centavos.toPesos((row['amount'] as num?)?.toInt() ?? 0),
            readDate(row['occurred_at']),
            row['description'] as String?,
          ),
        )
        .toList(growable: false);
  }
}
