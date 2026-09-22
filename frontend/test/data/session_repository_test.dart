import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitaza_app/core/device/device_identity.dart';
import 'package:kitaza_app/core/storage/preferences_store.dart';
import 'package:kitaza_app/core/storage/secure_token_store.dart';
import 'package:kitaza_app/data/local/dao/session_dao.dart';
import 'package:kitaza_app/data/local/dao/sync_queue_dao.dart';
import 'package:kitaza_app/data/models/access_grant.dart';
import 'package:kitaza_app/data/models/owner_account.dart';
import 'package:kitaza_app/data/remote/auth_api.dart';
import 'package:kitaza_app/data/repositories/session_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../support/in_memory_database.dart';

/// Answers every sign-in with whatever [next] says.
class _FakeAuthApi implements AuthApi {
  Map<String, dynamic> next = const {};
  DeviceLabel? lastDevice;

  @override
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
    required DeviceLabel device,
  }) async {
    lastDevice = device;
    return next;
  }

  @override
  Future<Map<String, dynamic>> join({
    required String code,
    required DeviceLabel device,
  }) async {
    lastDevice = device;
    return next;
  }

  @override
  Future<Map<String, dynamic>> account() async => next;

  @override
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    required String storeName,
    required DeviceLabel device,
  }) async => next;

  @override
  Future<void> signOut(String refreshToken) async {}
}

class _TestPhone extends DeviceIdentity {
  const _TestPhone();

  @override
  Future<String> name() async => 'Test phone';
}

Map<String, dynamic> _session({
  String ownerId = 'nena',
  List<String> stores = const [testStoreId],
  Map<String, dynamic> access = const {
    'role': 'owner',
    'display_name': 'Nena',
    'permissions': [
      'manage_products',
      'record_expenses',
      'view_profit',
      'delete_records',
    ],
  },
}) => {
  'access_token': 'access',
  'refresh_token': 'refresh',
  'session_id': 'session',
  'owner': {'id': ownerId, 'full_name': 'Nena', 'email': '$ownerId@x.ph'},
  'stores': [
    for (final id in stores) {'id': id, 'name': 'Store $id'},
  ],
  'access': access,
};

Map<String, dynamic> _staff(
  String staffId, {
  List<String> permissions = const [],
}) => {
  'role': 'staff',
  'staff_id': staffId,
  'display_name': staffId,
  'permissions': permissions,
};

