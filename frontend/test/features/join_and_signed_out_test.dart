import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitaza_app/app/route_paths.dart';
import 'package:kitaza_app/core/device/device_identity.dart';
import 'package:kitaza_app/core/errors/app_failure.dart';
import 'package:kitaza_app/data/local/dao/sync_queue_dao.dart';
import 'package:kitaza_app/data/remote/auth_api.dart';
import 'package:kitaza_app/features/authentication/auth_controller.dart';
import 'package:kitaza_app/features/authentication/join_store_screen.dart';
import 'package:kitaza_app/features/authentication/session_ended_screen.dart';

import '../support/app_harness.dart';
import '../support/in_memory_database.dart';
import '../support/team_fakes.dart';

class _FakeAuthApi implements AuthApi {
  String? joinedWith;
  Object? refuseWith;

  @override
  Future<Map<String, dynamic>> join({
    required String code,
    required DeviceLabel device,
  }) async {
    joinedWith = code;
    if (refuseWith case final error?) throw error;
    return {
      'access_token': 'access',
      'refresh_token': 'refresh',
      'session_id': 'session',
      'owner': {'id': 'owner', 'full_name': 'Nena Reyes'},
      'stores': [
        {'id': testStoreId, 'name': 'Test Store'},
      ],
      'access': {
        'role': 'staff',
        'staff_id': 'liza',
        'display_name': 'Liza',
        'permissions': <String>[],
      },
    };
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestPhoneIdentity extends DeviceIdentity {
  const _TestPhoneIdentity();

  @override
  Future<String> name() async => 'Test phone';
}

void main() {
  group('joining as staff', () {
    late _FakeAuthApi api;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      api = _FakeAuthApi();
    });

    Future<TestPhone> openJoin(WidgetTester tester) async {
      final phone = await TestPhone.open(
        tester,
        screens: {RoutePaths.joinStore: (_) => const JoinStoreScreen()},
        overrides: (_, _) => [
          authApiProvider.overrideWithValue(api),
          deviceIdentityProvider.overrideWithValue(const _TestPhoneIdentity()),
        ],
      );
      await phone.goTo(tester, RoutePaths.joinStore);
      return phone;
    }

    testWidgets('the code is tidied however it is typed, then joins', (
      tester,
    ) async {
      final phone = await openJoin(tester);

      await tester.enterText(find.byType(TextFormField), 'abcde fghjk');
      await tester.pump();
      final typed = tester.widget<EditableText>(find.byType(EditableText));
      expect(typed.controller.text, 'ABCDE-FGHJK');

      await tester.tap(find.text('Join store'));
      await phone.settle(tester);

      expect(api.joinedWith, 'ABCDE-FGHJK');
      final session = phone.container.read(currentSessionProvider);
      expect(session?.access.isStaff, isTrue);
      expect(session?.access.displayName, 'Liza');
    });

    testWidgets('a half-typed code is caught before anything is sent', (
      tester,
    ) async {
      await openJoin(tester);

      await tester.enterText(find.byType(TextFormField), 'ABCD');
      await tester.tap(find.text('Join store'));
      await tester.pumpAndSettle();

      expect(
        find.text('Enter all 10 letters and numbers of the code'),
        findsOneWidget,
      );
      expect(api.joinedWith, isNull);
    });

    testWidgets('a used or expired code says so, not "wrong password"', (
      tester,
    ) async {
      api.refuseWith = const AppFailure(
        'this code is not valid or has expired',
        code: 'unauthorized',
      );
      final phone = await openJoin(tester);

      await tester.enterText(find.byType(TextFormField), 'ABCDEFGHJK');
      await tester.tap(find.text('Join store'));
      await phone.settle(tester);

      expect(find.textContaining('That code did not work'), findsOneWidget);
      expect(find.textContaining('password'), findsNothing);
    });
  });

  group('after the server signed this phone out', () {
    Future<TestPhone> openEnded(
      WidgetTester tester, {
      bool staff = false,
    }) async {
      final phone = await TestPhone.open(
        tester,
        screens: {RoutePaths.sessionEnded: (_) => const SessionEndedScreen()},
        overrides: (_, _) => [
          currentSessionProvider.overrideWithValue(
            staff ? staffMember({}, ended: true) : cloudOwner(ended: true),
          ),
        ],
      );
      for (final id in ['s1', 's2']) {
        await SyncQueueDao(phone.db)
            .enqueue(QueuedEntity.sales, id, {'id': id}, storeId: testStoreId);
      }
      await phone.goTo(tester, RoutePaths.sessionEnded);
      return phone;
    }

    testWidgets('the owner is told what is still unsent and how to get back', (
      tester,
    ) async {
      final phone = await openEnded(tester);

      expect(find.text('This phone was signed out'), findsOneWidget);
      expect(
        find.textContaining(
          '2 entries recorded here have not reached the cloud',
        ),
        findsOneWidget,
      );
      expect(find.text('Sign in again'), findsOneWidget);

      await phone.tapAfterScrolling(
        tester,
        find.text('Remove this store from the phone'),
      );
      expect(
        find.textContaining('2 entries that never reached the cloud'),
        findsOneWidget,
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(
        await SyncQueueDao(phone.db).pendingCount(),
        2,
        reason: 'backing out keeps everything',
      );
    });

    testWidgets('a staff member is sent for a new code instead', (
      tester,
    ) async {
      await openEnded(tester, staff: true);

      expect(find.text('Enter a new join code'), findsOneWidget);
      expect(find.text('Sign in again'), findsNothing);
    });
  });
}
