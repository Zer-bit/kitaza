import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'backup_service.dart';

/// Makes the day's automatic copy once per launch, in the background. A
/// failed copy must never get in the way of recording a sale, so errors are
/// swallowed here; the next launch simply tries again.
final automaticBackupProvider = FutureProvider<void>((ref) async {
  try {
    await ref.read(backupServiceProvider).backUpIfDue();
  } on Object {
    // Deliberately silent: see above.
  }
});
