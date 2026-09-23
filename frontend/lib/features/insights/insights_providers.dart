import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/access_grant.dart';
import '../../data/models/benchmark_report.dart';
import '../../data/remote/benchmarks_api.dart';
import '../../data/repositories/data_revision.dart';
import '../../data/repositories/insights_repository.dart';
import '../../data/repositories/store_scope.dart';
import '../authentication/auth_controller.dart';

/// What the store's own records suggest. Worked out on the phone, so it is
/// there with or without a connection.
final storeInsightsProvider = FutureProvider.autoDispose<StoreInsights>((ref) {
  ref.watch(dataRevisionProvider);
  ref.watch(activeStoreIdProvider);
  return ref.watch(insightsRepositoryProvider).compile();
});

/// How the store compares with others of its kind and size. Needs the cloud,
/// and only for someone who may see profit.
final benchmarkReportProvider = FutureProvider.autoDispose<BenchmarkReport?>((
  ref,
) async {
  final session = ref.watch(currentSessionProvider);
  if (session == null ||
      !session.isCloud ||
      !session.access.can(Permission.viewProfit)) {
    return null;
  }

  try {
    return await ref.watch(benchmarksApiProvider).forStore(session.store.id);
  } on Object {
    // Offline, or the server is busy. The rest of the screen is worked out
    // on the phone and does not need this.
    return null;
  }
});
