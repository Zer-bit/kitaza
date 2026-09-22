import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitaza_app/app/route_paths.dart';
import 'package:kitaza_app/data/catalog/starter_catalog.dart';
import 'package:kitaza_app/data/local/dao/sync_queue_dao.dart';
import 'package:kitaza_app/features/dashboard/dashboard_screen.dart';
import 'package:kitaza_app/features/dashboard/widgets/starter_prompt_card.dart';
import 'package:kitaza_app/features/products/product_list_screen.dart';

import '../support/app_harness.dart';

/// Scrolls a checklist row fully into view before tapping it. Partly visible
/// is not enough: the row can sit under the pinned Add button.
Future<void> untick(WidgetTester tester, String name) async {
  final row = find.text(name);
  await tester.scrollUntilVisible(
    row,
    200,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.ensureVisible(row);
  await tester.pumpAndSettle();
  await tester.tap(row);
  await tester.pump();
}

void main() {
  final total = StarterCatalog.items.length;

  testWidgets('a new store picks its usual products from the checklist', (
    tester,
  ) async {
    final phone = await TestPhone.open(
      tester,
      screens: {RoutePaths.products: (_) => const ProductListScreen()},
    );
    await phone.goTo(tester, RoutePaths.products);

    await tester.tap(find.text('Add common sari-sari items'));
    await phone.settle(tester);
    expect(find.textContaining('typical prices, not yours'), findsOneWidget);

    // This store sells no rice or candy.
    await untick(tester, 'Rice (per kilo)');
    await untick(tester, 'Candy (per piece)');

    await tester.tap(find.text('Add ${total - 2} products'));
    await phone.settle(tester);

    final products = await phone.db.query('products', orderBy: 'name');
    expect(products, hasLength(total - 2));
    expect(
      products.map((row) => row['name']),
      isNot(contains('Rice (per kilo)')),
    );
    expect(products.every((row) => row['stock_quantity'] == 0), isTrue);

    // Every product is queued for the cloud, with stock still zero and no
    // ledger entries: stock arrives with the first delivery.
    final queue = await SyncQueueDao(phone.db).pending(limit: 100);
    expect(
      queue.where((c) => c.entity == QueuedEntity.products),
      hasLength(total - 2),
    );
    expect(
      queue.where((c) => c.entity == QueuedEntity.stockMovements),
      isEmpty,
    );
  });

  testWidgets('a Filipino store gets Filipino product names', (tester) async {
    final phone = await TestPhone.open(
      tester,
      locale: const Locale('fil'),
      screens: {RoutePaths.products: (_) => const ProductListScreen()},
    );
    await phone.goTo(tester, RoutePaths.products);

    await tester.tap(find.text('Idagdag ang karaniwang paninda'));
    await phone.settle(tester);
    await tester.tap(find.text('Idagdag ang $total paninda'));
    await phone.settle(tester);

    final names = (await phone.db.query('products')).map((row) => row['name']);
    expect(names, contains('Itlog (bawat isa)'));
    expect(names, isNot(contains('Eggs (per piece)')));
  });

  testWidgets('the dashboard prompt disappears once the store has products', (
    tester,
  ) async {
    final phone = await TestPhone.open(
      tester,
      screens: {RoutePaths.dashboard: (_) => const DashboardScreen()},
    );
    await phone.goTo(tester, RoutePaths.dashboard);
    expect(find.text('Your product list is empty'), findsOneWidget);

    await tester.tap(find.text('Add common sari-sari items'));
    await phone.settle(tester);
    await tester.tap(find.text('Add $total products'));
    await phone.settle(tester);

    expect(find.byType(StarterPromptCard), findsOneWidget);
    expect(find.text('Your product list is empty'), findsNothing);
  });
}
