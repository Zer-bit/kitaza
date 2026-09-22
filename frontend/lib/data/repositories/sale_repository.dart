import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../local/dao/sale_dao.dart';
import '../local/dao/sync_queue_dao.dart';
import '../models/payment_method.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../models/sale_line.dart';
import 'store_scope.dart';

/// A line the cashier has added but not yet charged.
class CartLine {
  const CartLine({
    required this.key,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.unitCost,
    this.productId,
  });

  final String key;
  final String? productId;
  final String productName;
  final double quantity;
  final double unitPrice;
  final double unitCost;

  double get total => unitPrice * quantity;

  CartLine copyWith({double? quantity}) => CartLine(
    key: key,
    productId: productId,
    productName: productName,
    quantity: quantity ?? this.quantity,
    unitPrice: unitPrice,
    unitCost: unitCost,
  );

  factory CartLine.fromProduct(Product product, {double quantity = 1}) =>
      CartLine(
        key: product.id,
        productId: product.id,
        productName: product.name,
        quantity: quantity,
        unitPrice: product.sellingPrice,
        unitCost: product.costPrice,
      );

  /// A sale typed straight into the keypad, with no catalogue entry behind it.
  /// This is how most sari-sari sales get recorded in under five seconds.
  factory CartLine.quick(double amount, {String label = 'Quick sale'}) =>
      CartLine(
        key: 'quick-${DateTime.now().microsecondsSinceEpoch}',
        productName: label,
        quantity: 1,
        unitPrice: amount,
        unitCost: 0,
      );
}

class SaleRepository {
  const SaleRepository({required this._db, required this._storeId});

  final Database _db;
  final String _storeId;

  static const Uuid _uuid = Uuid();

  Future<List<Sale>> history({
    DateTime? from,
    DateTime? to,
    int limit = 50,
    int offset = 0,
  }) async {
    final dao = SaleDao(_db);
    final sales = await dao.recent(
      _storeId,
      from: from,
      to: to,
      limit: limit,
      offset: offset,
    );

    final grouped = await dao.linesForAll(
      sales.map((sale) => sale.id).toList(growable: false),
    );

    return sales
        .map((sale) => sale.withLines(grouped[sale.id] ?? const []))
        .toList(growable: false);
  }

  /// The sale, its lines, the stock deduction and the sync entry are written
  /// in one transaction. Nothing here can half-succeed.
  Future<Sale> record({
    required List<CartLine> cart,
    PaymentMethod paymentMethod = PaymentMethod.cash,
    double discount = 0,
    String? note,
    DateTime? occurredAt,
  }) async {
    final saleId = _uuid.v4();
    final gross = cart.fold<double>(0, (sum, line) => sum + line.total);
    final cost = cart.fold<double>(
      0,
      (sum, line) => sum + line.unitCost * line.quantity,
    );
    final appliedDiscount = discount.clamp(0, gross).toDouble();

    final sale = Sale(
      id: saleId,
      paymentMethod: paymentMethod,
      totalAmount: gross - appliedDiscount,
      costAmount: cost,
      discountAmount: appliedDiscount,
      note: note,
      occurredAt: occurredAt ?? DateTime.now().toUtc(),
      lines: cart
          .map(
            (line) => SaleLine(
              id: _uuid.v4(),
              saleId: saleId,
              productId: line.productId,
              productName: line.productName,
              quantity: line.quantity,
              unitPrice: line.unitPrice,
              unitCost: line.unitCost,
            ),
          )
          .toList(growable: false),
    );

    await _db.transaction((txn) async {
      await SaleDao(txn).insert(_storeId, sale);
      await SyncQueueDao(txn)
          .enqueue(QueuedEntity.sales, sale.id, sale.toPushJson());
    });

    return sale;
  }

  Future<void> voidSale(String saleId) async {
    await _db.transaction((txn) async {
      await SaleDao(txn).voidSale(saleId);
      await SyncQueueDao(txn)
          .enqueueDeletion(DeletedEntity.sale, QueuedEntity.sales, saleId);
    });
  }
}

final saleRepositoryProvider = Provider<SaleRepository>((ref) {
  return SaleRepository(
    db: ref.watch(databaseProvider),
    storeId: ref.watch(activeStoreIdProvider),
  );
});
