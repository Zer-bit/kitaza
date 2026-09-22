import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/config/app_config.dart';
import '../../core/config/storage_mode.dart';
import '../../core/storage/preferences_store.dart';
import '../local/dao/sync_queue_dao.dart';
import '../remote/sync_api.dart';
import 'store_scope.dart';
import 'sync_row_mapper.dart';

enum SyncPhase { idle, syncing, offline, failed }

class SyncStatus {
  const SyncStatus({
    this.phase = SyncPhase.idle,
    this.pendingCount = 0,
    this.lastSyncedAt,
    this.lastError,
  });

  final SyncPhase phase;
  final int pendingCount;
  final DateTime? lastSyncedAt;
  final String? lastError;

  bool get hasPendingWork => pendingCount > 0;

  SyncStatus copyWith({
    SyncPhase? phase,
    int? pendingCount,
    DateTime? lastSyncedAt,
    String? lastError,
  }) {
    return SyncStatus(
      phase: phase ?? this.phase,
      pendingCount: pendingCount ?? this.pendingCount,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      lastError: lastError,
    );
  }
}

/// Drains the outbox to the cloud and folds the cloud's changes back into
/// SQLite.
///
/// It is safe to call [syncNow] as often as you like: pushes are idempotent
/// upserts keyed on client-generated ids, and pulls resume from a stored
/// cursor.
class SyncCoordinator extends Notifier<SyncStatus> {
  Timer? _periodicTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _running = false;

  @override
  SyncStatus build() {
    if (_isCloudMode) {
      _startWatching();
      ref.onDispose(_stopWatching);
      Future.microtask(syncNow);
    }
    return const SyncStatus();
  }

  bool get _isCloudMode =>
      StorageMode.parse(ref.read(preferencesStoreProvider).readStorageMode())
          .isCloud;

  void _startWatching() {
    _periodicTimer = Timer.periodic(AppConfig.syncInterval, (_) => syncNow());

    // Coming back onto a network is the moment a queued sale should leave the
    // device, so sync is triggered by connectivity rather than only by time.
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      final online = results.any((result) => result != ConnectivityResult.none);
      if (online) syncNow();
    });
  }

  void _stopWatching() {
    _periodicTimer?.cancel();
    _connectivitySubscription?.cancel();
  }

  Future<void> refreshPendingCount() async {
    final pending = await SyncQueueDao(ref.read(databaseProvider))
        .pendingCount();
    state = state.copyWith(pendingCount: pending);
  }

  Future<void> syncNow() async {
    if (_running || !_isCloudMode) return;

    final storeId = ref.read(activeStoreIdProvider);
    if (storeId.isEmpty) return;

    _running = true;
    state = state.copyWith(phase: SyncPhase.syncing);

    try {
      await _pushOutbox(storeId);
      await _pullChanges(storeId);

      state = SyncStatus(
        phase: SyncPhase.idle,
        pendingCount: await SyncQueueDao(ref.read(databaseProvider))
            .pendingCount(),
        lastSyncedAt: DateTime.now(),
      );
    } on Object catch (error) {
      state = state.copyWith(
        phase: SyncPhase.offline,
        lastError: error.toString(),
      );
    } finally {
      _running = false;
    }
  }

  Future<void> _pushOutbox(String storeId) async {
    final queue = SyncQueueDao(ref.read(databaseProvider));
    final pending = await queue.pending();
    if (pending.isEmpty) return;

    final batch = <String, List<Map<String, Object?>>>{
      'products': [],
      'sales': [],
      'expenses': [],
      'withdrawals': [],
    };

    for (final change in pending) {
      batch[change.entity]?.add(change.payload);
    }

    final result = await ref.read(syncApiProvider).push(storeId, batch);
    await queue.clearAccepted(result.applied);

    for (final change in pending) {
      final reason = result.rejected[change.entityId];
      if (reason != null) {
        await queue.recordFailure(change.rowId, reason);
      }
    }
  }

  Future<void> _pullChanges(String storeId) async {
    final preferences = ref.read(preferencesStoreProvider);
    final result = await ref
        .read(syncApiProvider)
        .pull(storeId, preferences.readSyncCursor());

    await _applyPulledRows(storeId, result);
    await preferences.writeSyncCursor(result.cursor);
  }

  /// Server rows win over local copies of the same id: the cloud is the
  /// authority once a device is online, and anything the device changed more
  /// recently is still sitting in the outbox to be pushed next round.
  Future<void> _applyPulledRows(String storeId, PullResult result) async {
    final db = ref.read(databaseProvider);

    await db.transaction((txn) async {
      final batch = txn.batch();

      void insertAll(
        String table,
        List<Map<String, dynamic>> rows,
        Map<String, Object?> Function(Map<String, dynamic>) map,
      ) {
        for (final row in rows) {
          batch.insert(
            table,
            map(row),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }

      insertAll(
        'products',
        result.tables['products']!,
        (row) => SyncRowMapper.product(row, storeId),
      );
      insertAll(
        'sales',
        result.tables['sales']!,
        (row) => SyncRowMapper.sale(row, storeId),
      );
      insertAll(
        'sale_items',
        result.tables['sale_items']!,
        SyncRowMapper.saleItem,
      );
      insertAll(
        'expenses',
        result.tables['expenses']!,
        (row) => SyncRowMapper.expense(row, storeId),
      );
      insertAll(
        'owner_withdrawals',
        result.tables['withdrawals']!,
        (row) => SyncRowMapper.withdrawal(row, storeId),
      );
      insertAll(
        'stock_movements',
        result.tables['stock_movements']!,
        (row) => SyncRowMapper.stockMovement(row, storeId),
      );

      await batch.commit(noResult: true);
    });
  }
}

final syncCoordinatorProvider = NotifierProvider<SyncCoordinator, SyncStatus>(
  SyncCoordinator.new,
);
