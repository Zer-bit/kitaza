import 'package:flutter_test/flutter_test.dart';
import 'package:kitaza_app/data/local/dao/sync_queue_dao.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../support/in_memory_database.dart';

void main() {
  late Database db;
  late SyncQueueDao queue;

  setUp(() async {
    db = await openTestDatabase();
    queue = SyncQueueDao(db);
  });

  tearDown(() => db.close());

  test('queuing the same entity again keeps only its latest version', () async {
    await queue.enqueue(QueuedEntity.products, 'p1', {
      'name': 'Coke',
    }, storeId: testStoreId);
    await queue.enqueue(QueuedEntity.products, 'p1', {
      'name': 'Coke 290ml',
    }, storeId: testStoreId);

    final pending = await queue.pending();
    expect(pending, hasLength(1));
    expect(pending.single.payload['name'], 'Coke 290ml');
  });

  test('an edit made while a push is in flight survives that push', () async {
    await queue.enqueue(QueuedEntity.products, 'p1', {
      'name': 'Old',
    }, storeId: testStoreId);
    final sent = await queue.pending();

    // The owner edits the product while the old version is being uploaded.
    await queue.enqueue(QueuedEntity.products, 'p1', {
      'name': 'New',
    }, storeId: testStoreId);
    await queue.clearRows(sent.map((change) => change.rowId));

    final remaining = await queue.pending();
    expect(remaining.single.payload['name'], 'New');
  });

  test(
    'a row the server keeps refusing is parked, not retried forever',
    () async {
      await queue.enqueue(QueuedEntity.sales, 's1', {
        'id': 's1',
      }, storeId: testStoreId);
      final rowId = (await queue.pending()).single.rowId;

      for (var i = 0; i < SyncQueueDao.maxAttempts; i++) {
        await queue.recordFailure(rowId, 'product not found');
      }

      expect(await queue.pending(), isEmpty);
      expect(await queue.parkedCount(), 1);
      expect((await queue.problems()).single.lastError, 'product not found');

      await queue.retry(rowId);
      expect(await queue.pending(), hasLength(1));
      expect(await queue.parkedCount(), 0);
    },
  );

  test(
    'deleting something drops its unsent version and queues the removal',
    () async {
      await queue.enqueue(QueuedEntity.sales, 's1', {
        'id': 's1',
      }, storeId: testStoreId);

      await queue.enqueueDeletion(
        DeletedEntity.sale,
        QueuedEntity.sales,
        's1',
        storeId: testStoreId,
      );

      final pending = await queue.pending();
      expect(pending, hasLength(1));
      expect(pending.single.entity, QueuedEntity.deletions);
      expect(pending.single.payload, {'entity': 'sale', 'id': 's1'});
    },
  );

  test('changes are sent in the order they were made', () async {
    await queue.enqueue(QueuedEntity.expenses, 'e1', {}, storeId: testStoreId);
    await queue.enqueue(QueuedEntity.sales, 's1', {}, storeId: testStoreId);
    await queue.enqueue(QueuedEntity.expenses, 'e2', {}, storeId: testStoreId);

    final order = (await queue.pending()).map((change) => change.entityId);
    expect(order, ['e1', 's1', 'e2']);
  });
}
