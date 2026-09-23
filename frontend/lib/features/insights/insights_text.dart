import '../../core/formatting/day_formatter.dart';
import '../../core/formatting/peso_formatter.dart';
import '../../core/formatting/quantity_formatter.dart';
import '../../data/analysis/price_advisor.dart';
import '../../data/analysis/restock_advisor.dart';
import '../../data/models/benchmark_report.dart';
import '../../l10n/l10n.dart';

extension InsightsText on AppLocalizations {
  /// Why this product is on the reorder list, in the terms it was decided.
  String restockReason(RestockAdvice advice) {
    if (advice.basis == RestockBasis.reorderLevel) return restockReasonLevel;

    final rate = QuantityFormatter.exact(advice.dailyQuantity);
    if (advice.isOutOfStock) {
      return restockReasonEmpty(rate, advice.product.unitLabel);
    }
    final days = (advice.coverDays ?? 0).round();
    return restockReasonRate(rate, advice.product.unitLabel, restockDays(days));
  }

  String restockOrderLine(RestockAdvice advice) => restockOrder(
    QuantityFormatter.exact(advice.orderQuantity),
    advice.product.unitLabel,
  );

  String priceReason(PriceAdvice advice) => switch (advice.issue) {
    PriceIssue.belowCost => priceReasonBelowCost(
      PesoFormatter.format(advice.product.costPrice),
    ),
    PriceIssue.thinMargin => priceReasonThin(
      commonPercent(advice.marginPercent.toStringAsFixed(0)),
    ),
    PriceIssue.slowMover => priceReasonSlow,
  };

  String benchmarkMetric(Comparison comparison) => switch (comparison.metric) {
    'gross_margin_percent' => benchmarkMargin,
    'expense_percent' => benchmarkExpenses,
    _ => benchmarkDailySales,
  };

  /// Percentages read as percentages; money reads as money.
  String benchmarkValue(Comparison comparison, double value) =>
      comparison.metric == 'daily_sales'
      ? PesoFormatter.format(value)
      : commonPercent(value.toStringAsFixed(0));

  String paydayLine(double upliftPercent) =>
      patternPayday(commonPercent(upliftPercent.round().toString()));

  String nextPaydayLine(DateTime day) =>
      patternNextPayday(DayFormatter.fullDate(day));

  String busiestDayLine(int weekday, double upliftPercent) => patternBusiest(
    DayFormatter.weekday(_nextWeekday(weekday)),
    commonPercent(upliftPercent.round().toString()),
  );

  static DateTime _nextWeekday(int weekday) {
    final today = DateTime.now();
    return today.add(Duration(days: (weekday - today.weekday + 7) % 7));
  }
}
