import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/config/app_config.dart';
import '../../core/errors/app_failure.dart';
import '../../core/storage/preferences_store.dart';
import '../local/dao/error_report_dao.dart';
import '../local/dao/sync_queue_dao.dart';
import '../remote/diagnostics_api.dart';
import '../remote/sync_api.dart';
import 'data_revision.dart';
import 'store_scope.dart';
import 'sync_row_mapper.dart';

enum SyncPhase { idle, syncing, offline, failed }

class SyncStatus {
  const SyncStatus({
    this.phase = SyncPhase.idle,
    this.pendingCount = 0,
    this.parkedCount = 0,
    this.lastSyncedAt,
    this.lastError,
  });

  final SyncPhase phase;
  final int pendingCount;

  /// Rows the server refused repeatedly, waiting for the owner to look.
  final int parkedCount;
  final DateTime? lastSyncedAt;
  final String? lastError;

  bool get hasPendingWork => pendingCount > 0;
  bool get needsAttention => parkedCount > 0;

  SyncStatus copyWith({
    SyncPhase? phase,
    int? pendingCount,
    int? parkedCount,
    DateTime? lastSyncedAt,
    String? lastError,
  }) {
    return SyncStatus(
      phase: phase ?? this.phase,
      pendingCount: pendingCount ?? this.pendingCount,
      parkedCount: parkedCount ?? this.parkedCount,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      lastError: lastError,
    );
  }
}

/// Drains the outbox to the cloud and folds the cloud's changes back into
/// SQLite.
///
/// Safe to trigger as often as you like: pushes are idempotent on
/// client-generated ids, and pulls resume from a stored cursor.
class SyncCoordinator extends Notifier<SyncStatus> {
  static const int _pushBatchSize = 200;
  static const int _maxPushBatches = 50;
  static const int _maxPullPages = 200;
  static const Duration _pushDebounce = Duration(milliseconds: 1500);
  static const Duration _firstBackoff = Duration(seconds: 30);
  static const Duration _maxBackoff = Duration(minutes: 15);

  Timer? _periodicTimer;
  Timer? _pushTimer;
  StreamSubscription<bool>? _connectivitySubscription;
  bool _running = false;
  int _consecutiveFailures = 0;
  DateTime? _retryAfter;

  @override
  SyncStatus build() {
    final storeId = ref.watch(activeStoreIdProvider);
    final mode = ref.watch(storageModeProvider);

    ref.onDispose(_stopWatching);

    if (mode.isCloud && storeId.isNotEmpty) {
      _startWatching();
      Future.microtask(() => syncNow(force: true));
    } else {
      Future.microtask(refreshCounts);
    }

    return const SyncStatus();
  }

  bool get _enabled =>
      ref.read(storageModeProvider).isCloud &&
      ref.read(activeStoreIdProvider).isNotEmpty;

  void _startWatching() {
    _periodicTimer = Timer.periodic(AppConfig.syncInterval, (_) => syncNow());

    // Coming back onto a network is the moment a queued sale should leave
    // the device, so reconnecting skips any backoff in progress.
    _connectivitySubscription = ref.read(connectivityChangesProvider).listen((
      online,
    ) {
      if (online) syncNow(force: true);
    });
  }

  void _stopWatching() {
    _periodicTimer?.cancel();
    _pushTimer?.cancel();
    _connectivitySubscription?.cancel();
  }

  /// Called after every local write. Coalesces a burst of entries - a cashier
  /// ringing up five sales in a row - into one push shortly after the last.
  void schedulePush() {
    refreshCounts();
    if (!_enabled) return;

    _pushTimer?.cancel();
    _pushTimer = Timer(_pushDebounce, syncNow);
  }

  Future<void> refreshCounts() async {
    final queue = SyncQueueDao(ref.read(databaseProvider));
    final pending = await queue.pendingCount();
    final parked = await queue.parkedCount();
    if (!ref.mounted) return;
    state = state.copyWith(pendingCount: pending, parkedCount: parked);
  }

  /// [force] skips the backoff: used when the owner taps "Sync now" and when
  /// the network comes back, the two moments a retry is most likely to work.
  Future<void> syncNow({bool force = false}) async {
    if (_running || !_enabled) return;
    if (!force &&
        _retryAfter != null &&
        DateTime.now().isBefore(_retryAfter!)) {
      return;
    }

    final storeId = ref.read(activeStoreIdProvider);
    _running = true;
    state = state.copyWith(phase: SyncPhase.syncing);

    try {
      await _pushOutbox(storeId);
      final pulledAnything = await _pullChanges(storeId);
      if (!ref.mounted) return;

      _consecutiveFailures = 0;
      _retryAfter = null;
      if (pulledAnything) ref.read(dataRevisionProvider.notifier).bump();
      await _uploadErrorReports();

      state = state.copyWith(
        phase: SyncPhase.idle,
        lastSyncedAt: DateTime.now(),
      );
    } on Object catch (error) {
      if (!ref.mounted) return;
      _consecutiveFailures++;
      _retryAfter = DateTime.now().add(_backoffFor(_consecutiveFailures));

      state = state.copyWith(
        phase: switch (error) {
          AppFailure(isTransient: true) => SyncPhase.offline,
          _ => SyncPhase.failed,
        },
        lastError: error is AppFailure ? error.message : error.toString(),
      );
    } finally {
      _running = false;
      if (ref.mounted) await refreshCounts();
    }
  }

