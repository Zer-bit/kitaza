class DailyProfitPoint {
  const DailyProfitPoint({
    required this.day,
    required this.salesTotal,
    required this.expensesTotal,
    required this.netProfit,
  });

  final DateTime day;
  final double salesTotal;
  final double expensesTotal;
  final double netProfit;
}

class ProductPerformance {
  const ProductPerformance({
    required this.productName,
    required this.quantitySold,
    required this.revenue,
    required this.profit,
  });

  final String productName;
  final double quantitySold;
  final double revenue;
  final double profit;
}

class ExpenseSlice {
  const ExpenseSlice({
    required this.categoryName,
    required this.totalAmount,
    required this.entryCount,
  });

  final String categoryName;
  final double totalAmount;
  final int entryCount;
}

/// An expense well outside the store's own normal range for its category.
class UnusualExpense {
  const UnusualExpense({
    required this.label,
    required this.amount,
    required this.categoryAverage,
    required this.timesAboveAverage,
    required this.occurredAt,
  });

  final String label;
  final double amount;
  final double categoryAverage;
  final double timesAboveAverage;
  final DateTime occurredAt;
}

class PeriodReport {
  const PeriodReport({
    required this.trend,
    required this.topProducts,
    required this.expenseBreakdown,
    required this.unusualExpenses,
  });

  final List<DailyProfitPoint> trend;
  final List<ProductPerformance> topProducts;
  final List<ExpenseSlice> expenseBreakdown;
  final List<UnusualExpense> unusualExpenses;

  static const PeriodReport empty = PeriodReport(
    trend: [],
    topProducts: [],
    expenseBreakdown: [],
    unusualExpenses: [],
  );
}
