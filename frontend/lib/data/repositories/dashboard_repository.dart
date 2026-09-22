import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../analysis/business_score_calculator.dart';
import '../local/dao/dashboard_dao.dart';
import '../local/dao/product_dao.dart';
import '../models/dashboard_summary.dart';
import '../models/report_period.dart';
import 'store_scope.dart';

/// Reads always come from SQLite, even in cloud mode. That is what makes the
/// dashboard open instantly and keeps working with no signal; the cloud's job
/// is to keep the local copy current, not to serve the screen.
class DashboardRepository {
  const DashboardRepository({
    required this._dashboard,
    required this._products,
    required this._storeId,
  });

  final DashboardDao _dashboard;
  final ProductDao _products;
  final String _storeId;

  Future<DashboardSummary> summarise(ReportPeriod period) async {
    final now = DateTime.now();
    final start = period.startOf(now);
    final previousStart = start.subtract(now.difference(start));

    final results = await Future.wait([
      _dashboard.salesTotals(_storeId, start, now),
      _dashboard.expensesTotal(_storeId, start, now),
      _dashboard.withdrawalsTotal(_storeId, start, now),
      _dashboard.salesTotals(_storeId, previousStart, start),
      _dashboard.expensesTotal(_storeId, previousStart, start),
      _dashboard.bestSeller(_storeId, start, now),
      _products.lowStockCount(_storeId),
    ]);

    final sales = results[0] as SalesTotals;
    final expensesTotal = results[1] as double;
    final withdrawalsTotal = results[2] as double;
    final previousSales = results[3] as SalesTotals;
    final previousExpenses = results[4] as double;
    final bestSeller = results[5] as BestSeller?;
    final lowStockCount = results[6] as int;

    final previousNetProfit =
        previousSales.salesTotal - previousSales.costTotal - previousExpenses;
    final netProfit = sales.salesTotal - sales.costTotal - expensesTotal;

    return DashboardSummary(
      period: period,
      salesTotal: sales.salesTotal,
      saleCount: sales.saleCount,
      costOfGoods: sales.costTotal,
      expensesTotal: expensesTotal,
      withdrawalsTotal: withdrawalsTotal,
      previousNetProfit: previousNetProfit,
      lowStockCount: lowStockCount,
      bestSeller: bestSeller,
      health: BusinessScoreCalculator.evaluate(
        ScoreInputs(
          salesTotal: sales.salesTotal,
          netProfit: netProfit,
          previousNetProfit: previousNetProfit,
          withdrawalsTotal: withdrawalsTotal,
          lowStockCount: lowStockCount,
        ),
      ),
    );
  }
}

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return DashboardRepository(
    dashboard: DashboardDao(db),
    products: ProductDao(db),
    storeId: ref.watch(activeStoreIdProvider),
  );
});
