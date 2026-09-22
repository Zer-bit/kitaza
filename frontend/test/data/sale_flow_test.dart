import 'package:flutter_test/flutter_test.dart';
import 'package:kitaza_app/data/local/dao/dashboard_dao.dart';
import 'package:kitaza_app/data/local/dao/product_dao.dart';
import 'package:kitaza_app/data/local/dao/sync_queue_dao.dart';
import 'package:kitaza_app/data/models/payment_method.dart';
import 'package:kitaza_app/data/models/product.dart';
import 'package:kitaza_app/data/repositories/expense_repository.dart';
import 'package:kitaza_app/data/repositories/sale_repository.dart';
import 'package:kitaza_app/data/repositories/withdrawal_repository.dart';
import 'package:kitaza_app/data/models/expense_category.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../support/in_memory_database.dart';

void main() {
  late Database db;
  late SaleRepository sales;
  late ExpenseRepository expenses;
  late WithdrawalRepository withdrawals;
  late ProductDao products;
  late DashboardDao dashboard;

  setUp(() async {
    db = await openTestDatabase();
    sales = SaleRepository(db: db, storeId: testStoreId);
    expenses = ExpenseRepository(db: db, storeId: testStoreId);
    withdrawals = WithdrawalRepository(db: db, storeId: testStoreId);
    products = ProductDao(db);
    dashboard = DashboardDao(db);
  });

  tearDown(() => db.close());

  Future<Product> addProduct({
    required String name,
    required double cost,
    required double price,
    double stock = 10,
  }) async {
    final product = Product(
      id: 'product-$name',
      name: name,
      costPrice: cost,
      sellingPrice: price,
      stockQuantity: stock,
      reorderLevel: 3,
      updatedAt: DateTime.now().toUtc(),
    );

    await products.upsert(testStoreId, product);
    return product;
  }

  group('recording a sale', () {
    test('stores the total, the cost and the profit', () async {
      final product = await addProduct(name: 'Pancit', cost: 12, price: 18);

      final sale = await sales.record(
        cart: [CartLine.fromProduct(product, quantity: 3)],
      );

      expect(sale.totalAmount, 54);
      expect(sale.costAmount, 36);
      expect(sale.profitAmount, 18);
    });

    test('deducts the quantity sold from stock', () async {
      final product = await addProduct(name: 'Coke', cost: 15, price: 20);

      await sales.record(cart: [CartLine.fromProduct(product, quantity: 4)]);

      final updated = await products.find(product.id);
      expect(updated!.stockQuantity, 6);
    });

    test('a quick sale needs no product and moves no stock', () async {
      final sale = await sales.record(cart: [CartLine.quick(25)]);

      expect(sale.totalAmount, 25);
      expect(sale.costAmount, 0);
      expect(sale.lines.single.productId, isNull);
    });

    test('a discount comes off the total but not off the cost', () async {
      final product = await addProduct(name: 'Rice', cost: 40, price: 55);

      final sale = await sales.record(
        cart: [CartLine.fromProduct(product, quantity: 2)],
        discount: 10,
      );

      expect(sale.totalAmount, 100);
      expect(sale.costAmount, 80);
      expect(sale.discountAmount, 10);
    });

    test('a discount can never exceed the gross amount', () async {
      final sale = await sales.record(
        cart: [CartLine.quick(50)],
        discount: 500,
      );

      expect(sale.totalAmount, 0);
      expect(sale.discountAmount, 50);
    });

    test('queues itself for the cloud', () async {
      await sales.record(cart: [CartLine.quick(30)]);

      expect(await SyncQueueDao(db).pendingCount(), 1);
    });
  });

  group('voiding a sale', () {
    test('puts the stock back and drops it from the totals', () async {
      final product = await addProduct(name: 'Sardinas', cost: 20, price: 28);
      final sale = await sales.record(
        cart: [CartLine.fromProduct(product, quantity: 5)],
      );

      expect((await products.find(product.id))!.stockQuantity, 5);

      await sales.voidSale(sale.id);

      expect((await products.find(product.id))!.stockQuantity, 10);
      expect(await sales.history(), isEmpty);
    });
  });

  group('dashboard totals', () {
    test('profit is sales minus cost of goods minus expenses', () async {
      final product = await addProduct(name: 'Tinapay', cost: 10, price: 25);

      await sales.record(cart: [CartLine.fromProduct(product, quantity: 4)]);
      await expenses.record(category: ExpenseCategory.utilities, amount: 30);

      final from = DateTime.now().subtract(const Duration(days: 1));
      final to = DateTime.now().add(const Duration(days: 1));

      final totals = await dashboard.salesTotals(testStoreId, from, to);
      final expenseTotal = await dashboard.expensesTotal(testStoreId, from, to);

      expect(totals.salesTotal, 100);
      expect(totals.costTotal, 40);
      expect(expenseTotal, 30);
      expect(totals.salesTotal - totals.costTotal - expenseTotal, 30);
    });

    test('an owner withdrawal reduces cash but not profit', () async {
      final product = await addProduct(name: 'Kape', cost: 5, price: 15);
      await sales.record(cart: [CartLine.fromProduct(product, quantity: 10)]);
      await withdrawals.record(amount: 60, reason: 'Groceries');

      final from = DateTime.now().subtract(const Duration(days: 1));
      final to = DateTime.now().add(const Duration(days: 1));

      final totals = await dashboard.salesTotals(testStoreId, from, to);
      final taken = await dashboard.withdrawalsTotal(testStoreId, from, to);

      final profit = totals.salesTotal - totals.costTotal;
      expect(profit, 100);
      expect(taken, 60);
      expect(profit - taken, 40);
    });

    test('names the best seller by revenue', () async {
      final cheap = await addProduct(name: 'Candy', cost: 1, price: 2);
      final pricey = await addProduct(name: 'Shampoo', cost: 8, price: 14);

      await sales.record(cart: [CartLine.fromProduct(cheap, quantity: 10)]);
      await sales.record(cart: [CartLine.fromProduct(pricey, quantity: 5)]);

      final best = await dashboard.bestSeller(
        testStoreId,
        DateTime.now().subtract(const Duration(days: 1)),
        DateTime.now().add(const Duration(days: 1)),
      );

      expect(best!.productName, 'Shampoo');
      expect(best.revenue, 70);
    });

    test('sales outside the window are excluded', () async {
      await sales.record(
        cart: [CartLine.quick(100)],
        occurredAt: DateTime.now().toUtc().subtract(const Duration(days: 10)),
      );
      await sales.record(cart: [CartLine.quick(40)]);

      final totals = await dashboard.salesTotals(
        testStoreId,
        DateTime.now().subtract(const Duration(days: 1)),
        DateTime.now().add(const Duration(days: 1)),
      );

      expect(totals.salesTotal, 40);
      expect(totals.saleCount, 1);
    });
  });

  group('low stock', () {
    test('counts only products at or below their reorder level', () async {
      final low = await addProduct(name: 'Asin', cost: 5, price: 9, stock: 10);
      await addProduct(name: 'Suka', cost: 5, price: 9, stock: 10);

      expect(await products.lowStockCount(testStoreId), 0);

      await sales.record(cart: [CartLine.fromProduct(low, quantity: 8)]);

      expect(await products.lowStockCount(testStoreId), 1);
    });
  });

  group('payment methods', () {
    test('are stored and read back', () async {
      await sales.record(
        cart: [CartLine.quick(75)],
        paymentMethod: PaymentMethod.gcash,
      );

      final history = await sales.history();
      expect(history.single.paymentMethod, PaymentMethod.gcash);
    });
  });
}
