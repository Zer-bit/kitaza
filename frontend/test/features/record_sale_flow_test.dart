import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitaza_app/app/route_paths.dart';
import 'package:kitaza_app/data/local/dao/product_dao.dart';
import 'package:kitaza_app/data/local/dao/sync_queue_dao.dart';
import 'package:kitaza_app/data/models/product.dart';
import 'package:kitaza_app/features/sales/record_sale_screen.dart';

import '../support/app_harness.dart';
import '../support/in_memory_database.dart';

void main() {
  Future<TestPhone> openSaleScreen(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
  }) async {
    final phone = await TestPhone.open(
      tester,
      locale: locale,
      screens: {RoutePaths.recordSale: (_) => const RecordSaleScreen()},
    );
    await phone.goTo(tester, RoutePaths.recordSale);
    return phone;
  }

  Future<void> typeOnKeypad(WidgetTester tester, String digits) async {
    for (final digit in digits.split('')) {
      await tester.tap(
        find.bySemanticsLabel(digit == '.' ? 'Decimal point' : digit).last,
      );
      await tester.pump();
    }
  }

  testWidgets('a cash sale typed on the keypad is saved in a few taps', (
    tester,
  ) async {
    final phone = await openSaleScreen(tester);

    await typeOnKeypad(tester, '25');
    expect(find.text('Save ₱25.00'), findsOneWidget);

    await tester.tap(find.text('Save ₱25.00'));
    await phone.settle(tester);

    expect(phone.isHome, isTrue, reason: 'the screen closes after saving');
    final sales = await phone.db.query('sales');
    expect(sales.single['total_amount'], 2500);
    expect(sales.single['payment_method'], 'cash');
    expect(await SyncQueueDao(phone.db).pendingCount(), 1);
  });

  testWidgets('the payment method chosen is the one recorded', (tester) async {
    final phone = await openSaleScreen(tester);

    await typeOnKeypad(tester, '120.5');
    await tester.tap(find.text('GCash'));
    await tester.pump();
    await tester.tap(find.text('Save ₱120.50'));
    await phone.settle(tester);

    final sale = (await phone.db.query('sales')).single;
    expect(sale['payment_method'], 'gcash');
    expect(sale['total_amount'], 12050);
  });

  testWidgets(
    'saving with nothing entered explains what to do and saves nothing',
    (tester) async {
      final phone = await openSaleScreen(tester);

      await tester.tap(find.text('Save ₱0.00'));
      await tester.pump();

      expect(
        find.text('Enter an amount or pick a product first.'),
        findsOneWidget,
      );
      expect(phone.isHome, isFalse);
      expect(await phone.db.query('sales'), isEmpty);
    },
  );

  testWidgets('picking a product from the catalogue takes it out of stock', (
    tester,
  ) async {
    final phone = await openSaleScreen(tester);
    await ProductDao(phone.db).upsert(
      testStoreId,
      Product(
        id: 'coke',
        name: 'Coke 290ml',
        costPrice: 15,
        sellingPrice: 20,
        stockQuantity: 10,
        reorderLevel: 3,
        updatedAt: DateTime.now().toUtc(),
      ),
    );

    await tester.tap(find.text('Product'));
    await phone.settle(tester);
    await tester.tap(find.text('Coke 290ml'));
    await tester.tap(find.text('Coke 290ml'));
    await phone.settle(tester);
    await tester.tapAt(const Offset(10, 10));
    await phone.settle(tester);

    expect(
      find.text('Save ₱40.00'),
      findsOneWidget,
      reason: 'two taps, two bottles',
    );
    await tester.tap(find.text('Save ₱40.00'));
    await phone.settle(tester);

    expect((await ProductDao(phone.db).find('coke'))!.stockQuantity, 8);
  });

  testWidgets('the whole flow works in Filipino', (tester) async {
    final phone = await openSaleScreen(tester, locale: const Locale('fil'));

    expect(find.text('Magbenta'), findsOneWidget);
    await typeOnKeypad(tester, '15');
    await tester.tap(find.text('I-save ang ₱15.00'));
    await phone.settle(tester);

    expect((await phone.db.query('sales')).single['total_amount'], 1500);
  });
}
