import 'package:flutter_test/flutter_test.dart';
import 'package:kitaza_app/core/diagnostics/error_digest.dart';
import 'package:kitaza_app/core/diagnostics/error_reporter.dart';
import 'package:kitaza_app/data/local/dao/error_report_dao.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../support/in_memory_database.dart';

StackTrace _traceAt(
  String location, {
  int frameNumber = 0,
}) => StackTrace.fromString(
  '#$frameNumber      SaleRepository.record (package:kitaza_app/$location)\n'
  '#${frameNumber + 1}      main (package:kitaza_app/main.dart:10:3)',
);

void main() {
  group('recognising the same bug', () {
    test('the same error in the same place has one fingerprint', () {
      final a = ErrorDigest.fingerprint(
        StateError('x'),
        _traceAt('sales.dart:42:7'),
      );
      final b = ErrorDigest.fingerprint(
        StateError('different wording'),
        _traceAt('sales.dart:42:7'),
      );
      expect(a, b);
    });

    test('frame numbers shifting between runs do not split one bug in two', () {
      expect(
        ErrorDigest.fingerprint(StateError('x'), _traceAt('sales.dart:42:7')),
        ErrorDigest.fingerprint(
          StateError('x'),
          _traceAt('sales.dart:42:7', frameNumber: 3),
        ),
      );
    });

    test('a different error type or place is a different bug', () {
      final base = ErrorDigest.fingerprint(
        StateError('x'),
        _traceAt('sales.dart:42:7'),
      );
      expect(
        ErrorDigest.fingerprint(
          ArgumentError('x'),
          _traceAt('sales.dart:42:7'),
        ),
        isNot(base),
      );
      expect(
        ErrorDigest.fingerprint(StateError('x'), _traceAt('sales.dart:99:1')),
        isNot(base),
      );
    });

    test('long messages and stacks are cut down to size', () {
      expect(
        ErrorDigest.message(StateError('x' * 5000)).length,
        lessThanOrEqualTo(ErrorDigest.maxMessageLength + 1),
      );
      final deep = StackTrace.fromString(
        List.generate(200, (i) => '#$i frame').join('\n'),
      );
      expect(
        ErrorDigest.stack(deep)!.split('\n'),
        hasLength(ErrorDigest.maxStackLines),
      );
    });
  });

  group('keeping reports on the phone', () {
    late Database db;
    late ErrorReportDao dao;

    setUp(() async {
      db = await openTestDatabase();
      dao = ErrorReportDao(db);
    });
    tearDown(() => db.close());

    Future<void> record(String fingerprint, DateTime at) => dao.record(
      fingerprint: fingerprint,
      errorType: 'StateError',
      message: 'boom',
      stack: null,
      appVersion: '1.0.0+1',
      platform: 'android',
      at: at,
    );

    test('repeats of one bug are counted in a single row', () async {
      final start = DateTime.utc(2026, 9, 22);
      await record('same', start);
      await record('same', start.add(const Duration(minutes: 1)));
      await record('same', start.add(const Duration(minutes: 2)));

      final reports = await dao.pending();
      expect(reports, hasLength(1));
      expect(reports.single.occurrences, 3);
      expect(reports.single.lastSeen, start.add(const Duration(minutes: 2)));
    });

    test('a crash loop cannot fill the phone', () async {
      final start = DateTime.utc(2026, 9, 22);
      for (var i = 0; i < ErrorReportDao.maxKept + 30; i++) {
        await record('bug-$i', start.add(Duration(seconds: i)));
      }

      expect(await dao.count(), ErrorReportDao.maxKept);
      final kept = (await dao.pending()).map((report) => report.fingerprint);
      expect(
        kept,
        contains('bug-${ErrorReportDao.maxKept + 29}'),
        reason: 'newest are kept',
      );
      expect(kept, isNot(contains('bug-0')));
    });
  });

  group('the reporter', () {
    test('records an error it is given', () async {
      final db = await openTestDatabase();
      addTearDown(db.close);
      final reporter = ErrorReporter(
        appVersion: '1.2.3+4',
        platform: 'android 14',
      )..attach(db);

      await reporter.record(StateError('Bad state'), StackTrace.current);

      final report = (await ErrorReportDao(db).pending()).single;
      expect(report.errorType, 'StateError');
      expect(report.appVersion, '1.2.3+4');
    });

    test('never throws, even when it cannot write', () async {
      final db = await openTestDatabase();
      final reporter = ErrorReporter(appVersion: '1', platform: 'test')
        ..attach(db);
      await db.close();

      await expectLater(reporter.record(StateError('x'), null), completes);
    });

    test('does nothing before it has a database', () async {
      final reporter = ErrorReporter(appVersion: '1', platform: 'test');
      await expectLater(reporter.record(StateError('x'), null), completes);
    });
  });
}
