import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kitaza_app/app/route_paths.dart';
import 'package:kitaza_app/data/local/dao/product_dao.dart';
import 'package:kitaza_app/data/models/product.dart';
import 'package:kitaza_app/features/products/product_editor_screen.dart';
import 'package:kitaza_app/features/sales/record_sale_screen.dart';
import 'package:kitaza_app/features/scanning/barcode_scanner.dart';

import '../support/app_harness.dart';
import '../support/in_memory_database.dart';

/// A camera that "sees" whatever codes the test lines up.
class _FakeScanner extends BarcodeScanner {
  _FakeScanner(this.codes);

  final List<String> codes;
  final List<String?> feedback = [];

  @override
  bool get isAvailable => true;

  @override
  Future<String?> scanOnce(BuildContext context) async =>
      codes.isEmpty ? null : codes.first;

  @override
  Future<void> scanContinuously(
    BuildContext context, {
    required FutureOr<String?> Function(String code) onCode,
  }) async {
    for (final code in codes) {
      feedback.add(await onCode(code));
    }
  }
}

Product _coke() => Product(
  id: 'coke',
  name: 'Coke 290ml',
  barcode: '4801981116072',
  costPrice: 15,
  sellingPrice: 20,
  stockQuantity: 10,
  reorderLevel: 2,
  unitLabel: 'pc',
  updatedAt: DateTime.now().toUtc(),
);

void main() {
  final screens = {
    RoutePaths.recordSale: (_) => const RecordSaleScreen(),
    RoutePaths.productEditor: (context) => ProductEditorScreen(
      productId: _query(context, 'id'),
      initialBarcode: _query(context, 'barcode'),
    ),
  };

  Future<TestPhone> open(WidgetTester tester, _FakeScanner scanner) async {
    final phone = await TestPhone.open(
      tester,
      screens: screens,
      overrides: (_, _) => [barcodeScannerProvider.overrideWithValue(scanner)],
    );
    await ProductDao(phone.db).upsert(testStoreId, _coke());
    return phone;
  }

  testWidgets('scanning at checkout puts each item in the cart', (
    tester,
  ) async {
    final scanner = _FakeScanner(['4801981116072', '4801981116072']);
    final phone = await open(tester, scanner);
    await phone.goTo(tester, RoutePaths.recordSale);

    await tester.tap(find.text('Scan'));
    await phone.settle(tester);

    expect(scanner.feedback, ['Coke 290ml added', 'Coke 290ml added']);
    expect(find.text('Save ₱40.00'), findsOneWidget);

    await tester.tap(find.text('Save ₱40.00'));
    await phone.settle(tester);
    expect((await ProductDao(phone.db).find('coke'))!.stockQuantity, 8);
  });

  testWidgets(
    'an unknown code can become a new product with the code filled in',
    (tester) async {
      final phone = await open(tester, _FakeScanner(['9999999999999']));
      await phone.goTo(tester, RoutePaths.recordSale);

      await tester.tap(find.text('Scan'));
      await phone.settle(tester);

      expect(find.text('No product has this code yet'), findsOneWidget);
      await tester.tap(find.text('Add as new product'));
      await phone.settle(tester);

      expect(find.text('Add product'), findsOneWidget);
      expect(
        find.widgetWithText(TextFormField, '9999999999999'),
        findsOneWidget,
      );
    },
  );

  testWidgets('the product editor fills the barcode from the camera', (
    tester,
  ) async {
    final phone = await open(tester, _FakeScanner(['4800016644290']));
    await phone.goTo(tester, RoutePaths.productEditor);

    await tester.tap(find.byTooltip('Scan'));
    await phone.settle(tester);
    expect(find.widgetWithText(TextFormField, '4800016644290'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'Skyflakes');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Cost (puhunan)'),
      '7',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Selling price'),
      '9',
    );
    await tester.ensureVisible(find.text('Save product'));
    await tester.tap(find.text('Save product'));
    await phone.settle(tester);

    final saved = await ProductDao(phone.db)
        .findByBarcode(testStoreId, '4800016644290');
    expect(saved?.name, 'Skyflakes');
  });

  testWidgets('a barcode gun typing into the product search picks the item', (
    tester,
  ) async {
    final phone = await open(tester, _FakeScanner([]));
    await phone.goTo(tester, RoutePaths.recordSale);

    await tester.tap(find.text('Product'));
    await phone.settle(tester);

    // What a keyboard-wedge scanner does: type the digits, then Enter.
    await tester.enterText(find.byType(TextField).last, '4801981116072');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await phone.settle(tester);
    await tester.tapAt(const Offset(10, 10));
    await phone.settle(tester);

    expect(find.text('Save ₱20.00'), findsOneWidget);
  });

  testWidgets('editing a price keeps the barcode and the unit', (tester) async {
    final phone = await open(tester, _FakeScanner([]));
    await ProductDao(phone.db).upsert(
      testStoreId,
      Product(
        id: 'rice',
        name: 'Rice',
        barcode: '1234567890128',
        unitLabel: 'kg',
        costPrice: 48,
        sellingPrice: 55,
        stockQuantity: 25,
        reorderLevel: 5,
        updatedAt: DateTime.now().toUtc(),
      ),
    );
    await phone.goTo(tester, '${RoutePaths.productEditor}?id=rice');

    await tester.enterText(find.widgetWithText(TextFormField, '55.00'), '58');
    await tester.ensureVisible(find.text('Save product'));
    await tester.tap(find.text('Save product'));
    await phone.settle(tester);

    final rice = (await ProductDao(phone.db).find('rice'))!;
    expect(rice.sellingPrice, 58);
    expect(
      rice.unitLabel,
      'kg',
      reason: 'used to be reset to "pc" on every edit',
    );
    expect(
      rice.barcode,
      '1234567890128',
      reason: 'used to be wiped on every edit',
    );
  });
}

String? _query(BuildContext context, String key) =>
    GoRouterState.of(context).uri.queryParameters[key];
