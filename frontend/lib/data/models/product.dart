import '../../core/formatting/centavos.dart';

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.costPrice,
    required this.sellingPrice,
    required this.stockQuantity,
    required this.reorderLevel,
    required this.updatedAt,
    this.barcode,
    this.unitLabel = 'pc',
    this.isActive = true,
  });

  final String id;
  final String name;
  final String? barcode;
  final String unitLabel;
  final double costPrice;
  final double sellingPrice;
  final double stockQuantity;
  final double reorderLevel;
  final bool isActive;
  final DateTime updatedAt;

  double get marginPerUnit => sellingPrice - costPrice;

  double get marginPercent =>
      sellingPrice <= 0 ? 0 : (marginPerUnit / sellingPrice) * 100;

  bool get isLowOnStock => reorderLevel > 0 && stockQuantity <= reorderLevel;

  bool get isOutOfStock => stockQuantity <= 0;

  Product copyWith({double? stockQuantity}) => Product(
    id: id,
    name: name,
    barcode: barcode,
    unitLabel: unitLabel,
    costPrice: costPrice,
    sellingPrice: sellingPrice,
    stockQuantity: stockQuantity ?? this.stockQuantity,
    reorderLevel: reorderLevel,
    isActive: isActive,
    updatedAt: updatedAt,
  );

  Map<String, Object?> toRow() => {
    'id': id,
    'name': name,
    'barcode': barcode,
    'unit_label': unitLabel,
    'cost_price': Centavos.fromPesos(costPrice),
    'selling_price': Centavos.fromPesos(sellingPrice),
    'stock_quantity': stockQuantity,
    'reorder_level': reorderLevel,
    'is_active': isActive ? 1 : 0,
    'updated_at': updatedAt.toUtc().toIso8601String(),
  };

  factory Product.fromRow(Map<String, Object?> row) => Product(
    id: row['id'] as String,
    name: row['name'] as String,
    barcode: row['barcode'] as String?,
    unitLabel: row['unit_label'] as String? ?? 'pc',
    costPrice: Centavos.toPesos(row['cost_price'] as int? ?? 0),
    sellingPrice: Centavos.toPesos(row['selling_price'] as int? ?? 0),
    stockQuantity: readDouble(row['stock_quantity']),
    reorderLevel: readDouble(row['reorder_level']),
    isActive: (row['is_active'] as int? ?? 1) == 1,
    updatedAt: readDate(row['updated_at']),
  );

  /// Shape the API expects when this product is pushed to the cloud.
  Map<String, Object?> toPushJson() => {
    'id': id,
    'name': name,
    'barcode': barcode,
    'unit_label': unitLabel,
    'cost_price': costPrice,
    'selling_price': sellingPrice,
    'opening_stock': stockQuantity,
    'reorder_level': reorderLevel,
  };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'] as String,
    name: json['name'] as String,
    barcode: json['barcode'] as String?,
    unitLabel: json['unit_label'] as String? ?? 'pc',
    costPrice: readDouble(json['cost_price']),
    sellingPrice: readDouble(json['selling_price']),
    stockQuantity: readDouble(json['stock_quantity']),
    reorderLevel: readDouble(json['reorder_level']),
    isActive: json['is_active'] as bool? ?? true,
    updatedAt: readDate(json['updated_at']),
  );
}
