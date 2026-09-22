import 'package:flutter_test/flutter_test.dart';
import 'package:kitaza_app/data/analysis/business_score_calculator.dart';
import 'package:kitaza_app/data/models/business_health.dart';

void main() {
  group('BusinessScoreCalculator', () {
    test('a store with no sales is not judged', () {
      final health = BusinessScoreCalculator.evaluate(
        const ScoreInputs(
          salesTotal: 0,
          netProfit: 0,
          previousNetProfit: 0,
          withdrawalsTotal: 0,
          lowStockCount: 0,
        ),
      );

      expect(health.rating, HealthRating.yellow);
      expect(health.headline, contains('No sales'));
    });

    test('a profitable, improving store rates green', () {
      final health = BusinessScoreCalculator.evaluate(
        const ScoreInputs(
          salesTotal: 10000,
          netProfit: 2500,
          previousNetProfit: 1800,
          withdrawalsTotal: 500,
          lowStockCount: 0,
        ),
      );

      expect(health.rating, HealthRating.green);
      expect(health.score, greaterThanOrEqualTo(70));
    });

    test('spending more than you sell rates red', () {
      final health = BusinessScoreCalculator.evaluate(
        const ScoreInputs(
          salesTotal: 5000,
          netProfit: -1200,
          previousNetProfit: 400,
          withdrawalsTotal: 0,
          lowStockCount: 2,
        ),
      );

      expect(health.rating, HealthRating.red);
      expect(
        health.reasons.any((reason) => reason.contains('more than you sold')),
        isTrue,
      );
    });

    test('withdrawing more than the profit is called out', () {
      final health = BusinessScoreCalculator.evaluate(
        const ScoreInputs(
          salesTotal: 8000,
          netProfit: 900,
          previousNetProfit: 900,
          withdrawalsTotal: 3000,
          lowStockCount: 0,
        ),
      );

      expect(
        health.reasons.any((reason) => reason.contains('withdrew')),
        isTrue,
      );
    });

    test('score never leaves the 0-100 range', () {
      final health = BusinessScoreCalculator.evaluate(
        const ScoreInputs(
          salesTotal: 1000,
          netProfit: -50000,
          previousNetProfit: 9000,
          withdrawalsTotal: 20000,
          lowStockCount: 40,
        ),
      );

      expect(health.score, inInclusiveRange(0, 100));
    });
  });
}
