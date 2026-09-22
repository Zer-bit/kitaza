import 'package:flutter_test/flutter_test.dart';
import 'package:kitaza_app/data/local/dao/sync_queue_dao.dart';
import 'package:kitaza_app/data/repositories/product_repository.dart';
import 'package:kitaza_app/data/repositories/sale_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../support/in_memory_database.dart';

void main() {
  late Database db;
  late ProductRepository products;
  late SyncQueueDao queue;

  setUp(() async {
    db = await openTestDatabase();
    products = ProductRepository(db: db, storeId: testStoreId);
    queue = SyncQueueDao(db);
  });

  tearDown(() => db.close());

  Future<List<QueuedChange>> queued(String entity) async =>
      (await queue.pending())
          .where((change) => change.entity == entity)
          .toList();

  test('opening stock travels as a stock-in, never on the product', () async {
    final product = await products.save(
      name: 'Coke',
      costPrice: 15,
      sellingPrice: 20,
      stockQuantity: 24,
      reorderLevel: 6,
    );

    expect(product.stockQuantity, 24);
    expect(
      (await queued(QueuedEntity.products)).single.payload['opening_stock'],
      0,
    );

    final movement = (await queued(QueuedEntity.stockMovements)).single.payload;
    expect(movement['movement'], 'stock_in');
    expect(movement['quantity'], 24);
  });

  test(
    'correcting the count records what was counted, not the difference',
    () async {
      final product = await products.save(
        name: 'Rice',
        costPrice: 40,
        sellingPrice: 55,
        stockQuantity: 10,
        reorderLevel: 2,
      );
      await SaleRepository(
        db: db,
        storeId: testStoreId,
      ).record(cart: [CartLine.fromProduct(product, quantity: 3)]);

      // Seven on record; the owner counts five on the shelf.
      final corrected = await products.save(
        id: product.id,
        name: 'Rice',
        costPrice: 40,
        sellingPrice: 55,
        stockQuantity: 5,
        reorderLevel: 2,
      );

      expect(corrected.stockQuantity, 5);
      final adjustments = (await queued(QueuedEntity.stockMovements))
          .where((change) => change.payload['movement'] == 'adjustment');
      expect(adjustments.single.payload['quantity'], 5);
    },
  );

  test('changing only the price moves no stock', () async {
    final product = await products.save(
      name: 'Bread',
      costPrice: 5,
      sellingPrice: 8,
      stockQuantity: 12,
      reorderLevel: 3,
    );
    final before = (await queued(QueuedEntity.stockMovements)).length;

    await products.save(
      id: product.id,
      name: 'Bread',
      costPrice: 5,
      sellingPrice: 9,
      stockQuantity: 12,
      reorderLevel: 3,
    );

    expect((await queued(QueuedEntity.stockMovements)).length, before);
    expect((await products.find(product.id))!.stockQuantity, 12);
  });

  test('receiving stock adds to the count and queues the delivery', () async {
    final product = await products.save(
      name: 'Eggs',
      costPrice: 7,
      sellingPrice: 9,
      stockQuantity: 0,
      reorderLevel: 6,
    );

    await products.receiveStock(product.id, 30, unitCost: 7);

    expect((await products.find(product.id))!.stockQuantity, 30);
    expect(await queued(QueuedEntity.stockMovements), hasLength(1));
  });

  test('removing a product queues its removal for the cloud', () async {
    final product = await products.save(
      name: 'Candy',
      costPrice: 1,
      sellingPrice: 2,
      stockQuantity: 0,
      reorderLevel: 0,
    );

    await products.remove(product.id);

    expect(await queued(QueuedEntity.products), isEmpty);
    expect((await queued(QueuedEntity.deletions)).single.payload, {
      'entity': 'product',
      'id': product.id,
    });
  });

  test('voiding a sale queues the void', () async {
    final sales = SaleRepository(db: db, storeId: testStoreId);
    final sale = await sales.record(cart: [CartLine.quick(50)]);

    await sales.voidSale(sale.id);

    expect(await queued(QueuedEntity.sales), isEmpty);
    expect(
      (await queued(QueuedEntity.deletions)).single.payload['entity'],
      'sale',
    );
  });

  test('sale lines are sent with the ids the device gave them', () async {
    final sale = await SaleRepository(
      db: db,
      storeId: testStoreId,
    ).record(cart: [CartLine.quick(20), CartLine.quick(30)]);

    final items =
        (await queued(QueuedEntity.sales)).single.payload['items'] as List;
    expect(
      items.map((item) => (item as Map)['id']),
      sale.lines.map((line) => line.id),
    );
  });
}
