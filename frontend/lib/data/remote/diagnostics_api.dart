import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/diagnostics/error_report.dart';
import 'api_client.dart';

class DiagnosticsApi {
  const DiagnosticsApi(this._client);

  final ApiClient _client;

  /// The server accepts at most this many per request.
  static const int batchSize = 20;

  Future<void> upload(List<ErrorReport> reports) async {
    for (var start = 0; start < reports.length; start += batchSize) {
      final batch = reports.skip(start).take(batchSize);
      await _client.post(
        '/diagnostics/errors',
        body: {'reports': batch.map((report) => report.toJson()).toList()},
      );
    }
  }
}

final diagnosticsApiProvider = Provider<DiagnosticsApi>(
  (ref) => DiagnosticsApi(ref.watch(apiClientProvider)),
);
