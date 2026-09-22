import '../../core/formatting/centavos.dart';

class SaleLine {
  const SaleLine({
    required this.id,
    required this.saleId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.unitCost,
    this.productId,
  });

  final String id;
  final String saleId;
  final String? productId;
  final String productName;
  final double quantity;
  final double unitPrice;
  final double unitCost;

  double get lineTotal => unitPrice * quantity;
  double get lineProfit => (unitPrice - unitCost) * quantity;

  SaleLine withQuantity(double value) => SaleLine(
    id: id,
    saleId: saleId,
    productId: productId,
    productName: productName,
    quantity: value,
    unitPrice: unitPrice,
    unitCost: unitCost,
  );

  Map<String, Object?> toRow() => {
    'id': id,
    'sale_id': saleId,
    'product_id': productId,
    'product_name': productName,
    'quantity': quantity,
    'unit_price': Centavos.fromPesos(unitPrice),
    'unit_cost': Centavos.fromPesos(unitCost),
    'line_total': Centavos.fromPesos(lineTotal),
  };

  factory SaleLine.fromRow(Map<String, Object?> row) => SaleLine(
    id: row['id'] as String,
    saleId: row['sale_id'] as String,
    productId: row['product_id'] as String?,
    productName: row['product_name'] as String,
    quantity: readDouble(row['quantity']),
    unitPrice: Centavos.toPesos(row['unit_price'] as int? ?? 0),
    unitCost: Centavos.toPesos(row['unit_cost'] as int? ?? 0),
  );

  Map<String, Object?> toPushJson() => {
    'id': id,
    'product_id': productId,
    'product_name': productName,
    'quantity': quantity,
    'unit_price': unitPrice,
    'unit_cost': unitCost,
  };
}
