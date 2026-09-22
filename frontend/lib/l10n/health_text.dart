import '../core/formatting/peso_formatter.dart';
import '../data/models/business_health.dart';
import 'generated/app_localizations.dart';

extension HealthText on AppLocalizations {
  String healthHeadline(BusinessHealth health) {
    if (!health.hasSales) return healthHeadlineNoSales;

    return switch (health.rating) {
      HealthRating.green => healthHeadlineGreen,
      HealthRating.yellow => healthHeadlineYellow,
      HealthRating.red => healthHeadlineRed,
    };
  }

  List<String> healthReasons(BusinessHealth health) {
    if (!health.hasSales) return [healthReasonNoSales];
    return health.reasons.map(healthReason).toList(growable: false);
  }

  String healthReason(HealthReason reason) => switch (reason) {
    ProfitEarned(:final amount) => healthReasonProfit(
      PesoFormatter.format(amount),
    ),
    SpentMoreThanSold(:final amount) => healthReasonLoss(
      PesoFormatter.format(amount),
    ),
    HealthyMargin(:final percent) => healthReasonHealthyMargin(percent),
    ThinMargin(:final percent) => healthReasonThinMargin(percent),
    VeryThinMargin(:final percent) => healthReasonVeryThinMargin(percent),
    ProfitUp() => healthReasonProfitUp,
    ProfitDown() => healthReasonProfitDown,
    WithdrewMoreThanProfit(:final amount) => healthReasonOverWithdrawn(
      PesoFormatter.format(amount),
    ),
    NeedsRestock(:final count) => healthReasonRestock(count),
  };
}
