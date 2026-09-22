import '../../core/formatting/centavos.dart';

/// Translates a server row into a local row.
///
/// The two schemas are deliberately close but not identical: the server keeps
/// money as `NUMERIC` and sends it as a decimal number, while SQLite stores
/// integer centavos. Every conversion between them happens here.
abstract final class SyncRowMapper {
  static Map<String, Object?> product(
    Map<String, dynamic> row,
    String storeId,
  ) => {
    'id': row['id'],
    'store_id': storeId,
    'name': row['name'],
    'barcode': row['barcode'],
    'unit_label': row['unit_label'] ?? 'pc',
    'cost_price': Centavos.fromJson(row['cost_price']),
    'selling_price': Centavos.fromJson(row['selling_price']),
    'stock_quantity': readDouble(row['stock_quantity']),
    'reorder_level': readDouble(row['reorder_level']),
    'is_active': (row['is_active'] as bool? ?? true) ? 1 : 0,
    'updated_at': row['updated_at'],
    'deleted_at': row['deleted_at'],
  };

  static Map<String, Object?> sale(Map<String, dynamic> row, String storeId) =>
      {
        'id': row['id'],
        'store_id': storeId,
        'payment_method': row['payment_method'] ?? 'cash',
        'total_amount': Centavos.fromJson(row['total_amount']),
        'cost_amount': Centavos.fromJson(row['cost_amount']),
        'discount_amount': Centavos.fromJson(row['discount_amount']),
        'note': row['note'],
        'occurred_at': row['occurred_at'],
        'updated_at': row['updated_at'],
        'deleted_at': row['deleted_at'],
      };

  static Map<String, Object?> saleItem(Map<String, dynamic> row) => {
    'id': row['id'],
    'sale_id': row['sale_id'],
    'product_id': row['product_id'],
    'product_name': row['product_name'],
    'quantity': readDouble(row['quantity']),
    'unit_price': Centavos.fromJson(row['unit_price']),
    'unit_cost': Centavos.fromJson(row['unit_cost']),
    'line_total': Centavos.fromJson(row['line_total']),
  };

  static Map<String, Object?> expense(
    Map<String, dynamic> row,
    String storeId,
  ) => {
    'id': row['id'],
    'store_id': storeId,
    'category': row['category'],
    'description': row['description'],
    'amount': Centavos.fromJson(row['amount']),
    'occurred_at': row['occurred_at'],
    'updated_at': row['updated_at'],
    'deleted_at': row['deleted_at'],
  };

  static Map<String, Object?> withdrawal(
    Map<String, dynamic> row,
    String storeId,
  ) => {
    'id': row['id'],
    'store_id': storeId,
    'amount': Centavos.fromJson(row['amount']),
    'reason': row['reason'],
    'occurred_at': row['occurred_at'],
    'updated_at': row['updated_at'],
    'deleted_at': row['deleted_at'],
  };

  static Map<String, Object?> stockMovement(
    Map<String, dynamic> row,
    String storeId,
  ) => {
    'id': row['id'],
    'store_id': storeId,
    'product_id': row['product_id'],
    'movement': row['movement'],
    'quantity': readDouble(row['quantity']),
    'unit_cost': Centavos.fromJson(row['unit_cost']),
    'note': row['note'],
    'occurred_at': row['occurred_at'],
    'updated_at': row['updated_at'],
    'deleted_at': row['deleted_at'],
  };
}
