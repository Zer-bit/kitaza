import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitaza_app/app/route_paths.dart';
import 'package:kitaza_app/data/models/expense_category.dart';
import 'package:kitaza_app/data/models/payment_method.dart';
import 'package:kitaza_app/data/repositories/expense_repository.dart';
import 'package:kitaza_app/data/repositories/product_repository.dart';
import 'package:kitaza_app/data/repositories/sale_repository.dart';
import 'package:kitaza_app/data/repositories/withdrawal_repository.dart';
import 'package:kitaza_app/features/dashboard/dashboard_screen.dart';
import 'package:kitaza_app/features/expenses/expense_history_screen.dart';
import 'package:kitaza_app/features/expenses/record_expense_screen.dart';
import 'package:kitaza_app/features/products/product_editor_screen.dart';
import 'package:kitaza_app/features/products/product_list_screen.dart';
import 'package:kitaza_app/features/reports/reports_screen.dart';
import 'package:kitaza_app/features/sales/record_sale_screen.dart';
import 'package:kitaza_app/features/sales/sale_history_screen.dart';
import 'package:kitaza_app/features/settings/settings_screen.dart';
import 'package:kitaza_app/features/withdrawals/withdrawal_screen.dart';

import '../support/app_harness.dart';
import '../support/in_memory_database.dart';

/// Every main screen, checked the way an older owner with large text on a
/// small phone - or someone using a screen reader - would meet it.
final Map<String, WidgetBuilder> _screens = {
  RoutePaths.dashboard: (_) => const DashboardScreen(),
  RoutePaths.recordSale: (_) => const RecordSaleScreen(),
  RoutePaths.saleHistory: (_) => const SaleHistoryScreen(),
  RoutePaths.recordExpense: (_) => const RecordExpenseScreen(),
  RoutePaths.expenseHistory: (_) => const ExpenseHistoryScreen(),
  RoutePaths.products: (_) => const ProductListScreen(),
  RoutePaths.productEditor: (_) => const ProductEditorScreen(),
  RoutePaths.withdrawals: (_) => const WithdrawalScreen(),
  RoutePaths.reports: (_) => const ReportsScreen(),
  RoutePaths.settings: (_) => const SettingsScreen(),
};

/// A believable day at the counter, with the long names and large amounts
/// that break layouts: several sales, a loss-making product, low stock,
/// expenses in several categories, and an owner withdrawal.
Future<void> _seedBusyDay(TestPhone phone) async {
  final db = phone.db;
  final products = ProductRepository(db: db, storeId: testStoreId);
  final sales = SaleRepository(db: db, storeId: testStoreId);

  final rice = await products.save(
    name: 'Premium Dinorado Rice, 25 kilogram sack (per kilo)',
    costPrice: 52,
    sellingPrice: 58.5,
    stockQuantity: 2.5,
    reorderLevel: 10,
  );
  final coke = await products.save(
    name: 'Coke 1.5L',
    costPrice: 68,
    sellingPrice: 75,
    stockQuantity: 24,
    reorderLevel: 6,
  );
  final loss = await products.save(
    name: 'Cooking oil 1L',
    costPrice: 95,
    sellingPrice: 90,
    stockQuantity: 12,
    reorderLevel: 3,
  );

  await sales.record(cart: [CartLine.fromProduct(rice, quantity: 2)]);
  await sales.record(
    cart: [CartLine.fromProduct(coke, quantity: 3), CartLine.fromProduct(loss)],
    paymentMethod: PaymentMethod.bankTransfer,
  );
  await sales.record(
    cart: [CartLine.quick(12345.67)],
    paymentMethod: PaymentMethod.utang,
  );

  final expenses = ExpenseRepository(db: db, storeId: testStoreId);
  await expenses.record(
    category: ExpenseCategory.taxesPermits,
    amount: 18500,
    description: 'Barangay business permit renewal and sanitary permit',
  );
  await expenses.record(category: ExpenseCategory.transportation, amount: 350);

  await WithdrawalRepository(
    db: db,
    storeId: testStoreId,
  ).record(amount: 25000, reason: 'Tuition for the eldest, second semester');
}

void main() {
  for (final entry in _screens.entries) {
    group(entry.key, () {
      for (final (label, scale, brightness, locale, busy) in const [
        ('normal text, light', 1.0, Brightness.light, Locale('en'), false),
        ('large text, light', 1.4, Brightness.light, Locale('en'), false),
        ('large text, dark', 1.4, Brightness.dark, Locale('en'), false),
        // Filipino strings run longer than English; they must fit too.
        ('large text, Filipino', 1.4, Brightness.light, Locale('fil'), false),
        (
          'busy day, large text, Filipino',
          1.4,
          Brightness.light,
          Locale('fil'),
          true,
        ),
        (
          'busy day, large text, dark',
          1.4,
          Brightness.dark,
          Locale('en'),
          true,
        ),
      ]) {
        testWidgets(label, (tester) async {
          final phone = await TestPhone.open(
            tester,
            screens: {entry.key: entry.value},
            textScale: scale,
            brightness: brightness,
            locale: locale,
          );
          if (busy) await _seedBusyDay(phone);
          await phone.goTo(tester, entry.key);

          // A layout overflow is reported as an exception and fails the test
          // by itself; these add the platform accessibility guidelines.
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          await expectLater(tester, meetsGuideline(textContrastGuideline));
        });
      }
    });
  }
}
