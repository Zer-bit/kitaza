import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitaza_app/core/errors/app_failure.dart';
import 'package:kitaza_app/core/storage/preferences_store.dart';
import 'package:kitaza_app/data/local/dao/sync_queue_dao.dart';
import 'package:kitaza_app/data/remote/sync_api.dart';
import 'package:kitaza_app/data/repositories/data_revision.dart';
import 'package:kitaza_app/data/repositories/store_scope.dart';
import 'package:kitaza_app/data/repositories/sync_coordinator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../support/in_memory_database.dart';

/// Stands in for the server. Tests script what it accepts and returns.
class FakeSyncApi implements SyncApi {
  final List<Map<String, List<Map<String, Object?>>>> pushes = [];
  final List<String?> pullCursors = [];
  final List<PullPage> pages = [];
  Set<String> refuse = {};
  Object? failWith;
  Future<void> Function()? duringPush;

  @override
  Future<PushResult> push(
    String storeId,
    Map<String, List<Map<String, Object?>>> batch,
  ) async {
    if (failWith case final error?) throw error;
    pushes.add(batch);
    await duringPush?.call();

    final applied = <QueueKey>{};
    final rejected = <QueueKey, String>{};
    batch.forEach((entity, rows) {
      for (final row in rows) {
        final key = (entity: entity, id: row['id'] as String);
        if (refuse.contains(key.id)) {
          rejected[key] = 'product not found';
        } else {
          applied.add(key);
        }
      }
    });
    return PushResult(applied: applied, rejected: rejected);
  }

  @override
  Future<PullPage> pull(String storeId, String? cursor) async {
    if (failWith case final error?) throw error;
    pullCursors.add(cursor);
    if (pages.isEmpty) {
      return const PullPage(
        tables: _emptyTables,
        cursor: 'done',
        hasMore: false,
      );
    }
    return pages.removeAt(0);
  }
}

const _emptyTables = <String, List<Map<String, dynamic>>>{
  'products': [],
  'sales': [],
  'sale_items': [],
  'expenses': [],
  'withdrawals': [],
  'stock_movements': [],
};

PullPage page(
  Map<String, List<Map<String, dynamic>>> rows, {
  required String cursor,
  bool hasMore = false,
}) {
  return PullPage(
    tables: {..._emptyTables, ...rows},
    cursor: cursor,
    hasMore: hasMore,
  );
}

