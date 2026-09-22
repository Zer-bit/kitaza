import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitaza_app/app/route_paths.dart';
import 'package:kitaza_app/core/platform/link_opener.dart';
import 'package:kitaza_app/data/models/auth_session.dart';
import 'package:kitaza_app/data/models/billing_overview.dart';
import 'package:kitaza_app/data/models/subscription.dart';
import 'package:kitaza_app/data/remote/billing_api.dart';
import 'package:kitaza_app/features/authentication/auth_controller.dart';
import 'package:kitaza_app/features/billing/plan_screen.dart';
import 'package:kitaza_app/features/dashboard/dashboard_screen.dart';

import '../support/app_harness.dart';
import '../support/team_fakes.dart';

void main() {
  late FakeBillingApi billing;
  late FakeLinkOpener browser;

  Future<TestPhone> open(
    WidgetTester tester,
    String path,
    WidgetBuilder screen, {
    AuthSession? session,
    Locale locale = const Locale('en'),
  }) async {
    final phone = await TestPhone.open(
      tester,
      screens: {path: screen},
      locale: locale,
      overrides: (_, _) => [
        currentSessionProvider.overrideWithValue(
          session ?? cloudOwner(subscription: pausedPlan),
        ),
        billingApiProvider.overrideWithValue(billing),
        linkOpenerProvider.overrideWithValue(browser),
      ],
    );
    await phone.goTo(tester, path);
    return phone;
  }

  setUp(() {
    billing = FakeBillingApi(overviewToShow: billingOverview());
    browser = FakeLinkOpener();
  });

  group('the plan screen', () {
    testWidgets('a paused owner sees why, the prices, and pays with GCash', (
      tester,
    ) async {
      final phone = await open(
        tester,
        RoutePaths.plan,
        (_) => const PlanScreen(),
      );

      expect(find.textContaining('Cloud backup is paused'), findsOneWidget);
      expect(find.text('₱99.00 a month'), findsOneWidget);
      expect(find.text('₱199.00 a month'), findsOneWidget);

      await phone.tapAfterScrolling(
        tester,
        find.text('Pay ₱199.00 with GCash or Maya'),
      );

      expect(billing.checkouts.single, (plan: PlanTier.pro, months: 1));
      expect(browser.opened.single.host, 'pay.example');
      expect(find.textContaining('Finish paying'), findsOneWidget);
    });

    testWidgets('a year of Basic costs ten months', (tester) async {
      final phone = await open(
        tester,
        RoutePaths.plan,
        (_) => const PlanScreen(),
      );

      await tester.tap(find.text('Yearly, 2 months free'));
      await tester.pumpAndSettle();
      await phone.tapAfterScrolling(tester, find.text('Basic'));

      expect(find.text('₱990.00 a year'), findsOneWidget);
      await phone.tapAfterScrolling(
        tester,
        find.text('Pay ₱990.00 with GCash or Maya'),
      );
      expect(billing.checkouts.single, (plan: PlanTier.basic, months: 12));
    });

    testWidgets('past payments are listed', (tester) async {
      billing.overviewToShow = billingOverview(
        subscription: const Subscription(
          status: SubscriptionStatus.active,
          plan: PlanTier.pro,
        ),
        payments: [
          PaymentRecord(
            id: 'p1',
            plan: PlanTier.pro,
            months: 12,
            amount: 1990,
            paidAt: DateTime(2026, 9, 1),
            method: 'gcash',
          ),
        ],
      );
      await open(tester, RoutePaths.plan, (_) => const PlanScreen());

      await tester.scrollUntilVisible(find.text('Pro · 1 year'), 200);
      expect(find.text('₱1,990.00'), findsOneWidget);
      expect(find.text('Current'), findsOneWidget);
    });

    testWidgets('on a server that does not charge, there is nothing to buy', (
      tester,
    ) async {
      billing.overviewToShow = billingOverview(
        enabled: false,
        subscription: const Subscription.unlimited(),
      );
      await open(tester, RoutePaths.plan, (_) => const PlanScreen());

      expect(find.textContaining('does not charge'), findsOneWidget);
      expect(find.textContaining('with GCash'), findsNothing);
      expect(find.text('Use Kitaza offline for free'), findsOneWidget);
    });

    testWidgets('leaving the cloud asks first and says nothing is lost', (
      tester,
    ) async {
      final phone = await open(
        tester,
        RoutePaths.plan,
        (_) => const PlanScreen(),
      );

      await phone.tapAfterScrolling(
        tester,
        find.text('Use Kitaza offline for free'),
      );
      expect(find.text('Switch this phone to offline?'), findsOneWidget);
      expect(find.textContaining('keeps every record'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    });

    testWidgets('in Filipino', (tester) async {
      await open(
        tester,
        RoutePaths.plan,
        (_) => const PlanScreen(),
        locale: const Locale('fil'),
      );

      expect(
        find.textContaining('Naka-pause ang cloud backup'),
        findsOneWidget,
      );
      expect(find.text('₱199.00 kada buwan'), findsOneWidget);
    });
  });

  group('the home screen reminder', () {
    Future<void> home(WidgetTester tester, AuthSession session) => open(
      tester,
      RoutePaths.dashboard,
      (_) => const DashboardScreen(),
      session: session,
    );

    testWidgets('stays quiet with weeks of trial left', (tester) async {
      await home(tester, cloudOwner(subscription: trialWithDaysLeft(20)));
      expect(find.textContaining('trial ends'), findsNothing);
    });

    testWidgets('speaks up in the trial\'s last days', (tester) async {
      await home(tester, cloudOwner(subscription: trialWithDaysLeft(3)));
      expect(find.text('Your free trial ends in 3 days.'), findsOneWidget);
      expect(find.text('Choose a plan'), findsOneWidget);
    });

    testWidgets('a paused owner is offered a plan', (tester) async {
      await home(tester, cloudOwner(subscription: pausedPlan));
      expect(find.textContaining('Cloud backup is paused'), findsOneWidget);
      expect(find.text('Choose a plan'), findsOneWidget);
    });

    testWidgets('a cashier is told to ask the owner, with no button', (
      tester,
    ) async {
      await home(tester, staffMember({}, subscription: pausedPlan));
      expect(find.textContaining('Ask the owner to renew'), findsOneWidget);
      expect(find.text('Choose a plan'), findsNothing);
    });
  });
}
