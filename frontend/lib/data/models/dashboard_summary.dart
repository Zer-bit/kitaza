import 'business_health.dart';
import 'report_period.dart';

class BestSeller {
  const BestSeller({
    required this.productName,
    required this.quantitySold,
    required this.revenue,
  });

  final String productName;
  final double quantitySold;
  final double revenue;
}

/// Everything the home screen shows, computed either locally from SQLite or
/// fetched from the API. Both paths produce this same shape.
class DashboardSummary {
  const DashboardSummary({
    required this.period,
    required this.salesTotal,
    required this.saleCount,
    required this.costOfGoods,
    required this.expensesTotal,
    required this.withdrawalsTotal,
    required this.previousNetProfit,
    required this.lowStockCount,
    required this.health,
    this.bestSeller,
  });

  final ReportPeriod period;
  final double salesTotal;
  final int saleCount;
  final double costOfGoods;
  final double expensesTotal;
  final double withdrawalsTotal;
  final double previousNetProfit;
  final int lowStockCount;
  final BusinessHealth health;
  final BestSeller? bestSeller;

  double get grossProfit => salesTotal - costOfGoods;
  double get netProfit => grossProfit - expensesTotal;
  double get cashMovement => netProfit - withdrawalsTotal;

  double get marginPercent =>
      salesTotal <= 0 ? 0 : (netProfit / salesTotal) * 100;

  double get averageSaleValue => saleCount == 0 ? 0 : salesTotal / saleCount;

  bool get hasActivity => saleCount > 0 || expensesTotal > 0;

  static DashboardSummary empty(ReportPeriod period) => DashboardSummary(
    period: period,
    salesTotal: 0,
    saleCount: 0,
    costOfGoods: 0,
    expensesTotal: 0,
    withdrawalsTotal: 0,
    previousNetProfit: 0,
    lowStockCount: 0,
    health: BusinessHealth.unknown,
  );
}
