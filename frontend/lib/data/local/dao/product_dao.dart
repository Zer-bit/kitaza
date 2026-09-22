import 'package:sqflite/sqflite.dart';

import '../../models/product.dart';

class ProductDao {
  const ProductDao(this._db);

  final DatabaseExecutor _db;

  Future<void> upsert(String storeId, Product product) => _db.insert(
    'products',
    {...product.toRow(), 'store_id': storeId},
    conflictAlgorithm: ConflictAlgorithm.replace,
  );

  Future<void> upsertMany(String storeId, List<Product> products) async {
    if (products.isEmpty) return;

    final batch = _db.batch();
    for (final product in products) {
      batch.insert('products', {
        ...product.toRow(),
        'store_id': storeId,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Product>> search(
    String storeId, {
    String? term,
    bool onlyLowStock = false,
    int limit = 200,
  }) async {
    final where = StringBuffer(
      'store_id = ? AND deleted_at IS NULL AND is_active = 1',
    );
    final args = <Object?>[storeId];

    if (term != null && term.trim().isNotEmpty) {
      where.write(' AND (name LIKE ? OR barcode LIKE ?)');
      final pattern = '%${term.trim()}%';
      args
        ..add(pattern)
        ..add(pattern);
    }

    if (onlyLowStock) {
      where.write(' AND reorder_level > 0 AND stock_quantity <= reorder_level');
    }

    final rows = await _db.query(
      'products',
      where: where.toString(),
      whereArgs: args,
      orderBy: 'name COLLATE NOCASE',
      limit: limit,
    );

    return rows.map(Product.fromRow).toList(growable: false);
  }

  Future<Product?> find(String productId) async {
    final rows = await _db.query(
      'products',
      where: 'id = ?',
      whereArgs: [productId],
      limit: 1,
    );
    return rows.isEmpty ? null : Product.fromRow(rows.first);
  }

  /// Exact match only: a scanned code either is a product or is not.
  Future<Product?> findByBarcode(String storeId, String barcode) async {
    final rows = await _db.query(
      'products',
      where: 'store_id = ? AND barcode = ? AND deleted_at IS NULL',
      whereArgs: [storeId, barcode.trim()],
      limit: 1,
    );
    return rows.isEmpty ? null : Product.fromRow(rows.first);
  }

  Future<int> count(String storeId) async {
    final result = await _db.rawQuery(
      'SELECT COUNT(*) AS total FROM products WHERE store_id = ? AND deleted_at IS NULL',
      [storeId],
    );
    return (result.first['total'] as int?) ?? 0;
  }

  Future<int> lowStockCount(String storeId) async {
    final result = await _db.rawQuery(
      '''
      SELECT COUNT(*) AS total FROM products
      WHERE store_id = ? AND deleted_at IS NULL AND is_active = 1
        AND reorder_level > 0 AND stock_quantity <= reorder_level
      ''',
      [storeId],
    );
    return (result.first['total'] as int?) ?? 0;
  }

  Future<void> adjustStock(String productId, double delta) => _db.rawUpdate(
    '''
        UPDATE products
        SET stock_quantity = stock_quantity + ?, updated_at = ?
        WHERE id = ?
        ''',
    [delta, DateTime.now().toUtc().toIso8601String(), productId],
  );

  Future<void> softDelete(String productId) => _db.update(
    'products',
    {
      'deleted_at': DateTime.now().toUtc().toIso8601String(),
      'is_active': 0,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    },
    where: 'id = ?',
    whereArgs: [productId],
  );
}
