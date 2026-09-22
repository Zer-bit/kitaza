import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kitaza_app/app/route_paths.dart';
import 'package:kitaza_app/data/models/access_grant.dart';
import 'package:kitaza_app/data/models/auth_session.dart';
import 'package:kitaza_app/data/repositories/product_repository.dart';
import 'package:kitaza_app/data/repositories/sale_repository.dart';
import 'package:kitaza_app/features/authentication/auth_controller.dart';
import 'package:kitaza_app/features/dashboard/dashboard_screen.dart';
import 'package:kitaza_app/features/dashboard/widgets/health_banner.dart';
import 'package:kitaza_app/features/products/product_editor_screen.dart';
import 'package:kitaza_app/features/products/product_list_screen.dart';
import 'package:kitaza_app/features/sales/sale_history_screen.dart';
import 'package:kitaza_app/features/settings/settings_screen.dart';
import 'package:kitaza_app/features/shell/navigation_destinations.dart';

import '../support/app_harness.dart';
import '../support/in_memory_database.dart';
import '../support/team_fakes.dart';

void main() {
  final cashier = staffMember({});

  Future<TestPhone> openAs(
    WidgetTester tester,
    AuthSession session,
    String path,
    WidgetBuilder screen,
  ) async {
    final phone = await TestPhone.open(
      tester,
      screens: {
        path: screen,
        RoutePaths.productEditor: (context) => ProductEditorScreen(
          productId: GoRouterState.of(context).uri.queryParameters['id'],
        ),
      },
      overrides: (_, _) => [currentSessionProvider.overrideWithValue(session)],
    );

    final products = ProductRepository(db: phone.db, storeId: testStoreId);
    final coke = await products.save(
      name: 'Coke 1.5L',
      costPrice: 68,
      sellingPrice: 75,
      stockQuantity: 24,
      reorderLevel: 6,
    );
    await SaleRepository(
      db: phone.db,
      storeId: testStoreId,
    ).record(cart: [CartLine.fromProduct(coke, quantity: 2)]);

    await phone.goTo(tester, path);
    return phone;
  }

  group('tabs', () {
    List<String> tabsFor(AccessGrant access) =>
        destinationsFor(access).map((tab) => tab.path).toList();

    test('a cashier gets sales and products, no money tabs', () {
      expect(tabsFor(cashier.access), [
        RoutePaths.dashboard,
        RoutePaths.saleHistory,
        RoutePaths.products,
      ]);
    });

    test('permissions bring back their tabs', () {
      expect(
        tabsFor(staffMember({Permission.recordExpenses}).access),
        contains(RoutePaths.expenseHistory),
      );
      expect(
        tabsFor(staffMember({Permission.viewProfit}).access),
        containsAll([RoutePaths.expenseHistory, RoutePaths.reports]),
      );
      expect(tabsFor(cloudOwner().access), hasLength(5));
    });
  });

  testWidgets('a cashier\'s home shows takings but not profit', (tester) async {
    await openAs(
      tester,
      cashier,
      RoutePaths.dashboard,
      (_) => const DashboardScreen(),
    );

    expect(find.text('Add sale'), findsOneWidget);
    expect(find.text('₱150.00'), findsWidgets, reason: "today's takings");
    for (final hidden in ['Profit', 'Expense', 'Expenses', 'Cash kept']) {
      expect(find.text(hidden), findsNothing, reason: hidden);
    }
    expect(find.byType(HealthBanner), findsNothing);
    expect(find.text('Owner withdrawals'), findsNothing);
  });

  testWidgets('the owner still sees everything', (tester) async {
    await openAs(
      tester,
      cloudOwner(),
      RoutePaths.dashboard,
      (_) => const DashboardScreen(),
    );

    expect(find.text('Profit'), findsWidgets);
    expect(find.text('Expense'), findsOneWidget);
  });

  testWidgets('a cashier cannot void a sale or see its profit', (tester) async {
    await openAs(
      tester,
      cashier,
      RoutePaths.saleHistory,
      (_) => const SaleHistoryScreen(),
    );

    expect(find.textContaining('profit'), findsNothing);
    await tester.longPress(find.text('Coke 1.5L'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('a cashier browses products but cannot change them', (
    tester,
  ) async {
    final phone = await openAs(
      tester,
      cashier,
      RoutePaths.products,
      (_) => const ProductListScreen(),
    );

    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.textContaining('margin'), findsNothing);

    await tester.tap(find.text('Coke 1.5L'));
    await tester.pumpAndSettle();
    expect(find.byType(ProductListScreen), findsOneWidget);
    expect(phone.router.state.uri.path, RoutePaths.products);
  });

  testWidgets('a stock clerk edits prices without ever seeing the cost', (
    tester,
  ) async {
    final clerk = staffMember({Permission.manageProducts});
    await openAs(
      tester,
      clerk,
      RoutePaths.products,
      (_) => const ProductListScreen(),
    );

    await tester.tap(find.text('Coke 1.5L'));
    await tester.pumpAndSettle();

    expect(find.byType(ProductEditorScreen), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Cost (puhunan)'), findsNothing);
    expect(find.text('The owner sets the cost price.'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Selling price'), findsOneWidget);
  });

  testWidgets('staff settings leave out the owner\'s tools', (tester) async {
    await openAs(
      tester,
      cashier,
      RoutePaths.settings,
      (_) => const SettingsScreen(),
    );

    expect(find.text('Stores and staff'), findsNothing);
    expect(find.text('Backups'), findsNothing);
    await tester.scrollUntilVisible(find.text('Liza'), 200);
    expect(find.text('Staff at Test Store'), findsOneWidget);
  });

  testWidgets('a cloud owner finds stores, staff, devices and activity', (
    tester,
  ) async {
    await openAs(
      tester,
      cloudOwner(),
      RoutePaths.settings,
      (_) => const SettingsScreen(),
    );

    expect(find.text('Stores and staff'), findsOneWidget);
    expect(find.text("Nena's Carinderia sa Kanto"), findsOneWidget);
    for (final entry in ['Staff', 'Signed-in devices', 'Activity']) {
      await tester.scrollUntilVisible(find.text(entry), 200);
      expect(find.text(entry), findsOneWidget);
    }
  });
}
