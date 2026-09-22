import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../data/local/dao/error_report_dao.dart';
import 'error_digest.dart';

/// Catches errors nobody else handled and keeps them for the team to fix.
///
/// Two rules shape it. It must never throw - a crash inside the crash handler
/// is the worst kind - and it must never recurse, so everything is guarded and
/// a failure to record is silently dropped.
class ErrorReporter {
  ErrorReporter({required this.appVersion, required this.platform});

  final String appVersion;
  final String platform;

  Database? _database;
  bool _recording = false;

  /// Points the reporter at the current database. Called at launch and again
  /// after a backup restore replaces it.
  void attach(Database database) => _database = database;

  /// Routes Flutter's and the platform's uncaught errors here.
  void install() {
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      previous?.call(details);
      record(details.exception, details.stack);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      record(error, stack);
      // Handled: logged here, and the app keeps running rather than dying.
      return true;
    };
  }

  Future<void> record(Object error, StackTrace? stack, {DateTime? at}) async {
    final database = _database;
    if (database == null || _recording) return;

    _recording = true;
    try {
      await ErrorReportDao(database).record(
        fingerprint: ErrorDigest.fingerprint(error, stack),
        errorType: error.runtimeType.toString(),
        message: ErrorDigest.message(error),
        stack: ErrorDigest.stack(stack),
        appVersion: appVersion,
        platform: platform,
        at: at ?? DateTime.now(),
      );
    } on Object catch (failure) {
      debugPrint('could not record error: $failure');
    } finally {
      _recording = false;
    }
  }
}
