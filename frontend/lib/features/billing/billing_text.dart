import '../../core/formatting/day_formatter.dart';
import '../../data/models/subscription.dart';
import '../../l10n/l10n.dart';

extension BillingText on AppLocalizations {
  String planName(PlanTier plan) => switch (plan) {
    PlanTier.basic => planBasic,
    PlanTier.pro => planPro,
  };

  String planPoints(PlanTier plan) => switch (plan) {
    PlanTier.basic => planBasicPoints,
    PlanTier.pro => planProPoints,
  };

  /// One sentence on where the account stands.
  String subscriptionStatus(Subscription subscription, DateTime now) =>
      switch (subscription.status) {
        SubscriptionStatus.unlimited => planStatusUnlimited,
        SubscriptionStatus.trial => planStatusTrial(
          subscription.daysLeft(now) ?? 0,
        ),
        SubscriptionStatus.active => planStatusActive(
          planName(subscription.plan ?? PlanTier.basic),
          _date(subscription.periodEndsAt),
        ),
        SubscriptionStatus.grace => planStatusGrace(
          _date(subscription.pausesAt),
        ),
        SubscriptionStatus.paused => planStatusPaused,
      };

  /// The home screen's reminder, when one is due.
  String subscriptionReminder(Subscription subscription, DateTime now) =>
      switch (subscription.status) {
        SubscriptionStatus.trial => planBannerTrial(
          subscription.daysLeft(now) ?? 0,
        ),
        SubscriptionStatus.active => planBannerEnding(
          subscription.daysLeft(now) ?? 0,
        ),
        SubscriptionStatus.grace => planBannerGrace(
          _date(subscription.pausesAt),
        ),
        SubscriptionStatus.paused ||
        SubscriptionStatus.unlimited => planBannerPaused,
      };

  static String _date(DateTime? value) =>
      value == null ? '' : DayFormatter.fullDate(value);
}
