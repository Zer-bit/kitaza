import 'dart:convert';

import 'package:sqflite/sqflite.dart';

/// The outbox. Anything written while the device was offline - or in local
/// mode before the owner upgraded - waits here until it reaches the cloud.
class QueuedChange {
  const QueuedChange({
    required this.rowId,
    required this.entity,
    required this.entityId,
    required this.payload,
  });

  final int rowId;
  final String entity;
  final String entityId;
  final Map<String, Object?> payload;
}

class SyncQueueDao {
  const SyncQueueDao(this._db);

  final DatabaseExecutor _db;

  /// Re-queuing the same entity replaces the old payload, so an item edited
  /// three times offline is pushed once with its final state.
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

  Future<List<QueuedChange>> pending({int limit = 200}) async {
    final rows = await _db.query(
      'sync_queue',
      orderBy: 'created_at ASC',
      limit: limit,
    );

    return rows
        .map(
          (row) => QueuedChange(
            rowId: row['id'] as int,
            entity: row['entity'] as String,
            entityId: row['entity_id'] as String,
            payload:
                jsonDecode(row['payload'] as String) as Map<String, Object?>,
          ),
        )
        .toList(growable: false);
  }

  Future<int> pendingCount() async {
    final result = await _db.rawQuery(
      'SELECT COUNT(*) AS total FROM sync_queue',
    );
    return (result.first['total'] as int?) ?? 0;
  }

  Future<void> clearAccepted(Iterable<String> entityIds) async {
    if (entityIds.isEmpty) return;

    final placeholders = List.filled(entityIds.length, '?').join(', ');
    await _db.rawDelete(
      'DELETE FROM sync_queue WHERE entity_id IN ($placeholders)',
      entityIds.toList(),
    );
  }

  /// A rejected row keeps its place but records why, so the settings screen
  /// can show the owner what needs fixing instead of retrying forever.
  Future<void> recordFailure(int rowId, String reason) {
    return _db.rawUpdate(
      'UPDATE sync_queue SET attempts = attempts + 1, last_error = ? WHERE id = ?',
      [reason, rowId],
    );
  }

  Future<void> clearAll() => _db.delete('sync_queue');
}
