import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../local/dao/product_dao.dart';
import '../local/dao/stock_movement_dao.dart';
import '../local/dao/sync_queue_dao.dart';
import '../models/product.dart';
import '../models/stock_movement.dart';
import 'store_scope.dart';

/// Local-first: the write lands in SQLite immediately and is queued for the
/// cloud separately. The UI never waits on a network call.
///
/// Stock only ever changes through a ledger movement. Editing the count on a
/// product records a counted-total adjustment rather than overwriting the
/// number, so a sale made on another device at the same time is not lost.
class ProductRepository {
  const ProductRepository({required this._db, required this._storeId});

  final Database _db;
  final String _storeId;

  static const Uuid _uuid = Uuid();

  ProductDao get _products => ProductDao(_db);

  Future<List<Product>> search({String? term, bool onlyLowStock = false}) =>
      _products.search(_storeId, term: term, onlyLowStock: onlyLowStock);

  Future<List<Product>> lowStock() =>
      _products.search(_storeId, onlyLowStock: true);

  Future<int> lowStockCount() => _products.lowStockCount(_storeId);

  Future<Product?> find(String productId) => _products.find(productId);

  Future<Product> save({
    String? id,
    required String name,
    required double costPrice,
    required double sellingPrice,
    required double stockQuantity,
    required double reorderLevel,
    String unitLabel = 'pc',
    String? barcode,
  }) async {
    final existing = id == null ? null : await _products.find(id);
    final now = DateTime.now().toUtc();

    final product = Product(
      id: id ?? _uuid.v4(),
      name: name.trim(),
      barcode: barcode?.trim().isEmpty ?? true ? null : barcode!.trim(),
      unitLabel: unitLabel,
      costPrice: costPrice,
      sellingPrice: sellingPrice,
      // The row keeps its current count; the ledger below moves it.
      stockQuantity: existing?.stockQuantity ?? 0,
      reorderLevel: reorderLevel,
      updatedAt: now,
    );

    final movement = switch (existing) {
      null when stockQuantity > 0 => StockMovement(
        id: _uuid.v4(),
        productId: product.id,
        kind: StockMovementKind.stockIn,
        quantity: stockQuantity,
        unitCost: costPrice,
        note: 'Opening stock',
        occurredAt: now,
      ),
      final Product before when before.stockQuantity != stockQuantity =>
        StockMovement(
          id: _uuid.v4(),
          productId: product.id,
          kind: StockMovementKind.adjustment,
          quantity: stockQuantity,
          note: 'Counted',
          occurredAt: now,
        ),
      _ => null,
    };

    await _db.transaction((txn) async {
      await ProductDao(txn).upsert(_storeId, product);
      final queue = SyncQueueDao(txn);
      await queue.enqueue(
        QueuedEntity.products,
        product.id,
        product.toPushJson(),
      );

      if (movement != null) {
        await StockMovementDao(txn).apply(_storeId, movement);
        await queue.enqueue(
          QueuedEntity.stockMovements,
          movement.id,
          movement.toPushJson(),
        );
      }
    });

    return (await _products.find(product.id))!;
  }

  Future<void> receiveStock(
    String productId,
    double quantity, {
    double unitCost = 0,
  }) async {
    final movement = StockMovement(
      id: _uuid.v4(),
      productId: productId,
      kind: StockMovementKind.stockIn,
      quantity: quantity,
      unitCost: unitCost,
      occurredAt: DateTime.now().toUtc(),
    );

    await _db.transaction((txn) async {
      await StockMovementDao(txn).apply(_storeId, movement);
      await SyncQueueDao(txn).enqueue(
        QueuedEntity.stockMovements,
        movement.id,
        movement.toPushJson(),
      );
    });
  }

  Future<void> remove(String productId) async {
    await _db.transaction((txn) async {
      await ProductDao(txn).softDelete(productId);
      await SyncQueueDao(txn).enqueueDeletion(
        DeletedEntity.product,
        QueuedEntity.products,
        productId,
      );
    });
  }
}

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(
    db: ref.watch(databaseProvider),
    storeId: ref.watch(activeStoreIdProvider),
  );
});
