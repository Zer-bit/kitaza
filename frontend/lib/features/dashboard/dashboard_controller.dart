import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/dashboard_summary.dart';
import '../../data/models/report_period.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../data/repositories/data_revision.dart';

/// Which window the dashboard is showing. Kept outside the summary provider so
/// switching periods does not tear down the whole screen.
final selectedPeriodProvider = NotifierProvider<SelectedPeriod, ReportPeriod>(
  SelectedPeriod.new,
);

class SelectedPeriod extends Notifier<ReportPeriod> {
  @override
  ReportPeriod build() => ReportPeriod.today;

  void select(ReportPeriod period) => state = period;
}

final dashboardSummaryProvider = FutureProvider.autoDispose<DashboardSummary>((
  ref,
) {
  ref.watch(dataRevisionProvider);
  final period = ref.watch(selectedPeriodProvider);

  // Held briefly so flicking between periods does not re-query SQLite for a
  // window the owner just looked at.
  ref.keepAlive();

  return ref.watch(dashboardRepositoryProvider).summarise(period);
});
