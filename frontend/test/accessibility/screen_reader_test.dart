import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitaza_app/data/models/business_health.dart';
import 'package:kitaza_app/data/models/report_models.dart';
import 'package:kitaza_app/features/dashboard/widgets/health_banner.dart';
import 'package:kitaza_app/features/reports/widgets/profit_trend_chart.dart';
import 'package:kitaza_app/shared/widgets/stat_card.dart';

import '../support/localized.dart';

void main() {
  testWidgets('the profit chart is described in words, not left silent', (
    tester,
  ) async {
    final points = [
      DailyProfitPoint(
        day: DateTime(2026, 9, 20),
        salesTotal: 900,
        expensesTotal: 100,
        netProfit: 800,
      ),
      DailyProfitPoint(
        day: DateTime(2026, 9, 21),
        salesTotal: 300,
        expensesTotal: 450,
        netProfit: -150,
      ),
      DailyProfitPoint(
        day: DateTime(2026, 9, 22),
        salesTotal: 500,
        expensesTotal: 100,
        netProfit: 400,
      ),
    ];

    await tester.pumpWidget(
      localized(Scaffold(body: ProfitTrendChart(points: points))),
    );

    expect(
      find.bySemanticsLabel(
        RegExp(
          r'last 3 days\. Best day 20 Sep, \+₱800\.00\. Worst day 21 Sep, -₱150\.00',
        ),
      ),
      findsOneWidget,
    );
  });

  // A Card groups its contents for screen readers on its own; this guards
  // that behaviour rather than any code of ours.
  testWidgets('a stat card is announced as one sentence', (tester) async {
    await tester.pumpWidget(
      localized(
        const Scaffold(
          body: StatCard(
            label: 'Profit',
            amount: 1200,
            caption: '18% of sales',
          ),
        ),
      ),
    );

    // What TalkBack or VoiceOver reads when the card is focused.
    final spoken = tester
        .getSemantics(find.text('Profit'))
        .getSemanticsData()
        .label;
    expect(spoken, contains('Profit'));
    expect(spoken, contains('₱1,200.00'));
    expect(spoken, contains('18% of sales'));
  });

  testWidgets('the health banner is read as one message', (tester) async {
    await tester.pumpWidget(
      localized(
        const Scaffold(
          body: HealthBanner(
            health: BusinessHealth(
              rating: HealthRating.red,
              score: 20,
              reasons: [SpentMoreThanSold(500)],
            ),
          ),
        ),
      ),
    );

    final spoken = tester
        .getSemantics(find.text('Your store needs attention'))
        .getSemanticsData()
        .label;
    expect(spoken, contains('Warning · 20'));
    expect(spoken, contains('Your store needs attention'));
    expect(spoken, contains('You spent ₱500.00 more than you sold.'));
  });
}
