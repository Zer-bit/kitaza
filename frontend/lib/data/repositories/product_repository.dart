import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../local/dao/product_dao.dart';
import '../local/dao/sync_queue_dao.dart';
import '../models/product.dart';
import 'store_scope.dart';

/// Local-first: the write lands in SQLite immediately and is queued for the
/// cloud separately. The UI never waits on a network call.
class ProductRepository {
  const ProductRepository({
    required this._products,
    required this._queue,
    required this._storeId,
  });

  final ProductDao _products;
  final SyncQueueDao _queue;
  final String _storeId;

  static const Uuid _uuid = Uuid();

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
    final product = Product(
      id: id ?? _uuid.v4(),
      name: name.trim(),
      barcode: barcode?.trim().isEmpty ?? true ? null : barcode!.trim(),
      unitLabel: unitLabel,
      costPrice: costPrice,
      sellingPrice: sellingPrice,
      stockQuantity: stockQuantity,
      reorderLevel: reorderLevel,
      updatedAt: DateTime.now().toUtc(),
    );

    await _products.upsert(_storeId, product);
    await _queue.enqueue('products', product.id, product.toPushJson());

    return product;
  }

  Future<void> receiveStock(String productId, double quantity) async {
    await _products.adjustStock(productId, quantity);

    final product = await _products.find(productId);
    if (product != null) {
      await _queue.enqueue('products', product.id, product.toPushJson());
    }
  }

  Future<void> remove(String productId) async {
    await _products.softDelete(productId);
    await _queue.clearAccepted([productId]);
  }
}

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return ProductRepository(
    products: ProductDao(db),
    queue: SyncQueueDao(db),
    storeId: ref.watch(activeStoreIdProvider),
  );
});
