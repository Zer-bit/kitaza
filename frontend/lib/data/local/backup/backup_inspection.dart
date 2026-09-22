/// Why a file was refused as a backup.
enum BackupProblem {
  /// Not a SQLite database at all, or unreadable.
  notABackup,

  /// A database, but not one Kitaza made.
  wrongApp,

  /// Made by a newer version of the app than this one.
  tooNew,

  /// A Kitaza backup, but damaged.
  damaged,
}

/// What a backup file contains, read before anything on the phone is touched,
/// so the owner confirms a restore knowing exactly what they will get.
class BackupInspection {
  const BackupInspection.valid({
    required this.storeId,
    required this.storeName,
    required this.saleCount,
    required this.productCount,
    required this.lastActivity,
  }) : problem = null;

  const BackupInspection.invalid(BackupProblem this.problem)
    : storeId = null,
      storeName = null,
      saleCount = 0,
      productCount = 0,
      lastActivity = null;

  final BackupProblem? problem;
  final String? storeId;
  final String? storeName;
  final int saleCount;
  final int productCount;

  /// The most recent sale or expense, so the owner can tell an old backup
  /// from yesterday's.
  final DateTime? lastActivity;

  bool get isValid => problem == null;
}
