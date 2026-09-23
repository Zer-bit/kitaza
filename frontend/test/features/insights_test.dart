import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitaza_app/app/route_paths.dart';
import 'package:kitaza_app/data/models/auth_session.dart';
import 'package:kitaza_app/data/models/benchmark_report.dart';
import 'package:kitaza_app/data/remote/benchmarks_api.dart';
import 'package:kitaza_app/data/remote/team_api.dart';
import 'package:kitaza_app/data/repositories/product_repository.dart';
import 'package:kitaza_app/data/repositories/sale_repository.dart';
import 'package:kitaza_app/features/authentication/auth_controller.dart';
import 'package:kitaza_app/features/reports/reports_screen.dart';
import 'package:kitaza_app/features/settings/settings_screen.dart';

import '../support/app_harness.dart';
import '../support/in_memory_database.dart';
import '../support/team_fakes.dart';

void main() {
  late FakeBenchmarksApi benchmarks;
  late FakeTeamApi team;

  setUp(() {
    benchmarks = FakeBenchmarksApi(
      report: const BenchmarkReport(available: false),
    );
    team = FakeTeamApi();
  });

  Future<TestPhone> open(
    WidgetTester tester, {
    AuthSession? session,
    Locale locale = const Locale('en'),
    String path = RoutePaths.reports,
    WidgetBuilder? screen,
    bool cloud = false,
  }) async {
    final phone = await TestPhone.open(
      tester,
      screens: {path: screen ?? (_) => const ReportsScreen()},
      locale: locale,
      cloud: cloud,
      overrides: (_, _) => [
        if (session != null) currentSessionProvider.overrideWithValue(session),
        benchmarksApiProvider.overrideWithValue(benchmarks),
        teamApiProvider.overrideWithValue(team),
      ],
    );
    return phone;
  }

  /// A store that sells four Coke a day and is nearly out.
  Future<void> sellingFast(TestPhone phone) async {
    final coke = await ProductRepository(db: phone.db, storeId: testStoreId)
        .save(
          name: 'Coke 1.5L',
          costPrice: 68,
          sellingPrice: 75,
          stockQuantity: 92,
          reorderLevel: 6,
        );
    final sales = SaleRepository(db: phone.db, storeId: testStoreId);
    for (var back = 20; back >= 0; back--) {
      await sales.record(
        cart: [CartLine.fromProduct(coke, quantity: 4)],
        occurredAt: DateTime.now().subtract(Duration(days: back)),
      );
    }
  }

  testWidgets('what to reorder is shown with the reason behind it', (
    tester,
  ) async {
    final phone = await open(tester);
    await sellingFast(phone);
    await phone.goTo(tester, RoutePaths.reports);

    await tester.scrollUntilVisible(find.text('Reorder soon'), 250);
    expect(find.text('Coke 1.5L'), findsWidgets);
    expect(find.textContaining('About 4 pc a day'), findsOneWidget);
    expect(find.textContaining('Order'), findsOneWidget);
  });

  testWidgets('the arithmetic is there for anyone who wants it', (
    tester,
  ) async {
    final phone = await open(tester);
    await sellingFast(phone);
    await phone.goTo(tester, RoutePaths.reports);

    await tester.scrollUntilVisible(find.text('How these are worked out'), 250);
    await phone.tapAfterScrolling(
      tester,
      find.text('How these are worked out'),
    );

    expect(find.textContaining('last four weeks'), findsOneWidget);
    expect(find.textContaining('out of stock left out'), findsOneWidget);
  });

  testWidgets('a store with barely any history is told so, not guessed at', (
    tester,
  ) async {
    final phone = await open(tester);
    final product = await ProductRepository(db: phone.db, storeId: testStoreId)
        .save(
          name: 'Coke',
          costPrice: 68,
          sellingPrice: 75,
          stockQuantity: 20,
          reorderLevel: 0,
        );
    await SaleRepository(
      db: phone.db,
      storeId: testStoreId,
    ).record(cart: [CartLine.fromProduct(product)]);
    await phone.goTo(tester, RoutePaths.reports);

    await tester.scrollUntilVisible(find.text('Suggestions'), 250);
    expect(find.textContaining('two weeks'), findsOneWidget);
    expect(find.text('Reorder soon'), findsNothing);
    expect(find.text('Prices worth a look'), findsNothing);
  });

  testWidgets('a price below cost is called out in Filipino too', (
    tester,
  ) async {
    final phone = await open(tester, locale: const Locale('fil'));
    final oil = await ProductRepository(db: phone.db, storeId: testStoreId)
        .save(
          name: 'Cooking oil 1L',
          costPrice: 95,
          sellingPrice: 90,
          stockQuantity: 12,
          reorderLevel: 0,
        );
    final sales = SaleRepository(db: phone.db, storeId: testStoreId);
    for (var back = 20; back >= 0; back--) {
      await sales.record(
        cart: [CartLine.fromProduct(oil)],
        occurredAt: DateTime.now().subtract(Duration(days: back)),
      );
    }
    await phone.goTo(tester, RoutePaths.reports);

    await tester.scrollUntilVisible(
      find.text('Mga presyong dapat tingnan'),
      250,
    );
    expect(find.textContaining('Mas mura pa sa ₱95.00'), findsOneWidget);
    expect(find.textContaining('Subukan ang'), findsOneWidget);
  });

  group('comparisons with other stores', () {
    testWidgets('are shown with how many stores they came from', (
      tester,
    ) async {
      benchmarks.report = comparedWith(31);
      final phone = await open(tester, session: cloudOwner());
      await sellingFast(phone);
      await phone.goTo(tester, RoutePaths.reports);

      await tester.scrollUntilVisible(find.text('Stores like yours'), 250);
      expect(
        find.textContaining('middle of 31 similar stores'),
        findsOneWidget,
      );
      expect(find.text('You: 14%'), findsOneWidget);
      expect(find.text('Usual: 22%'), findsOneWidget);
      expect(find.text('You: ₱1,800.00'), findsOneWidget);
    });

    testWidgets('are not shown at all offline', (tester) async {
      benchmarks.report = comparedWith(31);
      final phone = await open(tester);
      await sellingFast(phone);
      await phone.goTo(tester, RoutePaths.reports);

      expect(find.text('Stores like yours'), findsNothing);
    });

    testWidgets('say why when the owner keeps their figures back', (
      tester,
    ) async {
      benchmarks.report = const BenchmarkReport(
        available: false,
        unavailableBecause: NoComparison.notSharing,
      );
      final phone = await open(tester, session: cloudOwner());
      await sellingFast(phone);
      await phone.goTo(tester, RoutePaths.reports);

      await tester.scrollUntilVisible(find.text('Stores like yours'), 250);
      expect(
        find.textContaining('while you keep your own figures back'),
        findsOneWidget,
      );
    });

    testWidgets('sharing can be turned off in Settings', (tester) async {
      // A real cloud session, so the switch goes through the same path an
      // owner's tap does.
      final phone = await open(
        tester,
        cloud: true,
        path: RoutePaths.settings,
        screen: (_) => const SettingsScreen(),
      );
      await phone.goTo(tester, RoutePaths.settings);

      await tester.scrollUntilVisible(
        find.text('Share anonymous comparisons'),
        250,
      );
      expect(find.textContaining('Never your name'), findsOneWidget);

      await phone.tapAfterScrolling(tester, find.byType(Switch).first);
      await phone.settle(tester);

      expect(team.updates.single.shareBenchmarks, isFalse);
    });
  });
}
