import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitaza_app/core/diagnostics/error_reporter.dart';
import 'package:kitaza_app/core/storage/preferences_store.dart';
import 'package:kitaza_app/data/local/dao/dashboard_dao.dart';
import 'package:kitaza_app/data/local/dao/error_report_dao.dart';
import 'package:kitaza_app/data/local/dao/product_dao.dart';
import 'package:kitaza_app/data/local/dao/sync_queue_dao.dart';
import 'package:kitaza_app/data/models/expense_category.dart';
import 'package:kitaza_app/data/remote/api_client.dart';
import 'package:kitaza_app/data/repositories/expense_repository.dart';
import 'package:kitaza_app/data/repositories/product_repository.dart';
import 'package:kitaza_app/data/repositories/sale_repository.dart';
import 'package:kitaza_app/data/repositories/store_scope.dart';
import 'package:kitaza_app/data/repositories/sync_coordinator.dart';
import 'package:kitaza_app/data/repositories/withdrawal_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

import '../support/in_memory_database.dart';

/// The Flutter data layer against the real Kitaza API: the only test that
/// proves the two halves of the sync protocol agree on every field name.
///
///   KITAZA_CONTRACT_API=http://localhost:8080/api/v1 flutter test test/contract
final String? _api = Platform.environment['KITAZA_CONTRACT_API'];

/// One simulated phone: its own SQLite, its own outbox, its own cursor.
class Device {
  Device._(this.db, this.container, this.storeId);

  final Database db;
  final ProviderContainer container;
  final String storeId;

  static Future<Device> signIn(String token, String cloudStoreId) async {
    final db = await openTestDatabase();
    // The shared fixture seeds a local store; this device belongs to the
    // cloud store instead.
    await db.update('stores', {'id': cloudStoreId});

    SharedPreferences.setMockInitialValues({
      'kitaza.storage_mode': 'cloud',
      'kitaza.active_store_id': cloudStoreId,
    });
    final preferences = PreferencesStore(await SharedPreferences.getInstance());

    final dio = Dio(
      BaseOptions(
        baseUrl: _api!,
        contentType: 'application/json',
        headers: {'authorization': 'Bearer $token'},
        validateStatus: (status) => status != null && status < 400,
      ),
    );

    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        preferencesStoreProvider.overrideWithValue(preferences),
        // One client for every API, as in the real app.
        apiClientProvider.overrideWithValue(ApiClient(dio)),
        connectivityChangesProvider.overrideWithValue(const Stream.empty()),
      ],
    );
    return Device._(db, container, cloudStoreId);
  }

  ProductRepository get products => ProductRepository(db: db, storeId: storeId);
  SaleRepository get sales => SaleRepository(db: db, storeId: storeId);
  ExpenseRepository get expenses => ExpenseRepository(db: db, storeId: storeId);
  WithdrawalRepository get withdrawals =>
      WithdrawalRepository(db: db, storeId: storeId);

  Future<SyncStatus> sync() async {
    final coordinator = container.read(syncCoordinatorProvider.notifier);
    // The coordinator also starts a sync of its own on creation; waiting
    // for that one to finish keeps this call from being skipped.
    for (var i = 0; i < 400; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      if (container.read(syncCoordinatorProvider).phase != SyncPhase.syncing) {
        break;
      }
    }
    await coordinator.syncNow(force: true);
    return container.read(syncCoordinatorProvider);
  }

  Future<double> stockOf(String productId) async =>
      (await ProductDao(db).find(productId))!.stockQuantity;

  Future<SalesTotals> todaysSales() => DashboardDao(db).salesTotals(
    storeId,
    DateTime.now().subtract(const Duration(days: 1)),
    DateTime.now().add(const Duration(days: 1)),
  );

  Future<void> close() async {
    container.dispose();
    await db.close();
  }
}

Future<(String token, String storeId)> _register() async {
  final dio = Dio(BaseOptions(baseUrl: _api!, contentType: 'application/json'));
  final response = await dio.post<Map<String, dynamic>>(
    '/auth/register',
    data: {
      'email': 'contract-${const Uuid().v4().substring(0, 8)}@example.com',
      'password': 'contract-test-password',
      'full_name': 'Contract Test',
      'store_name': 'Contract Store',
    },
  );
  final body = response.data!;
  return (
    body['access_token'] as String,
    (body['stores'] as List).first['id'] as String,
  );
}