void main() {
  late Database db;
  late FakeSyncApi api;
  late ProviderContainer container;

  Future<ProviderContainer> start({String mode = 'cloud'}) async {
    SharedPreferences.setMockInitialValues({
      'kitaza.storage_mode': mode,
      'kitaza.active_store_id': testStoreId,
    });
    final preferences = PreferencesStore(await SharedPreferences.getInstance());

    final created = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        preferencesStoreProvider.overrideWithValue(preferences),
        syncApiProvider.overrideWithValue(api),
        connectivityChangesProvider.overrideWithValue(const Stream.empty()),
      ],
    );
    addTearDown(created.dispose);
    return created;
  }

  /// Lets the sync the coordinator starts on its own run to completion.
  Future<void> settle() async {
    await Future<void>.delayed(Duration.zero);
    for (var i = 0; i < 200; i++) {
      if (container.read(syncCoordinatorProvider).phase != SyncPhase.syncing) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
        if (container.read(syncCoordinatorProvider).phase !=
            SyncPhase.syncing) {
          return;
        }
      }
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
  }

  setUp(() async {
    db = await openTestDatabase();
    api = FakeSyncApi();
  });

  tearDown(() => db.close());

  test('queued changes are uploaded and cleared once accepted', () async {
    final queue = SyncQueueDao(db);
    await queue.enqueue(QueuedEntity.expenses, 'e1', {
      'id': 'e1',
      'amount': 10,
    });
    await queue.enqueue(QueuedEntity.sales, 's1', {'id': 's1', 'items': []});

    container = await start();
    container.read(syncCoordinatorProvider);
    await settle();

    expect(api.pushes.single[QueuedEntity.expenses], hasLength(1));
    expect(api.pushes.single[QueuedEntity.sales], hasLength(1));
    expect(await queue.pendingCount(), 0);
    expect(container.read(syncCoordinatorProvider).phase, SyncPhase.idle);
  });

  test('a refused row is kept with its reason, the rest are cleared', () async {
    final queue = SyncQueueDao(db);
    await queue.enqueue(QueuedEntity.sales, 'bad', {'id': 'bad'});
    await queue.enqueue(QueuedEntity.expenses, 'good', {'id': 'good'});
    api.refuse = {'bad'};

    container = await start();
    container.read(syncCoordinatorProvider);
    await settle();

    final problems = await queue.problems();
    expect(problems.single.entityId, 'bad');
    expect(problems.single.lastError, 'product not found');
    expect(await queue.pendingCount(), 1);
  });

  test('an entry written during an upload is not lost', () async {
    final queue = SyncQueueDao(db);
    await queue.enqueue(QueuedEntity.products, 'p1', {
      'id': 'p1',
      'name': 'Old',
    });

    api.duringPush = () async {
      api.duringPush = null;
      await queue.enqueue(QueuedEntity.products, 'p1', {
        'id': 'p1',
        'name': 'New',
      });
    };

    container = await start();
    container.read(syncCoordinatorProvider);
    await settle();

    // The edit went up in a second push rather than being cleared unsent.
    expect(api.pushes, hasLength(2));
    expect(api.pushes.last[QueuedEntity.products]!.single['name'], 'New');
    expect(await queue.pendingCount(), 0);
  });

  test('pulls page after page until the server has nothing more', () async {
    api.pages.addAll([
      page(
        {
          'expenses': [_expense('e1')],
        },
        cursor: 'c1',
        hasMore: true,
      ),
      page(
        {
          'expenses': [_expense('e2')],
        },
        cursor: 'c2',
        hasMore: true,
      ),
      page({
        'expenses': [_expense('e3')],
      }, cursor: 'c3'),
    ]);

    container = await start();
    final revisionBefore = container.read(dataRevisionProvider);
    container.read(syncCoordinatorProvider);
    await settle();

    expect(api.pullCursors, [null, 'c1', 'c2']);
    expect(await db.query('expenses'), hasLength(3));
    expect(container.read(preferencesStoreProvider).readSyncCursor(), 'c3');
    expect(
      container.read(dataRevisionProvider),
      greaterThan(revisionBefore),
      reason: 'screens must refresh after a pull',
    );
  });

  test('a pulled sale replaces its lines instead of adding to them', () async {
    await db.insert('sales', {
      'id': 's1',
      'store_id': testStoreId,
      'occurred_at': '2026-09-22T00:00:00Z',
      'updated_at': '2026-09-22T00:00:00Z',
    });
    await db.insert('sale_items', {
      'id': 'stale-line',
      'sale_id': 's1',
      'product_name': 'Old line',
      'quantity': 1,
      'unit_price': 100,
      'line_total': 100,
    });

    api.pages.add(
      page({
        'sales': [_sale('s1')],
        'sale_items': [_line('fresh-line', 's1')],
      }, cursor: 'c1'),
    );

    container = await start();
    container.read(syncCoordinatorProvider);
    await settle();

    final lines = await db.query(
      'sale_items',
      where: 'sale_id = ?',
      whereArgs: ['s1'],
    );
    expect(lines.map((line) => line['id']), ['fresh-line']);
  });

  test(
    'when the server is unreachable it backs off instead of hammering',
    () async {
      await SyncQueueDao(db).enqueue(QueuedEntity.expenses, 'e1', {'id': 'e1'});
      api.failWith = const AppFailure.offline();

      container = await start();
      container.read(syncCoordinatorProvider);
      await settle();

      final status = container.read(syncCoordinatorProvider);
      expect(status.phase, SyncPhase.offline);
      expect(status.pendingCount, 1, reason: 'nothing is lost while offline');

      // A timer-driven retry straight away is skipped...
      api.failWith = null;
      await container.read(syncCoordinatorProvider.notifier).syncNow();
      expect(api.pushes, isEmpty);

      // ...but the owner tapping "Sync now" goes through immediately.
      await container
          .read(syncCoordinatorProvider.notifier)
          .syncNow(force: true);
      expect(api.pushes, hasLength(1));
      expect(container.read(syncCoordinatorProvider).phase, SyncPhase.idle);
    },
  );

  test(
    'a phone that only keeps records locally never talks to the server',
    () async {
      await SyncQueueDao(db).enqueue(QueuedEntity.expenses, 'e1', {'id': 'e1'});

      container = await start(mode: 'local');
      container.read(syncCoordinatorProvider);
      await settle();
      await container
          .read(syncCoordinatorProvider.notifier)
          .syncNow(force: true);

      expect(api.pushes, isEmpty);
      expect(api.pullCursors, isEmpty);
    },
  );
}

Map<String, dynamic> _expense(String id) => {
  'id': id,
  'category': 'utilities',
  'amount': 125.5,
  'occurred_at': '2026-09-22T01:00:00Z',
  'updated_at': '2026-09-22T01:00:00Z',
  'deleted_at': null,
};

Map<String, dynamic> _sale(String id) => {
  'id': id,
  'payment_method': 'cash',
  'total_amount': 45,
  'cost_amount': 30,
  'discount_amount': 0,
  'occurred_at': '2026-09-22T01:00:00Z',
  'updated_at': '2026-09-22T01:00:00Z',
  'deleted_at': null,
};

Map<String, dynamic> _line(String id, String saleId) => {
  'id': id,
  'sale_id': saleId,
  'product_id': null,
  'product_name': 'Fresh line',
  'quantity': 1,
  'unit_price': 45,
  'unit_cost': 30,
  'line_total': 45,
};
