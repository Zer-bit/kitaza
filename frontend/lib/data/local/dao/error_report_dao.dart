import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

import '../../../core/diagnostics/error_report.dart';

class ErrorReportDao {
  const ErrorReportDao(this._db);

  final DatabaseExecutor _db;

  /// The phone keeps at most this many distinct errors. A bug that fires in a
  /// loop must never be able to fill a cheap phone's storage.
  static const int maxKept = 50;

  static const Uuid _uuid = Uuid();

  Future<void> record({
    required String fingerprint,
    required String errorType,
    required String message,
    required String? stack,
    required String appVersion,
    required String platform,
    required DateTime at,
  }) async {
    final when = at.toUtc().toIso8601String();

    final bumped = await _db.rawUpdate(
      'UPDATE error_reports SET occurrences = occurrences + 1, last_seen = ? WHERE fingerprint = ?',
      [when, fingerprint],
    );
    if (bumped > 0) return;

    await _db.insert('error_reports', {
      'id': _uuid.v4(),
      'fingerprint': fingerprint,
      'error_type': errorType,
      'message': message,
      'stack': stack,
      'occurrences': 1,
      'first_seen': when,
      'last_seen': when,
      'app_version': appVersion,
      'platform': platform,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    await _db.rawDelete(
      'DELETE FROM error_reports WHERE id NOT IN '
      '(SELECT id FROM error_reports ORDER BY last_seen DESC LIMIT ?)',
      [maxKept],
    );
  }

  Future<List<ErrorReport>> pending({int limit = maxKept}) async {
    final rows = await _db.query(
      'error_reports',
      orderBy: 'last_seen DESC',
      limit: limit,
    );
    return rows.map(ErrorReport.fromRow).toList(growable: false);
  }

  Future<int> count() async {
    final result = await _db.rawQuery(
      'SELECT COUNT(*) AS total FROM error_reports',
    );
    return (result.first['total'] as int?) ?? 0;
  }

  Future<void> remove(Iterable<String> ids) async {
    final list = ids.toList(growable: false);
    if (list.isEmpty) return;
    final placeholders = List.filled(list.length, '?').join(', ');
    await _db.rawDelete(
      'DELETE FROM error_reports WHERE id IN ($placeholders)',
      list,
    );
  }

  Future<void> clear() => _db.delete('error_reports');
}
