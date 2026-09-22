import 'dart:convert';

import 'package:sqflite/sqflite.dart';

/// What kind of change a queue row carries. The names double as the keys of
/// the push request body.
abstract final class QueuedEntity {
  static const String products = 'products';
  static const String stockMovements = 'stock_movements';
  static const String sales = 'sales';
  static const String expenses = 'expenses';
  static const String withdrawals = 'withdrawals';
  static const String deletions = 'deletions';

  static const List<String> all = [
    products,
    stockMovements,
    sales,
    expenses,
    withdrawals,
    deletions,
  ];
}

/// Singular names the server uses when a deletion names its target.
abstract final class DeletedEntity {
  static const String sale = 'sale';
  static const String expense = 'expense';
  static const String withdrawal = 'withdrawal';
  static const String product = 'product';
}

class QueuedChange {
  const QueuedChange({
    required this.rowId,
    required this.entity,
    required this.entityId,
    required this.payload,
    this.attempts = 0,
    this.lastError,
  });

  final int rowId;
  final String entity;
  final String entityId;
  final Map<String, Object?> payload;
  final int attempts;
  final String? lastError;
}

/// The outbox. Every local write lands here too, and waits until the cloud
/// has accepted it.
class SyncQueueDao {
  const SyncQueueDao(this._db);

  final DatabaseExecutor _db;

  /// After this many rejections a row stops being retried automatically and
  /// is shown to the owner instead. Rejections are the server saying "no", so
  /// sending the same row forever would never change the answer.
  static const int maxAttempts = 5;

  /// Re-queuing the same entity replaces the old row, so a product edited
  /// three times offline is pushed once with its final state. The replacement
  /// gets a new row id, which is what lets a push in flight tell "the version
  /// I sent" from "an edit made while I was sending".
  Future<void> enqueue(
    String entity,
    String entityId,
    Map<String, Object?> payload,
  ) {
    return _db.insert('sync_queue', {
      'entity': entity,
      'entity_id': entityId,
      'payload': jsonEncode(payload),
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'attempts': 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Queues the removal of something the cloud may already hold, and drops
  /// any unsent version of it: there is no point uploading a sale only to
  /// void it in the same breath.
  Future<void> enqueueDeletion(
    String deletedEntity,
    String queuedEntity,
    String id,
  ) async {
    await discard(queuedEntity, id);
    await enqueue(QueuedEntity.deletions, id, {
      'entity': deletedEntity,
      'id': id,
    });
  }

  Future<void> discard(String entity, String entityId) => _db.delete(
    'sync_queue',
    where: 'entity = ? AND entity_id = ?',
    whereArgs: [entity, entityId],
  );

  /// Rows ready to send, oldest first. Parked rows are left out.
  Future<List<QueuedChange>> pending({int limit = 200}) async {
    final rows = await _db.query(
      'sync_queue',
      where: 'attempts < ?',
      whereArgs: [maxAttempts],
      orderBy: 'id ASC',
      limit: limit,
    );
    return rows.map(_toChange).toList(growable: false);
  }

  /// Rows the server has refused at least once, for the sync problems screen.
  Future<List<QueuedChange>> problems() async {
    final rows = await _db.query(
      'sync_queue',
      where: 'attempts > 0',
      orderBy: 'attempts DESC, id ASC',
    );
    return rows.map(_toChange).toList(growable: false);
  }

  Future<int> pendingCount() => _count('attempts < ?', [maxAttempts]);

  Future<int> parkedCount() => _count('attempts >= ?', [maxAttempts]);

  /// Removes exactly the rows that were sent and accepted. Clearing by entity
  /// id instead would also delete an edit queued while the push was in
  /// flight, and that edit would never reach the cloud.
  Future<void> clearRows(Iterable<int> rowIds) async {
    final ids = rowIds.toList(growable: false);
    if (ids.isEmpty) return;

    final placeholders = List.filled(ids.length, '?').join(', ');
    await _db.rawDelete(
      'DELETE FROM sync_queue WHERE id IN ($placeholders)',
      ids,
    );
  }

  Future<void> recordFailure(int rowId, String reason) {
    return _db.rawUpdate(
      'UPDATE sync_queue SET attempts = attempts + 1, last_error = ? WHERE id = ?',
      [reason, rowId],
    );
  }

  /// Gives a parked row another chance, after the owner has fixed whatever
  /// the server objected to.
  Future<void> retry(int rowId) => _db.rawUpdate(
    'UPDATE sync_queue SET attempts = 0, last_error = NULL WHERE id = ?',
    [rowId],
  );

  Future<void> drop(int rowId) =>
      _db.delete('sync_queue', where: 'id = ?', whereArgs: [rowId]);

  Future<void> clearAll() => _db.delete('sync_queue');

  Future<int> _count(String where, List<Object?> args) async {
    final result = await _db.rawQuery(
      'SELECT COUNT(*) AS total FROM sync_queue WHERE $where',
      args,
    );
    return (result.first['total'] as int?) ?? 0;
  }

  static QueuedChange _toChange(Map<String, Object?> row) => QueuedChange(
    rowId: row['id'] as int,
    entity: row['entity'] as String,
    entityId: row['entity_id'] as String,
    payload: jsonDecode(row['payload'] as String) as Map<String, Object?>,
    attempts: row['attempts'] as int? ?? 0,
    lastError: row['last_error'] as String?,
  );
}
