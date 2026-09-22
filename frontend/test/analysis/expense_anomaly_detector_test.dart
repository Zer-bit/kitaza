import 'package:flutter_test/flutter_test.dart';
import 'package:kitaza_app/data/analysis/expense_anomaly_detector.dart';

void main() {
  final now = DateTime(2026, 9, 22);

  List<(String, double, DateTime, String?)> samples(
    String category,
    List<double> amounts,
  ) {
    return [
      for (var i = 0; i < amounts.length; i++)
        (category, amounts[i], now.subtract(Duration(days: i)), null),
    ];
  }

  group('ExpenseAnomalyDetector', () {
    test('needs enough history before flagging anything', () {
      final flagged = ExpenseAnomalyDetector.detect(
        samples('utilities', [100, 5000]),
      );

      expect(flagged, isEmpty);
    });

    test('flags spending far above the category average', () {
      final flagged = ExpenseAnomalyDetector.detect(
        samples('utilities', [100, 110, 95, 105, 2000]),
      );

      expect(flagged, hasLength(1));
      expect(flagged.single.amount, 2000);
      expect(flagged.single.timesAboveAverage, greaterThan(2.5));
    });

    test('leaves consistent spending alone', () {
      final flagged = ExpenseAnomalyDetector.detect(
        samples('transportation', [200, 210, 190, 205, 195, 215]),
      );

      expect(flagged, isEmpty);
    });

    test('compares each category against its own history', () {
      final flagged = ExpenseAnomalyDetector.detect([
        ...samples('utilities', [100, 100, 100, 100]),
        ...samples('inventory', [5000, 5200, 4800, 5100]),
      ]);

      // Inventory is far larger than utilities in absolute terms, but it is
      // normal *for inventory*, so nothing is flagged.
      expect(flagged, isEmpty);
    });

    test('reports at most five, worst first', () {
      final flagged = ExpenseAnomalyDetector.detect(
        samples('other', [10, 10, 10, 10, 100, 200, 300, 400, 500, 600, 700]),
      );

      expect(flagged.length, lessThanOrEqualTo(5));
      expect(
        flagged.first.timesAboveAverage,
        greaterThanOrEqualTo(flagged.last.timesAboveAverage),
      );
    });
  });
}
