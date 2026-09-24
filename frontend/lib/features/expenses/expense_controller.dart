import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/keep_for.dart';
import '../../data/models/expense.dart';
import '../../data/repositories/data_revision.dart';
import '../../data/repositories/expense_repository.dart';
import '../dashboard/dashboard_controller.dart';

final expenseHistoryProvider = FutureProvider.autoDispose<List<Expense>>((ref) {
  ref.keepFor(tabDataLifetime);
  ref.watch(dataRevisionProvider);
  final period = ref.watch(selectedPeriodProvider);
  final now = DateTime.now();

  return ref
      .watch(expenseRepositoryProvider)
      .history(from: period.startOf(now), to: now, limit: 200);
});
