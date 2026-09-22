import '../../core/formatting/day_formatter.dart';
import '../../core/formatting/peso_formatter.dart';
import '../../core/formatting/quantity_formatter.dart';
import '../../data/models/sale.dart';
import '../../l10n/l10n.dart';

enum ReceiptAlign { left, center }

/// One printed line, with the little styling a thermal printer can do.
class ReceiptLine {
  const ReceiptLine(
    this.text, {
    this.align = ReceiptAlign.left,
    this.bold = false,
    this.large = false,
  });

  final String text;
  final ReceiptAlign align;
  final bool bold;

  /// Double height only: double width would break the column arithmetic.
  final bool large;
}

/// Paper widths in characters for the two common thermal rolls.
enum PaperWidth {
  mm58(32),
  mm80(48);

  const PaperWidth(this.columns);

  final int columns;

  static PaperWidth parse(String? raw) => raw == 'mm80' ? mm80 : mm58;
}

/// Lays a sale out as fixed-width lines. Text sharing and the printer both
/// start from this, so a shared receipt and a printed one always match.
class ReceiptLayout {
  const ReceiptLayout({
    required this.l10n,
    required this.width,
    this.currencySymbol = '₱',
  });

  final AppLocalizations l10n;
  final PaperWidth width;

  /// Most cheap thermal printers have no ₱ in their character set and print
  /// garbage for it, so the printer path passes "P" here.
  final String currencySymbol;

  int get _columns => width.columns;

  List<ReceiptLine> build({required Sale sale, required String storeName}) {
    final lines = <ReceiptLine>[
      ReceiptLine(
        storeName,
        align: ReceiptAlign.center,
        bold: true,
        large: true,
      ),
      ReceiptLine(
        '${DayFormatter.dayMonth(sale.occurredAt)} ${sale.occurredAt.toLocal().year}, '
        '${DayFormatter.timeOfDay(sale.occurredAt)}',
        align: ReceiptAlign.center,
      ),
      ReceiptLine(
        l10n.receiptReference(sale.id.substring(0, 6).toUpperCase()),
        align: ReceiptAlign.center,
      ),
      ReceiptLine('-' * _columns),
    ];

    for (final line in sale.lines) {
      lines.addAll(
        _item(
          name: l10n.displayProductName(line.productName),
          quantity: line.quantity,
          unitPrice: line.unitPrice,
          total: line.lineTotal,
        ),
      );
    }

    final gross = sale.totalAmount + sale.discountAmount;
    lines.add(ReceiptLine('-' * _columns));
    if (sale.discountAmount > 0) {
      lines
        ..add(ReceiptLine(_pair(l10n.receiptSubtotal, _amount(gross))))
        ..add(
          ReceiptLine(
            _pair(l10n.receiptDiscount, '-${_amount(sale.discountAmount)}'),
          ),
        );
    }
    lines
      ..add(
        ReceiptLine(
          _pair(
            l10n.receiptTotal,
            '$currencySymbol ${_amount(sale.totalAmount)}',
          ),
          bold: true,
        ),
      )
      ..add(
        ReceiptLine(
          _pair(l10n.receiptPaidBy, l10n.paymentMethod(sale.paymentMethod)),
        ),
      )
      ..add(ReceiptLine('-' * _columns))
      ..add(ReceiptLine(l10n.receiptThanks, align: ReceiptAlign.center));

    return lines;
  }

  /// A receipt as one block of text, for sharing.
  String asText({required Sale sale, required String storeName}) =>
      build(sale: sale, storeName: storeName)
          .map(
            (line) => line.align == ReceiptAlign.center
                ? _center(line.text)
                : line.text,
          )
          .join('\n');

  List<ReceiptLine> _item({
    required String name,
    required double quantity,
    required double unitPrice,
    required double total,
  }) {
    final amount = _amount(total);

    if (quantity == 1) {
      final wrapped = _wrap(name, _columns);
      final last = wrapped.removeLast();
      // The total sits on the name's last line when it fits.
      if (last.length + 1 + amount.length <= _columns) {
        return [
          ...wrapped.map(ReceiptLine.new),
          ReceiptLine(_pair(last, amount)),
        ];
      }
      return [
        ...wrapped.map(ReceiptLine.new),
        ReceiptLine(last),
        ReceiptLine(_pair('', amount)),
      ];
    }

    return [
      ..._wrap(
        '${QuantityFormatter.exact(quantity)} x $name',
        _columns,
      ).map(ReceiptLine.new),
      ReceiptLine(_pair('   @ ${_amount(unitPrice)}', amount)),
    ];
  }

  String _amount(double value) => PesoFormatter.plain(value);

  /// Label on the left, value flush right.
  String _pair(String left, String right) {
    final space = _columns - left.length - right.length;
    if (space >= 1) return '$left${' ' * space}$right';
    // Too long for one line: the label is shortened, never the amount.
    final room = _columns - right.length - 1;
    return '${left.substring(0, room.clamp(0, left.length))} $right';
  }

  String _center(String text) {
    if (text.length >= _columns) return text;
    return '${' ' * ((_columns - text.length) ~/ 2)}$text';
  }

  static List<String> _wrap(String text, int width) {
    final lines = <String>[];
    var current = '';
    for (final word in text.split(RegExp(r'\s+'))) {
      if (word.isEmpty) continue;
      var piece = word;
      // A single word longer than the paper is broken hard.
      while (piece.length > width) {
        if (current.isNotEmpty) {
          lines.add(current);
          current = '';
        }
        lines.add(piece.substring(0, width));
        piece = piece.substring(width);
      }
      if (current.isEmpty) {
        current = piece;
      } else if (current.length + 1 + piece.length <= width) {
        current = '$current $piece';
      } else {
        lines.add(current);
        current = piece;
      }
    }
    if (current.isNotEmpty || lines.isEmpty) lines.add(current);
    return lines;
  }
}
