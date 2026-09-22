import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../analysis/expense_anomaly_detector.dart';
import '../local/dao/report_dao.dart';
import '../models/report_models.dart';
import '../models/report_period.dart';
import 'store_scope.dart';

class ReportRepository {
  const ReportRepository({required this._reports, required this._storeId});

  final ReportDao _reports;
  final String _storeId;

  static const int _trendDays = 14;
  static const int _anomalyLookbackDays = 60;

  Future<PeriodReport> compile(ReportPeriod period) async {
    final now = DateTime.now();
    final start = period.startOf(now);
    final trendStart = now.subtract(const Duration(days: _trendDays));
    final anomalyStart = now.subtract(
      const Duration(days: _anomalyLookbackDays),
    );

    final results = await Future.wait([
      _reports.dailyTrend(_storeId, trendStart, now),
      _reports.topProducts(_storeId, start, now),
      _reports.expenseBreakdown(_storeId, start, now),
      _reports.expenseSamples(_storeId, anomalyStart),
    ]);

    return PeriodReport(
      trend: results[0] as List<DailyProfitPoint>,
      topProducts: results[1] as List<ProductPerformance>,
      expenseBreakdown: results[2] as List<ExpenseSlice>,
      unusualExpenses: ExpenseAnomalyDetector.detect(
        results[3] as List<(String, double, DateTime, String?)>,
      ),
    );
  }
}

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepository(
    reports: ReportDao(ref.watch(databaseProvider)),
    storeId: ref.watch(activeStoreIdProvider),
  );
});
