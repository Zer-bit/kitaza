import 'package:flutter_test/flutter_test.dart';
import 'package:kitaza_app/data/analysis/demand_forecast.dart';
import 'package:kitaza_app/data/analysis/price_advisor.dart';
import 'package:kitaza_app/data/analysis/restock_advisor.dart';
import 'package:kitaza_app/data/analysis/seasonality.dart';
import 'package:kitaza_app/data/models/product.dart';

Product product(
  String name, {
  double stock = 0,
  double reorder = 0,
  double cost = 10,
  double price = 15,
  bool active = true,
}) => Product(
  id: name,
  name: name,
  unitLabel: 'pc',
  costPrice: cost,
  sellingPrice: price,
  stockQuantity: stock,
  reorderLevel: reorder,
  isActive: active,
  updatedAt: DateTime(2026, 9, 22),
);

DemandForecast selling(double perDay, {int days = 28}) => DemandForecast(
  dailyQuantity: perDay,
  daysCounted: days,
  totalSold: perDay * days,
);

void main() {
  group('what to reorder', () {
    test('a fast seller close to running out is first in the list', () {
      final coke = product('Coke', stock: 6);
      final rice = product('Rice', stock: 40);

      final advice = suggestRestocks({
        coke: selling(4), // a day and a half left
        rice: selling(2), // twenty days left
      });

      expect(advice.single.product.name, 'Coke');
      expect(advice.single.basis, RestockBasis.sellingRate);
      // 4 a day for ten days plus two days of delivery, less the 6 on hand.
      expect(advice.single.orderQuantity, 45);
      expect(advice.single.coverDays, closeTo(1.5, 0.01));
    });

    test('without enough history it falls back to the reorder level', () {
      final soap = product('Soap', stock: 2, reorder: 5);

      final advice = suggestRestocks({soap: selling(1, days: 4)});

      expect(advice.single.basis, RestockBasis.reorderLevel);
      expect(advice.single.orderQuantity, 8, reason: 'twice the level, less 2');
      expect(advice.single.dailyQuantity, 0);
    });

    test('nothing to say about a well stocked shelf', () {
      expect(
        suggestRestocks({product('Coke', stock: 200): selling(4)}),
        isEmpty,
      );
      expect(
        suggestRestocks({
          product('Soap', stock: 9, reorder: 5): selling(0.1, days: 3),
        }),
        isEmpty,
      );
    });

    test('a product no longer sold is left alone', () {
      final old = product('Old', stock: 0, reorder: 5, active: false);
      expect(suggestRestocks({old: DemandForecast.none}), isEmpty);
    });

    test('products that sell fastest come before the reorder-level ones', () {
      final coke = product('Coke', stock: 2);
      final soap = product('Soap', stock: 1, reorder: 5);
      final rice = product('Rice', stock: 1);

      final advice = suggestRestocks({
        soap: selling(1, days: 3),
        coke: selling(4),
        rice: selling(10),
      });

      expect(advice.map((item) => item.product.name), ['Rice', 'Coke', 'Soap']);
    });
  });

  group('prices worth a second look', () {
    test('selling below cost is said plainly, with the price to fix it', () {
      final oil = product('Cooking oil', cost: 95, price: 90, stock: 12);

      final advice = suggestPrices({oil: selling(1)}).single;

      expect(advice.issue, PriceIssue.belowCost);
      expect(advice.suggestedPrice, closeTo(112, 0.5));
      expect(advice.extraPerMonth, greaterThan(0));
    });

    test('a thin margin on a good seller is worth raising', () {
      final rice = product('Rice', cost: 52, price: 55, stock: 40);

      final advice = suggestPrices({rice: selling(3)}).single;

      expect(advice.issue, PriceIssue.thinMargin);
      expect(advice.suggestedPrice, closeTo(61.5, 0.01));
      // About ₱6.50 more on 90 kilos a month.
      expect(advice.extraPerMonth, closeTo(585, 5));
    });

    test('a few pesos a month is not worth bothering anyone about', () {
      final sachet = product('Shampoo sachet', cost: 7, price: 7.5, stock: 20);

      expect(suggestPrices({sachet: selling(0.2)}), isEmpty);
    });

    test('a healthy margin is left alone', () {
      final soap = product('Soap', cost: 10, price: 18, stock: 30);
      expect(suggestPrices({soap: selling(2)}), isEmpty);
    });

    test('stock that barely moves is flagged as money on the shelf', () {
      final tumbler = product('Tumbler', cost: 120, price: 180, stock: 8);

      final advice = suggestPrices({
        tumbler: const DemandForecast(
          dailyQuantity: 0.03,
          daysCounted: 28,
          totalSold: 1,
        ),
      }).single;

      expect(advice.issue, PriceIssue.slowMover);
      expect(
        advice.suggestedPrice,
        isNull,
        reason: 'a price rise is not the fix',
      );
    });

    test('the price for a margin lands on half pesos', () {
      expect(priceForMargin(52, 15), 61.5);
      expect(priceForMargin(10, 15), 12);
      expect(priceForMargin(0, 15), 0);
    });
  });

  group('when the store sells', () {
    Map<DateTime, double> month({
      required double payday,
      required double other,
    }) => {
      for (var day = 1; day <= 60; day++)
        DateTime(2026, 8, day): isPaydayWeek(DateTime(2026, 8, day))
            ? payday
            : other,
    };

    test('payday weeks are measured, not assumed', () {
      final pattern = detectPaydayPattern(month(payday: 1400, other: 1000));

      expect(pattern.isReliable, isTrue);
      expect(pattern.upliftPercent, closeTo(40, 0.5));
    });

    test('a store with no payday rhythm is not told it has one', () {
      final pattern = detectPaydayPattern(month(payday: 1020, other: 1000));
      expect(pattern.isReliable, isFalse, reason: 'only 2% apart');
    });

    test('a few days of history prove nothing', () {
      final pattern = detectPaydayPattern({
        DateTime(2026, 9, 15): 2000,
        DateTime(2026, 9, 20): 500,
      });
      expect(pattern.isReliable, isFalse);
    });

    test('the next payday is the 15th or the end of the month', () {
      expect(nextPayday(DateTime(2026, 9, 3)), DateTime(2026, 9, 15));
      expect(nextPayday(DateTime(2026, 9, 20)), DateTime(2026, 9, 30));
      expect(nextPayday(DateTime(2026, 9, 30)), DateTime(2026, 10, 15));
      expect(nextPayday(DateTime(2026, 2, 20)), DateTime(2026, 2, 28));
    });

    test('a standout day of the week is found', () {
      final sales = {
        for (var day = 1; day <= 28; day++)
          DateTime(
            2026,
            9,
            day,
          ): DateTime(2026, 9, day).weekday == DateTime.saturday
              ? 3000.0
              : 1000.0,
      };

      final busiest = busiestWeekday(sales)!;

      expect(busiest.weekday, DateTime.saturday);
      expect(busiest.isReliable, isTrue);
      expect(busiest.upliftPercent, greaterThan(100));
    });

    test('an even week says nothing', () {
      final sales = {
        for (var day = 1; day <= 28; day++) DateTime(2026, 9, day): 1000.0,
      };

      expect(busiestWeekday(sales)!.isReliable, isFalse);
      expect(busiestWeekday({DateTime(2026, 9, 1): 10.0}), isNull);
    });
  });
}