void main() {
  late Database db;
  late _FakeAuthApi api;
  late PreferencesStore preferences;
  late SessionRepository sessions;

  /// A phone that was signed in to the cloud as [ownerId], with a sale that
  /// never made it up and a sale that did.
  Future<void> signedInBefore({
    String ownerId = 'nena',
    AccessGrant? access,
  }) async {
    SharedPreferences.setMockInitialValues({
      'kitaza.storage_mode': 'cloud',
      'kitaza.active_store_id': testStoreId,
      'kitaza.onboarded': true,
      'kitaza.sync_cursor.$testStoreId': 'somewhere',
      'kitaza.access': ?access?.encode(),
    });
    preferences = PreferencesStore(await SharedPreferences.getInstance());
    await SessionDao(db).saveOwner(OwnerAccount(id: ownerId, fullName: 'Nena'));

    for (final id in ['synced', 'unsent']) {
      await db.insert('sales', {
        'id': id,
        'store_id': testStoreId,
        'total_amount': 2000,
        'occurred_at': '2026-09-20T09:00:00Z',
        'updated_at': '2026-09-20T09:00:00Z',
      });
    }
    await SyncQueueDao(db).enqueue(QueuedEntity.sales, 'unsent', {
      'id': 'unsent',
    }, storeId: testStoreId);

    sessions = SessionRepository(
      sessionDao: SessionDao(db),
      preferences: preferences,
      tokens: const SecureTokenStore(FlutterSecureStorage()),
      authApi: api,
      db: db,
      device: const _TestPhone(),
    );
  }

  Future<int> salesOnPhone() async => (await db.query('sales')).length;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    db = await openTestDatabase();
    api = _FakeAuthApi();
  });
  tearDown(() => db.close());

  group('signing back in after the server signed this phone out', () {
    test('the same owner finds their unsent sale still waiting', () async {
      await signedInBefore();
      api.next = _session();

      await sessions.signIn(email: 'nena@x.ph', password: 'secret');

      expect(await salesOnPhone(), 2);
      expect(await SyncQueueDao(db).pendingCount(), 1);
      expect(preferences.readSyncCursor(testStoreId), 'somewhere');
    });

    test('someone else starts on a clean phone', () async {
      await signedInBefore();
      api.next = _session(ownerId: 'somebody-else');

      await sessions.signIn(email: 'other@x.ph', password: 'secret');

      expect(await salesOnPhone(), 0, reason: "not uploaded into their store");
      expect(await SyncQueueDao(db).pendingCount(), 0);
      expect(preferences.readSyncCursor(testStoreId), isNull);
    });

    test(
      'a cashier re-joining keeps their sales; a colleague does not',
      () async {
        final liza = AccessGrant.fromJson(_staff('liza'));

        await signedInBefore(access: liza);
        api.next = _session(access: _staff('liza'));
        await sessions.joinStore('ABCDE-FGHJK');
        expect(await SyncQueueDao(db).pendingCount(), 1);

        api.next = _session(access: _staff('ben'));
        await sessions.joinStore('KJHGF-EDCBA');
        expect(await SyncQueueDao(db).pendingCount(), 0);
        expect(await salesOnPhone(), 0);
      },
    );
  });

  test('the phone tells the server what it is called', () async {
    await signedInBefore();
    api.next = _session();

    await sessions.signIn(email: 'nena@x.ph', password: 'secret');

    expect(api.lastDevice?.name, 'Test phone');
  });

  test(
    'a cloud phone with no session left opens as signed out, records intact',
    () async {
      await signedInBefore();

      final restored = await sessions.restore();

      expect(restored?.ended, isTrue);
      expect(await salesOnPhone(), 2);
    },
  );

  group('when the owner changes what a staff member may see', () {
    final withProfit = AccessGrant.fromJson(
      _staff('liza', permissions: ['view_profit', 'record_expenses']),
    );

    Future<void> withExpenses() async {
      for (final id in ['theirs-unsent', 'already-synced']) {
        await db.insert('expenses', {
          'id': id,
          'store_id': testStoreId,
          'category': 'utilities',
          'amount': 35000,
          'occurred_at': '2026-09-20T09:00:00Z',
          'updated_at': '2026-09-20T09:00:00Z',
        });
      }
      await SyncQueueDao(db).enqueue(QueuedEntity.expenses, 'theirs-unsent', {
        'id': 'theirs-unsent',
      }, storeId: testStoreId);
    }

    test(
      'losing profit access removes the money records and re-downloads',
      () async {
        await signedInBefore(access: withProfit);
        await withExpenses();
        final current = (await sessions.restore())!.copyWith(ended: false);
        api.next = _session(
          access: _staff('liza', permissions: ['record_expenses']),
        );

        final refreshed = await sessions.refreshAccount(current);

        expect(refreshed.accessChanged, isTrue);
        expect(refreshed.session.access.can(Permission.viewProfit), isFalse);
        final left = await db.query('expenses');
        expect(left.map((row) => row['id']), ['theirs-unsent']);
        expect(
          preferences.readSyncCursor(testStoreId),
          isNull,
          reason: 'the next pull overwrites the costs it held',
        );
        expect(
          AccessGrant.decode(preferences.readAccess()),
          refreshed.session.access,
        );
      },
    );

    test('an unchanged grant leaves the phone alone', () async {
      await signedInBefore(access: withProfit);
      await withExpenses();
      final current = (await sessions.restore())!.copyWith(ended: false);
      api.next = _session(
        access: _staff('liza', permissions: ['view_profit', 'record_expenses']),
      );

      final refreshed = await sessions.refreshAccount(current);

      expect(refreshed.accessChanged, isFalse);
      expect(await db.query('expenses'), hasLength(2));
      expect(preferences.readSyncCursor(testStoreId), 'somewhere');
    });
  });

  test('a store added on another phone appears after a refresh', () async {
    await signedInBefore();
    final current = (await sessions.restore())!.copyWith(ended: false);
    api.next = _session(stores: [testStoreId, 'branch']);

    final refreshed = await sessions.refreshAccount(current);

    expect(refreshed.session.stores.map((store) => store.id), [
      testStoreId,
      'branch',
    ]);
    expect(
      refreshed.session.store.id,
      testStoreId,
      reason: 'stays where it was',
    );
    expect(await SessionDao(db).readStore('branch'), isNotNull);
  });
}
