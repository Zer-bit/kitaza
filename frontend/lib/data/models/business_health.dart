enum HealthRating { green, yellow, red }

/// One reason behind a health rating. Typed rather than a sentence so each
/// screen can phrase it in the owner's language.
sealed class HealthReason {
  const HealthReason();
}

final class ProfitEarned extends HealthReason {
  const ProfitEarned(this.amount);
  final double amount;
}

final class SpentMoreThanSold extends HealthReason {
  const SpentMoreThanSold(this.amount);
  final double amount;
}

final class HealthyMargin extends HealthReason {
  const HealthyMargin(this.percent);
  final int percent;
}

final class ThinMargin extends HealthReason {
  const ThinMargin(this.percent);
  final int percent;
}

final class VeryThinMargin extends HealthReason {
  const VeryThinMargin(this.percent);
  final int percent;
}

final class ProfitUp extends HealthReason {
  const ProfitUp();
}

final class ProfitDown extends HealthReason {
  const ProfitDown();
}

final class WithdrewMoreThanProfit extends HealthReason {
  const WithdrewMoreThanProfit(this.amount);
  final double amount;
}

final class NeedsRestock extends HealthReason {
  const NeedsRestock(this.count);
  final int count;
}

class BusinessHealth {
  const BusinessHealth({
    required this.rating,
    required this.score,
    required this.reasons,
    this.hasSales = true,
  });

  final HealthRating rating;
  final int score;
  final List<HealthReason> reasons;

  /// A store with no sales yet is not judged at all.
  final bool hasSales;

  static const BusinessHealth unknown = BusinessHealth(
    rating: HealthRating.yellow,
    score: 50,
    reasons: [],
    hasSales: false,
  );
}
