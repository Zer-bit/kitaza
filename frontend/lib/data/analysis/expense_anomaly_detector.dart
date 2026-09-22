import '../models/expense_category.dart';
import '../models/report_models.dart';

/// Flags spending that is far outside the store's own normal range. A plain
/// rule rather than a model: it needs no training data, works from the first
/// week, and the owner can check the arithmetic themselves.
abstract final class ExpenseAnomalyDetector {
  static const double _outlierMultiplier = 2.5;
  static const int _minimumSamples = 4;
  static const int _maxFlagged = 5;

  static List<UnusualExpense> detect(
    List<(String category, double amount, DateTime at, String? description)>
    samples,
  ) {
    final grouped = <String, List<(double, DateTime, String?)>>{};
    for (final (category, amount, at, description) in samples) {
      grouped.putIfAbsent(category, () => []).add((amount, at, description));
    }

    final flagged = <UnusualExpense>[];

    grouped.forEach((category, entries) {
      if (entries.length < _minimumSamples) return;

      final average =
          entries.fold<double>(0, (sum, entry) => sum + entry.$1) /
          entries.length;
      if (average <= 0) return;

      final kind = ExpenseCategory.parse(category);

      for (final (amount, at, description) in entries) {
        final ratio = amount / average;
        if (ratio < _outlierMultiplier) continue;

        flagged.add(
          UnusualExpense(
            category: kind,
            description: description?.isNotEmpty == true ? description : null,
            amount: amount,
            categoryAverage: average,
            timesAboveAverage: double.parse(ratio.toStringAsFixed(1)),
            occurredAt: at,
          ),
        );
      }
    });

    flagged.sort((a, b) => b.timesAboveAverage.compareTo(a.timesAboveAverage));
    return flagged.take(_maxFlagged).toList(growable: false);
  }
}
