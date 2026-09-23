import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/benchmark_report.dart';
import 'api_client.dart';
import 'api_endpoints.dart';

class BenchmarksApi {
  const BenchmarksApi(this._client);

  final ApiClient _client;

  Future<BenchmarkReport> forStore(String storeId) async =>
      BenchmarkReport.fromJson(
        await _client.get(ApiEndpoints.benchmarks(storeId)),
      );
}

final benchmarksApiProvider = Provider<BenchmarksApi>(
  (ref) => BenchmarksApi(ref.watch(apiClientProvider)),
);
