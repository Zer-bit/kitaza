import '../models/business_health.dart';

class ScoreInputs {
  const ScoreInputs({
    required this.salesTotal,
    required this.netProfit,
    required this.previousNetProfit,
    required this.withdrawalsTotal,
    required this.lowStockCount,
  });

  final double salesTotal;
  final double netProfit;
  final double previousNetProfit;
  final double withdrawalsTotal;
  final int lowStockCount;
}

/// The offline twin of the server's health score. Both implementations use the
/// same weights so an owner sees the same rating whether or not they have
/// signal.
abstract final class BusinessScoreCalculator {
  static const int _healthyMarginPercent = 15;
  static const int _thinMarginPercent = 5;

  static BusinessHealth evaluate(ScoreInputs inputs) {
    if (inputs.salesTotal <= 0) return BusinessHealth.unknown;

    var score = 50;
    final reasons = <String>[];

    if (inputs.netProfit > 0) {
      score += 25;
      reasons.add('You earned a profit of ${_peso(inputs.netProfit)}.');
    } else {
      score -= 30;
      reasons.add('You spent ${_peso(-inputs.netProfit)} more than you sold.');
    }

    final margin = ((inputs.netProfit / inputs.salesTotal) * 100).round();
    if (margin >= _healthyMarginPercent) {
      score += 15;
      reasons.add('Healthy margin: $margin% of sales is profit.');
    } else if (margin >= _thinMarginPercent) {
      reasons.add('Thin margin: only $margin% of sales is profit.');
    } else if (margin > 0) {
      score -= 10;
      reasons.add('Very thin margin: $margin% of sales is profit.');
    }

    if (inputs.previousNetProfit != 0) {
      if (inputs.netProfit > inputs.previousNetProfit) {
        score += 10;
        reasons.add('Profit is higher than the previous period.');
      } else if (inputs.netProfit < inputs.previousNetProfit) {
        score -= 10;
        reasons.add('Profit is lower than the previous period.');
      }
    }

    if (inputs.withdrawalsTotal > inputs.netProfit &&
        inputs.withdrawalsTotal > 0) {
      score -= 15;
      reasons.add(
        'You withdrew ${_peso(inputs.withdrawalsTotal)}, more than the profit you made.',
      );
    }

    if (inputs.lowStockCount > 0) {
      score -= 5;
      reasons.add('${inputs.lowStockCount} product(s) need restocking.');
    }

    final clamped = score.clamp(0, 100);
    final rating = switch (clamped) {
      >= 70 => HealthRating.green,
      >= 40 => HealthRating.yellow,
      _ => HealthRating.red,
    };

    return BusinessHealth(
      rating: rating,
      score: clamped,
      headline: switch (rating) {
        HealthRating.green => 'Your store is doing well',
        HealthRating.yellow => 'Keep an eye on your numbers',
        HealthRating.red => 'Your store needs attention',
      },
      reasons: reasons,
    );
  }

  static String _peso(double amount) => '₱${amount.toStringAsFixed(2)}';
}
