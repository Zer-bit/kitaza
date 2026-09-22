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
    final reasons = <HealthReason>[];

    if (inputs.netProfit > 0) {
      score += 25;
      reasons.add(ProfitEarned(inputs.netProfit));
    } else {
      score -= 30;
      reasons.add(SpentMoreThanSold(-inputs.netProfit));
    }

    final margin = ((inputs.netProfit / inputs.salesTotal) * 100).round();
    if (margin >= _healthyMarginPercent) {
      score += 15;
      reasons.add(HealthyMargin(margin));
    } else if (margin >= _thinMarginPercent) {
      reasons.add(ThinMargin(margin));
    } else if (margin > 0) {
      score -= 10;
      reasons.add(VeryThinMargin(margin));
    }

    if (inputs.previousNetProfit != 0) {
      if (inputs.netProfit > inputs.previousNetProfit) {
        score += 10;
        reasons.add(const ProfitUp());
      } else if (inputs.netProfit < inputs.previousNetProfit) {
        score -= 10;
        reasons.add(const ProfitDown());
      }
    }

    if (inputs.withdrawalsTotal > inputs.netProfit &&
        inputs.withdrawalsTotal > 0) {
      score -= 15;
      reasons.add(WithdrewMoreThanProfit(inputs.withdrawalsTotal));
    }

    if (inputs.lowStockCount > 0) {
      score -= 5;
      reasons.add(NeedsRestock(inputs.lowStockCount));
    }

    final clamped = score.clamp(0, 100);
    final rating = switch (clamped) {
      >= 70 => HealthRating.green,
      >= 40 => HealthRating.yellow,
      _ => HealthRating.red,
    };

    return BusinessHealth(rating: rating, score: clamped, reasons: reasons);
  }
}
