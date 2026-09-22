import '../../core/formatting/centavos.dart';
import 'payment_method.dart';
import 'sale_line.dart';

class Sale {
  const Sale({
    required this.id,
    required this.paymentMethod,
    required this.totalAmount,
    required this.costAmount,
    required this.occurredAt,
    this.discountAmount = 0,
    this.note,
    this.lines = const [],
  });

  final String id;
  final PaymentMethod paymentMethod;
  final double totalAmount;
  final double costAmount;
  final double discountAmount;
  final String? note;
  final DateTime occurredAt;
  final List<SaleLine> lines;

  double get profitAmount => totalAmount - costAmount;

  /// A one-line description for history rows: the product when there is only
  /// one, otherwise a count.
  String get summaryLabel => switch (lines.length) {
    0 => 'Sale',
    1 => lines.first.productName,
    final count => '$count items',
  };

  Sale withLines(List<SaleLine> value) => Sale(
    id: id,
    paymentMethod: paymentMethod,
    totalAmount: totalAmount,
    costAmount: costAmount,
    discountAmount: discountAmount,
    note: note,
    occurredAt: occurredAt,
    lines: value,
  );

  Map<String, Object?> toRow() => {
    'id': id,
    'payment_method': paymentMethod.wireName,
    'total_amount': Centavos.fromPesos(totalAmount),
    'cost_amount': Centavos.fromPesos(costAmount),
    'discount_amount': Centavos.fromPesos(discountAmount),
    'note': note,
    'occurred_at': occurredAt.toUtc().toIso8601String(),
    'updated_at': DateTime.now().toUtc().toIso8601String(),
  };

  factory Sale.fromRow(Map<String, Object?> row) => Sale(
    id: row['id'] as String,
    paymentMethod: PaymentMethod.parse(row['payment_method'] as String?),
    totalAmount: Centavos.toPesos(row['total_amount'] as int? ?? 0),
    costAmount: Centavos.toPesos(row['cost_amount'] as int? ?? 0),
    discountAmount: Centavos.toPesos(row['discount_amount'] as int? ?? 0),
    note: row['note'] as String?,
    occurredAt: readDate(row['occurred_at']),
  );

  Map<String, Object?> toPushJson() => {
    'id': id,
    'payment_method': paymentMethod.wireName,
    'discount_amount': discountAmount,
    'note': note,
    'occurred_at': occurredAt.toUtc().toIso8601String(),
    'items': lines.map((line) => line.toPushJson()).toList(),
  };
}
