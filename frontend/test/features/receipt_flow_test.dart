import 'package:flutter_test/flutter_test.dart';
import 'package:kitaza_app/app/route_paths.dart';
import 'package:kitaza_app/data/repositories/sale_repository.dart';
import 'package:kitaza_app/features/receipts/escpos_encoder.dart';
import 'package:kitaza_app/features/receipts/receipt_printer.dart';
import 'package:kitaza_app/features/sales/sale_history_screen.dart';
import 'package:kitaza_app/features/settings/settings_screen.dart';

import '../support/app_harness.dart';
import '../support/in_memory_database.dart';

/// A printer on the desk that records what it was sent.
class _FakePrinter extends ReceiptPrinter {
  _FakePrinter({this.outcome = PrintOutcome.printed});

  final PrintOutcome outcome;
  final List<List<int>> printed = [];

  @override
  Future<List<PrinterDevice>> pairedPrinters() async => const [
    PrinterDevice(name: 'Xprinter XP-58', address: '66:02:BD:06:18:7B'),
  ];

  @override
  Future<PrintOutcome> printBytes(String address, List<int> bytes) async {
    printed.add(bytes);
    return outcome;
  }
}

void main() {
  Future<TestPhone> openHistory(
    WidgetTester tester,
    _FakePrinter printer, {
    bool withPrinter = true,
  }) async {
    final phone = await TestPhone.open(
      tester,
      screens: {RoutePaths.saleHistory: (_) => const SaleHistoryScreen()},
      overrides: (db, _) => [receiptPrinterProvider.overrideWithValue(printer)],
    );
    if (withPrinter) {
      final prefs = phone.container.read(printerSettingsProvider.notifier);
      await prefs.choose(
        const PrinterDevice(
          name: 'Xprinter XP-58',
          address: '66:02:BD:06:18:7B',
        ),
      );
    }
    await SaleRepository(
      db: phone.db,
      storeId: testStoreId,
    ).record(cart: [CartLine.quick(45), CartLine.quick(20)]);
    await phone.goTo(tester, RoutePaths.saleHistory);
    await tester.tap(find.text('2 items'));
    await phone.settle(tester);
    return phone;
  }

  testWidgets('tapping a sale shows its receipt', (tester) async {
    await openHistory(tester, _FakePrinter());

    expect(find.text('Receipt'), findsOneWidget);
    expect(find.textContaining('Quick sale'), findsOneWidget);
    expect(find.textContaining('₱ 65.00'), findsOneWidget);
    expect(find.textContaining('Thank you!'), findsOneWidget);
  });

  testWidgets('printing sends the receipt to the chosen printer', (
    tester,
  ) async {
    final printer = _FakePrinter();
    await openHistory(tester, printer);

    await tester.tap(find.text('Print'));
    await tester.pumpAndSettle();

    expect(find.text('Receipt printed.'), findsOneWidget);
    final bytes = printer.printed.single;
    expect(bytes.take(2), EscPosEncoder.reset);
    expect(
      String.fromCharCodes(bytes.where((b) => b >= 0x20 && b < 0x7F)),
      contains('P 65.00'),
    );
  });

  testWidgets('with no printer set up, the owner is told where to set one', (
    tester,
  ) async {
    final printer = _FakePrinter();
    await openHistory(tester, printer, withPrinter: false);

    await tester.tap(find.text('Print'));
    await tester.pumpAndSettle();

    expect(
      find.text('No receipt printer yet. Set one up in Settings.'),
      findsOneWidget,
    );
    expect(printer.printed, isEmpty);
  });

  for (final (outcome, message) in [
    (PrintOutcome.bluetoothOff, 'Bluetooth is off. Turn it on and try again.'),
    (
      PrintOutcome.couldNotConnect,
      'Could not connect to the printer. Check that it is on and nearby.',
    ),
  ]) {
    testWidgets('a ${outcome.name} failure is explained plainly', (
      tester,
    ) async {
      await openHistory(tester, _FakePrinter(outcome: outcome));

      await tester.tap(find.text('Print'));
      await tester.pumpAndSettle();

      expect(find.text(message), findsOneWidget);
    });
  }

  testWidgets('a paired printer is chosen in Settings and remembered', (
    tester,
  ) async {
    final phone = await TestPhone.open(
      tester,
      screens: {RoutePaths.settings: (_) => const SettingsScreen()},
      overrides: (_, _) => [
        receiptPrinterProvider.overrideWithValue(_FakePrinter()),
      ],
    );
    await phone.goTo(tester, RoutePaths.settings);

    await phone.tapAfterScrolling(tester, find.text('None chosen'));
    await tester.tap(find.text('Xprinter XP-58'));
    await tester.pumpAndSettle();

    expect(find.text('Xprinter XP-58'), findsOneWidget);
    expect(
      phone.container.read(printerSettingsProvider).address,
      '66:02:BD:06:18:7B',
    );
  });
}
