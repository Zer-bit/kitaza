import 'package:flutter_test/flutter_test.dart';
import 'package:kitaza_app/data/analysis/restock_advisor.dart';
import 'package:kitaza_app/data/local/dao/insights_dao.dart';
import 'package:kitaza_app/data/local/dao/stock_movement_dao.dart';
import 'package:kitaza_app/data/models/expense_category.dart';
import 'package:kitaza_app/data/models/product.dart';
import 'package:kitaza_app/data/models/stock_movement.dart';
import 'package:kitaza_app/data/repositories/expense_repository.dart';
import 'package:kitaza_app/data/repositories/insights_repository.dart';
import 'package:kitaza_app/data/repositories/product_repository.dart';
import 'package:kitaza_app/data/repositories/sale_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../support/in_memory_database.dart';

void main() {
  late Database db;
  late InsightsRepository insights;
  final today = DateTime(2026, 9, 22, 10);

  setUp(() async {
    db = await openTestDatabase();
    insights = InsightsRepository(dao: InsightsDao(db), storeId: testStoreId);
  });
  tearDown(() => db.close());

  Future<Product> stocked(
    String name, {
    double stock = 100,
    double cost = 10,
    double price = 15,
    double reorder = 0,
  }) => ProductRepository(db: db, storeId: testStoreId).save(
    name: name,
    costPrice: cost,
    sellingPrice: price,
    stockQuantity: stock,
    reorderLevel: reorder,
  );

  /// Sells [quantity] of [product] on the day [back] days before today.
  Future<void> sell(Product product, double quantity, int back) =>
      SaleRepository(db: db, storeId: testStoreId).record(
        cart: [CartLine.fromProduct(product, quantity: quantity)],
        occurredAt: today.subtract(Duration(days: back)),
      );

  test('a fast seller running low is the first thing to reorder', () async {
    final coke = await stocked('Coke 1.5L', stock: 92);
    for (var back = 20; back >= 0; back--) {
      await sell(coke, 4, back);
    }
    // 92 in, 84 sold: 8 left, two days' worth.

    final advice = (await insights.compile(asOf: today)).restock;

    expect(advice.single.product.name, 'Coke 1.5L');
    expect(advice.single.dailyQuantity, closeTo(4, 0.01));
    expect(advice.single.orderQuantity, greaterThan(20));
    expect(advice.single.basis, RestockBasis.sellingRate);
  });

  test('a product with no history falls back to its reorder level', () async {
    await stocked('Soap', stock: 2, reorder: 6);

    final advice = (await insights.compile(asOf: today)).restock;

    expect(advice.single.basis, RestockBasis.reorderLevel);
  });

  test(
    'the weeks a product was out of stock do not drag its rate down',
    () async {
      // Empty shelf for three weeks, a delivery of 17 ten days ago, then
      // three a day for the last five days. Two left.
      final rice = await stocked('Rice', stock: 0);
      await StockMovementDao(db).apply(
        testStoreId,
        StockMovement(
          id: 'delivery',
          productId: rice.id,
          kind: StockMovementKind.stockIn,
          quantity: 17,
          occurredAt: today.subtract(const Duration(days: 10)),
        ),
      );
      for (var back = 4; back >= 0; back--) {
        await sell(rice, 3, back);
      }

      final advice = (await insights.compile(asOf: today)).restock.single;

      expect(
        advice.dailyQuantity,
        greaterThan(0.9),
        reason: 'counting the empty weeks would say about 0.5 and under-order',
      );
      expect(advice.orderQuantity, greaterThan(10));
    },
  );

  test('a quiet store is told it is early days, not given guesses', () async {
    await stocked('Coke', stock: 20, reorder: 0);
    await ExpenseRepository(
      db: db,
      storeId: testStoreId,
    ).record(category: ExpenseCategory.transportation, amount: 100);

    final compiled = await insights.compile(asOf: today);

    expect(compiled.isEarlyDays, isTrue);
    expect(compiled.hasAnything, isFalse);
    expect(compiled.payday.isReliable, isFalse);
  });

  test('payday weeks are read from the store\'s own takings', () async {
    final coke = await stocked('Coke', stock: 10000);
    for (var back = 59; back >= 0; back--) {
      final day = today.subtract(Duration(days: back));
      final isPayday =
          (day.day >= 13 && day.day <= 17) || day.day >= 28 || day.day <= 2;
      await sell(coke, isPayday ? 20 : 8, back);
    }

    final compiled = await insights.compile(asOf: today);

    expect(compiled.payday.isReliable, isTrue);
    expect(compiled.payday.upliftPercent, greaterThan(100));
    expect(compiled.nextPayday.isAfter(today), isTrue);
  });
}
