import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';
import 'api_endpoints.dart';

class PushResult {
  const PushResult({required this.applied, required this.rejected});

  final List<String> applied;

  /// Entity id to the reason the server refused it.
  final Map<String, String> rejected;
}

class PullResult {
  const PullResult({required this.tables, required this.cursor});

  /// Table name to the rows the server changed since the last cursor.
  final Map<String, List<Map<String, dynamic>>> tables;
  final String cursor;
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

  Future<PushResult> push(
    String storeId,
    Map<String, List<Map<String, Object?>>> batch,
  ) async {
    final body = await _client.post(
      ApiEndpoints.syncPush(storeId),
      body: batch,
    );

    final rejected = <String, String>{};
    for (final entry in (body['rejected'] as List? ?? const [])) {
      final row = entry as Map<String, dynamic>;
      final id = row['id'] as String?;
      if (id != null) rejected[id] = row['reason'] as String? ?? 'rejected';
    }

    return PushResult(
      applied: (body['applied'] as List? ?? const []).cast<String>(),
      rejected: rejected,
    );
  }

  Future<PullResult> pull(String storeId, String? since) async {
    final body = await _client.get(
      ApiEndpoints.syncPull(storeId),
      query: since == null ? null : {'since': since},
    );

    final tables = <String, List<Map<String, dynamic>>>{
      for (final table in pulledTables)
        table: (body[table] as List? ?? const [])
            .cast<Map<String, dynamic>>()
            .toList(growable: false),
    };

    return PullResult(
      tables: tables,
      cursor:
          body['cursor'] as String? ?? DateTime.now().toUtc().toIso8601String(),
    );
  }
}

final syncApiProvider = Provider<SyncApi>(
  (ref) => SyncApi(ref.watch(apiClientProvider)),
);
