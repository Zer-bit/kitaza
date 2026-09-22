import '../../core/formatting/centavos.dart';

/// Why stock changed. Sales move stock too, but through the sale itself.
enum StockMovementKind {
  stockIn('stock_in'),
  stockOut('stock_out'),

  /// The owner physically counted the shelf. Carries the counted total, not a
  /// difference, so it stays correct however many sales arrive around it.
  adjustment('adjustment'),
  spoilage('spoilage');

  const StockMovementKind(this.wireName);

  final String wireName;
}

/// One line of the stock ledger. Stock is always the sum of the ledger and
/// the sales, never a number overwritten in place - which is what lets two
/// devices change the same product's stock without losing each other's work.
class StockMovement {
  const StockMovement({
    required this.id,
    required this.productId,
    required this.kind,
    required this.quantity,
    required this.occurredAt,
    this.unitCost = 0,
    this.note,
  });

  final String id;
  final String productId;
  final StockMovementKind kind;

  /// An amount for in and out, the counted total for an adjustment.
  final double quantity;
  final double unitCost;
  final String? note;
  final DateTime occurredAt;

  Map<String, Object?> toRow(String storeId, {required double appliedDelta}) =>
      {
        'id': id,
        'store_id': storeId,
        'product_id': productId,
        'movement': kind.wireName,
        // The ledger stores the signed change, matching the server's table.
        'quantity': appliedDelta,
        'unit_cost': Centavos.fromPesos(unitCost),
        'note': note,
        'occurred_at': occurredAt.toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

  Map<String, Object?> toPushJson() => {
    'id': id,
    'product_id': productId,
    'movement': kind.wireName,
    'quantity': quantity,
    'unit_cost': unitCost,
    'note': note,
    'occurred_at': occurredAt.toUtc().toIso8601String(),
  };
}
