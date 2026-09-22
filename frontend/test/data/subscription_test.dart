import 'package:flutter_test/flutter_test.dart';
import 'package:kitaza_app/data/models/subscription.dart';

void main() {
  final now = DateTime(2026, 9, 22, 9);

  Subscription trialEnding(Duration left) => Subscription(
    status: SubscriptionStatus.trial,
    plan: PlanTier.pro,
    periodEndsAt: now.add(left),
    pausesAt: now.add(left + const Duration(days: 7)),
  );

  test('reads what the server sends, and survives being stored', () {
    final subscription = Subscription.fromJson({
      'status': 'active',
      'plan': 'basic',
      'period_ends_at': '2026-10-22T01:00:00Z',
      'pauses_at': '2026-10-29T01:00:00Z',
      'store_limit': 1,
      'allows_staff': false,
    });

    expect(subscription.status, SubscriptionStatus.active);
    expect(subscription.plan, PlanTier.basic);
    expect(subscription.storeLimit, 1);
    expect(subscription.allowsStaff, isFalse);
    expect(Subscription.decode(subscription.encode()), subscription);
  });

  test('an older server that says nothing means nothing is limited', () {
    expect(Subscription.fromJson(null), const Subscription.unlimited());
    expect(Subscription.decode('not json'), const Subscription.unlimited());
  });

  test('days left count a part day as a day', () {
    expect(trialEnding(const Duration(days: 2, hours: 3)).daysLeft(now), 3);
    expect(trialEnding(const Duration(hours: 1)).daysLeft(now), 1);
    expect(trialEnding(const Duration(days: -1)).daysLeft(now), 0);
  });

  test('the home screen speaks up only in the last five days, or later', () {
    expect(trialEnding(const Duration(days: 20)).needsAttention(now), isFalse);
    expect(trialEnding(const Duration(days: 5)).needsAttention(now), isTrue);
    expect(
      const Subscription(status: SubscriptionStatus.grace).needsAttention(now),
      isTrue,
    );
    expect(
      const Subscription(status: SubscriptionStatus.paused).needsAttention(now),
      isTrue,
    );
    expect(const Subscription.unlimited().needsAttention(now), isFalse);
  });
}