/// The server holds back rows younger than its settle window (two seconds by
/// default) so an in-flight transaction cannot be skipped by a cursor.
Future<void> _outlastSettleWindow() =>
    Future<void>.delayed(const Duration(milliseconds: 2500));

void main() {
  test(
    'two phones sharing a store end up with identical books',
    () async {
      final (token, storeId) = await _register();
      final counter = await Device.signIn(token, storeId);
      final phone = await Device.signIn(token, storeId);
      addTearDown(counter.close);
      addTearDown(phone.close);

      // The counter tablet trades for a while with no signal.
      final coke = await counter.products.save(
        name: 'Coke 290ml',
        costPrice: 15,
        sellingPrice: 20,
        stockQuantity: 24,
        reorderLevel: 6,
      );
      await counter.sales.record(
        cart: [CartLine.fromProduct(coke, quantity: 3)],
      );
      final mistake = await counter.sales.record(
        cart: [CartLine.fromProduct(coke, quantity: 5)],
      );
      await counter.sales.voidSale(mistake.id);
      await counter.sales.record(cart: [CartLine.quick(45)]);
      await counter.expenses.record(
        category: ExpenseCategory.transportation,
        amount: 60,
      );
      await counter.withdrawals.record(amount: 100, reason: 'Lunch');

      // The owner counts the shelf and corrects the number.
      await counter.products.save(
        id: coke.id,
        name: 'Coke 290ml',
        costPrice: 15,
        sellingPrice: 20,
        stockQuantity: 20,
        reorderLevel: 6,
      );

      // The tablet also hit a bug along the way.
      await ErrorReporter(appVersion: '1.0.0+1', platform: 'contract-test')
          .let((reporter) => reporter..attach(counter.db))
          .record(StateError('contract test error'), StackTrace.current);

      final uploaded = await counter.sync();
      expect(uploaded.phase, SyncPhase.idle, reason: uploaded.lastError);
      expect(await SyncQueueDao(counter.db).pendingCount(), 0);
      expect(await SyncQueueDao(counter.db).parkedCount(), 0);
      // Reports are only deleted once the server has accepted them, so an
      // empty table proves the real endpoint took the phone's format.
      expect(await ErrorReportDao(counter.db).count(), 0);

      await _outlastSettleWindow();

      // The owner's phone downloads the store from scratch.
      final downloaded = await phone.sync();
      expect(downloaded.phase, SyncPhase.idle, reason: downloaded.lastError);

      expect(await phone.stockOf(coke.id), 20);
      expect(await phone.stockOf(coke.id), await counter.stockOf(coke.id));

      final phoneSales = await phone.todaysSales();
      final counterSales = await counter.todaysSales();
      expect(phoneSales.saleCount, 2, reason: 'the voided sale must not count');
      expect(phoneSales.salesTotal, 60 + 45);
      expect(phoneSales.salesTotal, counterSales.salesTotal);
      expect(phoneSales.costTotal, counterSales.costTotal);

      // The counter pulls its own sales back; their lines must not double.
      await _outlastSettleWindow();
      await counter.sync();
      final lines = await counter.db.rawQuery(
        'SELECT COUNT(*) AS n FROM sale_items i JOIN sales s ON s.id = i.sale_id '
        'WHERE s.deleted_at IS NULL',
      );
      expect(lines.first['n'], 2);

      // A sale on the phone reaches the counter.
      await phone.sales.record(cart: [CartLine.fromProduct(coke, quantity: 4)]);
      await phone.sync();
      await _outlastSettleWindow();
      await counter.sync();

      expect(await counter.stockOf(coke.id), 16);
      expect((await counter.todaysSales()).saleCount, 3);
    },
    skip: _api == null
        ? 'set KITAZA_CONTRACT_API to run against a live server'
        : false,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

extension<T> on T {
  R let<R>(R Function(T) block) => block(this);
}
