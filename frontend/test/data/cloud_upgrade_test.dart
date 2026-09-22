import 'package:flutter_test/flutter_test.dart';
import 'package:kitaza_app/data/local/dao/session_dao.dart';
import 'package:kitaza_app/data/local/dao/sync_queue_dao.dart';
import 'package:kitaza_app/data/models/expense_category.dart';
import 'package:kitaza_app/data/models/owner_account.dart';
import 'package:kitaza_app/data/models/store_profile.dart';
import 'package:kitaza_app/data/repositories/expense_repository.dart';
import 'package:kitaza_app/data/repositories/product_repository.dart';
import 'package:kitaza_app/data/repositories/sale_repository.dart';

import '../support/in_memory_database.dart';

void main() {
  test('backing up moves every local record under the cloud store', () async {
    final db = await openTestDatabase();
    addTearDown(db.close);

    final product = await ProductRepository(db: db, storeId: testStoreId).save(
      name: 'Coke',
      costPrice: 15,
      sellingPrice: 20,
      stockQuantity: 10,
      reorderLevel: 2,
    );
    await SaleRepository(
      db: db,
      storeId: testStoreId,
    ).record(cart: [CartLine.fromProduct(product, quantity: 2)]);
    await ExpenseRepository(
      db: db,
      storeId: testStoreId,
    ).record(category: ExpenseCategory.utilities, amount: 100);
    final queuedBefore = await SyncQueueDao(db).pendingCount();

    const cloudStore = StoreProfile(id: 'cloud-store', name: 'Test Store');
    await SessionDao(db).adoptCloudStore(
      fromStoreId: testStoreId,
      store: cloudStore,
      owner: const OwnerAccount(id: 'cloud-owner', fullName: 'Owner'),
    );

    for (final table in ['products', 'sales', 'expenses', 'stock_movements']) {
      final stranded = await db.query(
        table,
        where: 'store_id != ?',
        whereArgs: [cloudStore.id],
      );
      expect(stranded, isEmpty, reason: '$table still has local-store rows');
    }

    final stores = await db.query('stores');
    expect(stores.single['id'], cloudStore.id);

    // The whole history is still queued, ready for the first upload - and
    // addressed to the cloud store, not the local one that no longer exists.
    expect(await SyncQueueDao(db).pendingCount(), queuedBefore);
    final queued = await SyncQueueDao(db).pending();
    expect(queued.map((change) => change.storeId).toSet(), {cloudStore.id});
  });
}
