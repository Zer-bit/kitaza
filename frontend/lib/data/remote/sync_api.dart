import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../local/dao/sync_queue_dao.dart';
import 'api_client.dart';
import 'api_endpoints.dart';

/// A row named in a push result, keyed the way the outbox keys it.
typedef QueueKey = ({String entity, String id});

class PushResult {
  const PushResult({required this.applied, required this.rejected});

  final Set<QueueKey> applied;

  /// Rows the server refused, with the reason it gave.
  final Map<QueueKey, String> rejected;
}

class PullPage {
  const PullPage({
    required this.tables,
    required this.cursor,
    required this.hasMore,
  });

  /// Table name to the rows the server changed since the previous cursor.
  final Map<String, List<Map<String, dynamic>>> tables;
  final String cursor;
  final bool hasMore;
}

class SyncApi {
  const SyncApi(this._client);

  final ApiClient _client;

  static const List<String> pulledTables = [
    'products',
    'sales',
    'sale_items',
    'expenses',
    'withdrawals',
    'stock_movements',
  ];

  /// The server names entities in the singular.
  static const Map<String, String> _queuedEntityFor = {
    'product': QueuedEntity.products,
    'stock_movement': QueuedEntity.stockMovements,
    'sale': QueuedEntity.sales,
    'expense': QueuedEntity.expenses,
    'withdrawal': QueuedEntity.withdrawals,
    'deletion': QueuedEntity.deletions,
  };

  Future<PushResult> push(
    String storeId,
    Map<String, List<Map<String, Object?>>> batch,
  ) async {
    final body = await _client.post(
      ApiEndpoints.syncPush(storeId),
      body: batch,
    );

    QueueKey? keyOf(Object? entry) {
      if (entry is! Map) return null;
      final entity = _queuedEntityFor[entry['entity']];
      final id = entry['id'];
      if (entity == null || id is! String) return null;
      return (entity: entity, id: id);
    }

    final applied = <QueueKey>{
      for (final entry in (body['applied'] as List? ?? const [])) ?keyOf(entry),
    };

    final rejected = <QueueKey, String>{};
    for (final entry in (body['rejected'] as List? ?? const [])) {
      final key = keyOf(entry);
      if (key != null) {
        rejected[key] = (entry as Map)['reason'] as String? ?? 'rejected';
      }
    }

    return PushResult(applied: applied, rejected: rejected);
  }

  Future<PullPage> pull(String storeId, String? cursor) async {
    final body = await _client.get(
      ApiEndpoints.syncPull(storeId),
      query: cursor == null ? null : {'cursor': cursor},
    );

    return PullPage(
      tables: {
        for (final table in pulledTables)
          table: (body[table] as List? ?? const [])
              .cast<Map<String, dynamic>>()
              .toList(growable: false),
      },
      cursor: body['cursor'] as String? ?? cursor ?? '',
      hasMore: body['has_more'] as bool? ?? false,
    );
  }
}

final syncApiProvider = Provider<SyncApi>(
  (ref) => SyncApi(ref.watch(apiClientProvider)),
);
