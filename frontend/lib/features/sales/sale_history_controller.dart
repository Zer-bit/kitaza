import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/keep_for.dart';
import '../../data/models/report_period.dart';
import '../../data/models/sale.dart';
import '../../data/repositories/data_revision.dart';
import '../../data/repositories/sale_repository.dart';
import '../dashboard/dashboard_controller.dart';

final saleHistoryProvider = FutureProvider.autoDispose<List<Sale>>((ref) {
  ref.keepFor(tabDataLifetime);
  ref.watch(dataRevisionProvider);
  final period = ref.watch(selectedPeriodProvider);
  final now = DateTime.now();

  return ref
      .watch(saleRepositoryProvider)
      .history(
        from: period == ReportPeriod.today
            ? period.startOf(now)
            : period.startOf(now),
        to: now,
        limit: 200,
      );
});