  /// Parked rows the owner has chosen to try again.
  Future<void> retryParked(int rowId) async {
    await SyncQueueDao(ref.read(databaseProvider)).retry(rowId);
    await refreshCounts();
    await syncNow(force: true);
  }

  Future<void> discardParked(int rowId) async {
    await SyncQueueDao(ref.read(databaseProvider)).drop(rowId);
    await refreshCounts();
  }

  /// Sends this phone's error reports while the connection is known to be
  /// good. Best effort: a report that fails to send is simply kept for the
  /// next sync, and never turns a successful sync into a failed one.
  Future<void> _uploadErrorReports() async {
    try {
      final reports = ErrorReportDao(ref.read(databaseProvider));
      final pending = await reports.pending();
      if (pending.isEmpty) return;

      await ref.read(diagnosticsApiProvider).upload(pending);
      await reports.remove(pending.map((report) => report.id));
    } on Object {
      // Kept for next time.
    }
  }

  static Duration _backoffFor(int failures) {
    final doubled = _firstBackoff * math.pow(2, failures - 1).toInt();
    return doubled > _maxBackoff ? _maxBackoff : doubled;
  }

  Future<void> _pushOutbox(String storeId) async {
    final queue = SyncQueueDao(ref.read(databaseProvider));
    final api = ref.read(syncApiProvider);

    for (var batch = 0; batch < _maxPushBatches; batch++) {
      final pending = await queue.pending(limit: _pushBatchSize);
      if (pending.isEmpty) return;

      final body = {
        for (final entity in QueuedEntity.all) entity: <Map<String, Object?>>[],
      };
      for (final change in pending) {
        body[change.entity]?.add(change.payload);
      }

      final result = await api.push(storeId, body);

      final accepted = <int>[];
      for (final change in pending) {
        final key = (entity: change.entity, id: change.entityId);
        final reason = result.rejected[key];
        if (reason != null) {
          await queue.recordFailure(change.rowId, reason);
        } else if (result.applied.contains(key)) {
          accepted.add(change.rowId);
        }
      }
      await queue.clearRows(accepted);

      // Nothing got through: sending the same rows again straight away
      // would get the same answer, so leave them for the next cycle.
      if (accepted.isEmpty) return;
    }
  }

  /// Returns whether any row was written locally.
  Future<bool> _pullChanges(String storeId) async {
    final preferences = ref.read(preferencesStoreProvider);
    final api = ref.read(syncApiProvider);
    var cursor = preferences.readSyncCursor();
    var wroteAnything = false;

    for (var page = 0; page < _maxPullPages; page++) {
      final result = await api.pull(storeId, cursor);
      if (!ref.mounted) return wroteAnything;

      wroteAnything = await _apply(storeId, result) || wroteAnything;
      cursor = result.cursor;
      await preferences.writeSyncCursor(cursor);

      if (!result.hasMore) break;
    }

    return wroteAnything;
  }

  /// Server rows win over local copies of the same id: once a change has been
  /// pushed the cloud holds the authoritative version, and anything newer on
  /// this device is still in the outbox for the next round.
  Future<bool> _apply(String storeId, PullPage page) async {
    final tables = page.tables;
    final total = tables.values.fold<int>(0, (sum, rows) => sum + rows.length);
    if (total == 0) return false;

    await ref.read(databaseProvider).transaction((txn) async {
      final batch = txn.batch();

      void upsertAll(
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

      upsertAll(
        'products',
        tables['products']!,
        (row) => SyncRowMapper.product(row, storeId),
      );
      upsertAll(
        'sales',
        tables['sales']!,
        (row) => SyncRowMapper.sale(row, storeId),
      );

      // A pulled sale carries its complete set of lines, so the local lines
      // are replaced rather than merged.
      final saleIds = tables['sales']!
          .map((row) => row['id'] as String)
          .toList();
      if (saleIds.isNotEmpty) {
        final placeholders = List.filled(saleIds.length, '?').join(', ');
        batch.rawDelete(
          'DELETE FROM sale_items WHERE sale_id IN ($placeholders)',
          saleIds,
        );
      }
      upsertAll('sale_items', tables['sale_items']!, SyncRowMapper.saleItem);

      upsertAll(
        'expenses',
        tables['expenses']!,
        (row) => SyncRowMapper.expense(row, storeId),
      );
      upsertAll(
        'owner_withdrawals',
        tables['withdrawals']!,
        (row) => SyncRowMapper.withdrawal(row, storeId),
      );
      upsertAll(
        'stock_movements',
        tables['stock_movements']!,
        (row) => SyncRowMapper.stockMovement(row, storeId),
      );

      await batch.commit(noResult: true);
    });

    return true;
  }
}

final syncCoordinatorProvider = NotifierProvider<SyncCoordinator, SyncStatus>(
  SyncCoordinator.new,
);
