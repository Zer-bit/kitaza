import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitaza_app/core/diagnostics/error_report.dart';
import 'package:kitaza_app/core/errors/app_failure.dart';
import 'package:kitaza_app/core/storage/preferences_store.dart';
import 'package:kitaza_app/data/local/dao/error_report_dao.dart';
import 'package:kitaza_app/data/local/dao/sync_queue_dao.dart';
import 'package:kitaza_app/data/remote/diagnostics_api.dart';
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
  final List<String> pushedTo = [];
  final List<String> pulledFrom = [];
  int attempts = 0;
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
    attempts++;
    if (failWith case final error?) throw error;
    pushes.add(batch);
    pushedTo.add(storeId);
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
    attempts++;
    if (failWith case final error?) throw error;
    pulledFrom.add(storeId);
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

/// Stands in for the diagnostics endpoint.
class FakeDiagnosticsApi implements DiagnosticsApi {
  final List<ErrorReport> received = [];
  bool fail = false;

  @override
  Future<void> upload(List<ErrorReport> reports) async {
    if (fail) throw const AppFailure.offline();
    received.addAll(reports);
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
  late FakeDiagnosticsApi diagnostics;

  Future<ProviderContainer> start({
    String mode = 'cloud',
    Map<String, Object> savedPreferences = const {},
  }) async {
    SharedPreferences.setMockInitialValues({
      'kitaza.storage_mode': mode,
      'kitaza.active_store_id': testStoreId,
      ...savedPreferences,
    });
    final preferences = PreferencesStore(await SharedPreferences.getInstance());

    final created = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        preferencesStoreProvider.overrideWithValue(preferences),
        syncApiProvider.overrideWithValue(api),
        diagnosticsApiProvider.overrideWithValue(diagnostics),
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
    diagnostics = FakeDiagnosticsApi();
  });

  tearDown(() => db.close());

  test('queued changes are uploaded and cleared once accepted', () async {
    final queue = SyncQueueDao(db);
    await queue.enqueue(QueuedEntity.expenses, 'e1', {
      'id': 'e1',
      'amount': 10,
    }, storeId: testStoreId);
    await queue.enqueue(QueuedEntity.sales, 's1', {
      'id': 's1',
      'items': [],
    }, storeId: testStoreId);

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
    await queue.enqueue(QueuedEntity.sales, 'bad', {
      'id': 'bad',
    }, storeId: testStoreId);
    await queue.enqueue(QueuedEntity.expenses, 'good', {
      'id': 'good',
    }, storeId: testStoreId);
    api.refuse = {'bad'};

    container = await start();
    container.read(syncCoordinatorProvider);
    await settle();

    final problems = await queue.problems();
    expect(problems.single.entityId, 'bad');
    expect(problems.single.lastError, 'product not found');
    expect(await queue.pendingCount(), 1);
  });

  test('each queued change goes to the store it was made in', () async {
    // A sale rung up in the branch, then the owner switched back home
    // before it uploaded.
    final queue = SyncQueueDao(db);
    await queue.enqueue(QueuedEntity.sales, 'home-sale', {
      'id': 'home-sale',
    }, storeId: testStoreId);
    await queue.enqueue(QueuedEntity.sales, 'branch-sale', {
      'id': 'branch-sale',
    }, storeId: 'branch');

    container = await start();
    container.read(syncCoordinatorProvider);
    await settle();

    expect(api.pushedTo.toSet(), {testStoreId, 'branch'});
    for (final (index, storeId) in api.pushedTo.indexed) {
      final sent = api.pushes[index][QueuedEntity.sales]!.single['id'];
      expect(sent, storeId == 'branch' ? 'branch-sale' : 'home-sale');
    }
    expect(await queue.pendingCount(), 0);
    expect(api.pulledFrom.toSet(), {
      testStoreId,
    }, reason: 'only the open store');
  });

  test('each store keeps its own place in the download', () async {
    // A phone from before stores could be switched had one cursor.
    container = await start(
      savedPreferences: {'kitaza.sync_cursor': 'old-place'},
    );
    container.read(syncCoordinatorProvider);
    await settle();

    expect(api.pullCursors.first, 'old-place');
    final preferences = container.read(preferencesStoreProvider);
    expect(preferences.readSyncCursor(testStoreId), 'done');
    expect(
      preferences.readSyncCursor('branch'),
      isNull,
      reason: 'another store starts from the beginning',
    );
  });

  test('a phone the server signed out stops trying', () async {
    await SyncQueueDao(db)
        .enqueue(QueuedEntity.sales, 's1', {'id': 's1'}, storeId: testStoreId);
    api.failWith = const AppFailure.unauthorized();

    container = await start();
    container.read(syncCoordinatorProvider);
    await settle();
    final attempts = api.attempts;

    await container.read(syncCoordinatorProvider.notifier).syncNow(force: true);

    expect(api.attempts, attempts, reason: 'no request after the refusal');
    expect(container.read(syncCoordinatorProvider).phase, SyncPhase.failed);
    expect(
      await SyncQueueDao(db).pendingCount(),
      1,
      reason: 'kept to send later',
    );
  });

  test('an entry written during an upload is not lost', () async {
    final queue = SyncQueueDao(db);
    await queue.enqueue(QueuedEntity.products, 'p1', {
      'id': 'p1',
      'name': 'Old',
    }, storeId: testStoreId);

    api.duringPush = () async {
      api.duringPush = null;
      await queue.enqueue(QueuedEntity.products, 'p1', {
        'id': 'p1',
        'name': 'New',
      }, storeId: testStoreId);
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
    expect(
      container.read(preferencesStoreProvider).readSyncCursor(testStoreId),
      'c3',
    );
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
      await SyncQueueDao(db).enqueue(QueuedEntity.expenses, 'e1', {
        'id': 'e1',
      }, storeId: testStoreId);
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
      await SyncQueueDao(db).enqueue(QueuedEntity.expenses, 'e1', {
        'id': 'e1',
      }, storeId: testStoreId);

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

  group('error reports', () {
    Future<void> recordError(String fingerprint) => ErrorReportDao(db).record(
      fingerprint: fingerprint,
      errorType: 'StateError',
      message: 'boom',
      stack: null,
      appVersion: '1.0.0+1',
      platform: 'android',
      at: DateTime.utc(2026, 9, 22),
    );

    test('are sent after a good sync and then forgotten', () async {
      await recordError('a');
      await recordError('b');

      container = await start();
      container.read(syncCoordinatorProvider);
      await settle();

      expect(
        diagnostics.received.map((r) => r.fingerprint),
        unorderedEquals(['a', 'b']),
      );
      expect(await ErrorReportDao(db).count(), 0);
    });

    test(
      'are kept for next time if sending fails, without failing the sync',
      () async {
        await recordError('a');
        diagnostics.fail = true;

        container = await start();
        container.read(syncCoordinatorProvider);
        await settle();

        expect(container.read(syncCoordinatorProvider).phase, SyncPhase.idle);
        expect(await ErrorReportDao(db).count(), 1);
      },
    );

    test('never leave an offline-only phone', () async {
      await recordError('a');

      container = await start(mode: 'local');
      container.read(syncCoordinatorProvider);
      await settle();

      expect(diagnostics.received, isEmpty);
    });
  });
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
