import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitaza_app/data/models/payment_method.dart';
import 'package:kitaza_app/data/models/sale.dart';
import 'package:kitaza_app/data/models/sale_line.dart';
import 'package:kitaza_app/data/repositories/sale_repository.dart';
import 'package:kitaza_app/features/receipts/escpos_encoder.dart';
import 'package:kitaza_app/features/receipts/receipt_layout.dart';
import 'package:kitaza_app/l10n/l10n.dart';

SaleLine _line(String name, double quantity, double price, {double cost = 0}) =>
    SaleLine(
      id: name,
      saleId: 'sale',
      productName: name,
      quantity: quantity,
      unitPrice: price,
      unitCost: cost,
    );

Sale _sale(List<SaleLine> lines, {double discount = 0}) {
  final gross = lines.fold<double>(0, (sum, line) => sum + line.lineTotal);
  return Sale(
    id: '3f9a1c7e-0000-0000-0000-000000000000',
    paymentMethod: PaymentMethod.gcash,
    totalAmount: gross - discount,
    costAmount: 0,
    discountAmount: discount,
    occurredAt: DateTime.utc(2026, 9, 22, 1, 41),
    lines: lines,
  );
}

void main() {
  final english = lookupAppLocalizations(const Locale('en'));
  final filipino = lookupAppLocalizations(const Locale('fil'));

  final busy = _sale([
    _line('Premium Dinorado Rice, 25 kilogram sack (per kilo)', 2.5, 58.5),
    _line('Coke 1.5L', 3, 75),
    _line(CartLine.quickSaleName, 1, 12345.67),
    _line('Supercalifragilisticexpialidocious-sachet-pack', 1, 8),
  ], discount: 20);

  group('the receipt layout', () {
    for (final paper in PaperWidth.values) {
      for (final (language, l10n) in [
        ('English', english),
        ('Filipino', filipino),
      ]) {
        test(
          'never runs past the edge of a ${paper.name} roll in $language',
          () {
            final lines = ReceiptLayout(
              l10n: l10n,
              width: paper,
            ).build(sale: busy, storeName: 'Aling Nena Sari-Sari Store');
            for (final line in lines) {
              expect(
                line.text.length,
                lessThanOrEqualTo(paper.columns),
                reason: '"${line.text}"',
              );
            }
          },
        );
      }
    }

    test('shows every line total, the discount and the total paid', () {
      final text = ReceiptLayout(
        l10n: english,
        width: PaperWidth.mm58,
      ).asText(sale: busy, storeName: 'Store');

      expect(text, contains('146.25'), reason: '2.5 x 58.50');
      expect(text, contains('225.00'), reason: '3 x 75.00');
      expect(text, contains('12,345.67'));
      expect(text, contains('-20.00'));
      expect(
        text,
        contains(
          '₱ ${busy.totalAmount.toStringAsFixed(2).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',')}',
        ),
      );
      expect(text, contains('GCash'));
    });

    test('a keypad sale is named in the reader\'s language', () {
      final text = ReceiptLayout(
        l10n: filipino,
        width: PaperWidth.mm58,
      ).asText(sale: busy, storeName: 'Store');
      expect(text, contains('Mabilisang benta'));
      expect(text, contains('Salamat po!'));
      expect(text, isNot(contains(CartLine.quickSaleName)));
    });

    test('an amount is never cut short to fit', () {
      final lines = ReceiptLayout(
        l10n: english,
        width: PaperWidth.mm58,
      ).build(sale: _sale([_line('x' * 60, 1, 99999.99)]), storeName: 'S');
      expect(lines.any((line) => line.text.endsWith('99,999.99')), isTrue);
    });

    test('the printer version avoids the peso sign, which most printers cannot print', () {
      final lines = ReceiptLayout(
        l10n: english,
        width: PaperWidth.mm58,
        currencySymbol: 'P',
      ).build(sale: busy, storeName: 'Store');
      expect(lines.map((line) => line.text).join(), isNot(contains('₱')));
    });
  });

  group('printer commands', () {
    test('a receipt starts with a reset and ends with a feed and cut', () {
      final bytes = EscPosEncoder.encode(const [ReceiptLine('Hi')]);
      expect(bytes.take(2), EscPosEncoder.reset);
      expect(
        bytes.skip(bytes.length - EscPosEncoder.feedAndCut.length),
        EscPosEncoder.feedAndCut,
      );
    });

    test('styling is sent before each line\'s text', () {
      final bytes = EscPosEncoder.encode(const [
        ReceiptLine(
          'Store',
          align: ReceiptAlign.center,
          bold: true,
          large: true,
        ),
      ]);
      expect(bytes.sublist(2, 11), [
        ...EscPosEncoder.alignCenter,
        ...EscPosEncoder.boldOn,
        ...EscPosEncoder.doubleHeight,
      ]);
      expect(bytes.sublist(11, 17), [
        ...'Store'.codeUnits,
        EscPosEncoder.lineFeed,
      ]);
    });

    test('characters a printer cannot show are spelled out', () {
      expect(
        EscPosEncoder.ascii('Niño · ₱20 × 2 – “sale”'),
        'Nino - P20 x 2 - "sale"',
      );
      expect(EscPosEncoder.ascii('日本'), '??');
    });

    test('nothing outside plain ASCII ever reaches the printer', () {
      final bytes = EscPosEncoder.encode(
        ReceiptLayout(
          l10n: filipino,
          width: PaperWidth.mm58,
          currencySymbol: 'P',
        ).build(sale: busy, storeName: 'Tindahan ni Señora Niña'),
      );
      expect(bytes.every((byte) => byte >= 0 && byte < 0x80), isTrue);
    });
  });
}
