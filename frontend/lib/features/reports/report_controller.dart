import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/keep_for.dart';
import '../../data/models/report_models.dart';
import '../../data/repositories/data_revision.dart';
import '../../data/repositories/report_repository.dart';
import '../dashboard/dashboard_controller.dart';

final periodReportProvider = FutureProvider.autoDispose<PeriodReport>((ref) {
  ref.keepFor(tabDataLifetime);
  ref.watch(dataRevisionProvider);
  final period = ref.watch(selectedPeriodProvider);

  return ref.watch(reportRepositoryProvider).compile(period);
});
