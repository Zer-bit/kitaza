import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/owner_withdrawal.dart';
import '../../data/repositories/data_revision.dart';
import '../../data/repositories/withdrawal_repository.dart';

final withdrawalHistoryProvider =
    FutureProvider.autoDispose<List<OwnerWithdrawal>>((ref) {
      ref.watch(dataRevisionProvider);
      return ref.watch(withdrawalRepositoryProvider).history();
    });
