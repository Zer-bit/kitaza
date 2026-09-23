import 'package:flutter_test/flutter_test.dart';
import 'package:kitaza_app/data/analysis/demand_forecast.dart';

void main() {
  final today = DateTime(2026, 9, 22);
  DateTime daysAgo(int days) => today.subtract(Duration(days: days));

  List<SellingDay> steady(double perDay, {int days = 28, bool inStock = true}) {
    return [
      for (var back = days - 1; back >= 0; back--)
        SellingDay(day: daysAgo(back), quantity: perDay, inStock: inStock),
    ];
  }

  group('how fast a product sells', () {
    test('a steady seller is read straight off its history', () {
      final forecast = forecastDemand(steady(4), asOf: today);

      expect(forecast.dailyQuantity, closeTo(4, 0.001));
      expect(forecast.isReliable, isTrue);
      expect(forecast.coverDays(10), closeTo(2.5, 0.001));
    });

    test('this week counts for more than the three before it', () {
      final history = [
        for (var back = 27; back >= 7; back--)
          SellingDay(day: daysAgo(back), quantity: 2),
        for (var back = 6; back >= 0; back--)
          SellingDay(day: daysAgo(back), quantity: 10),
      ];

      // 10 recent, 2 earlier: 0.6 x 10 + 0.4 x 2.
      expect(
        forecastDemand(history, asOf: today).dailyQuantity,
        closeTo(6.8, 0.01),
      );
    });

    test('days with nothing on the shelf are left out', () {
      // Sold 6 a day for a week, then ran out for three weeks.
      final history = [
        for (var back = 27; back >= 21; back--)
          SellingDay(day: daysAgo(back), quantity: 6),
        for (var back = 20; back >= 0; back--)
          SellingDay(day: daysAgo(back), quantity: 0, inStock: false),
      ];

      final forecast = forecastDemand(history, asOf: today);

      expect(
        forecast.dailyQuantity,
        closeTo(6, 0.001),
        reason: 'counting the empty days would say 1.5 and under-order forever',
      );
    });

    test('a week of history is not enough to go on', () {
      final forecast = forecastDemand(steady(3, days: 6), asOf: today);

      expect(forecast.isReliable, isFalse, reason: 'only 6 days');
      expect(forecast.daysCounted, 6);
    });

    test('a handful of sales is not enough either', () {
      final history = [
        for (var back = 27; back >= 0; back--)
          SellingDay(day: daysAgo(back), quantity: back == 3 ? 3 : 0),
      ];

      expect(forecastDemand(history, asOf: today).isReliable, isFalse);
    });

    test('nothing at all is not a forecast', () {
      expect(forecastDemand(const [], asOf: today), DemandForecast.none);
      expect(DemandForecast.none.coverDays(5), isNull);
    });

    test('older than the window is ignored', () {
      final history = [
        for (var back = 60; back >= 40; back--)
          SellingDay(day: daysAgo(back), quantity: 20),
        ...steady(2),
      ];

      expect(
        forecastDemand(history, asOf: today).dailyQuantity,
        closeTo(2, 0.001),
      );
    });
  });

  group('rebuilding what was on the shelf', () {
    test('a day that sold nothing with nothing to sell is marked empty', () {
      // Nothing on the shelf now, nothing sold for three days, and 4 sold
      // the day before that.
      final days = sellingDays(
        soldPerDay: {daysAgo(3): 4},
        stockNow: 0,
        stockChanges: const [],
        asOf: today,
        windowDays: 5,
      );

      final byDay = {for (final day in days) day.day: day};
      expect(byDay[daysAgo(0)]!.inStock, isFalse);
      expect(byDay[daysAgo(1)]!.inStock, isFalse);
      expect(byDay[daysAgo(3)]!.inStock, isTrue, reason: 'it sold that day');
      expect(
        byDay[daysAgo(4)]!.inStock,
        isTrue,
        reason: 'stock was still there',
      );
    });

    test('a delivery is undone when walking back', () {
      // 20 delivered yesterday, 5 sold since, 15 on the shelf now: which
      // means the shelf was empty before the delivery arrived.
      final days = sellingDays(
        soldPerDay: {daysAgo(0): 5},
        stockNow: 15,
        stockChanges: [(day: daysAgo(1), change: 20.0, isCount: false)],
        asOf: today,
        windowDays: 4,
      );

      final byDay = {for (final day in days) day.day: day};
      expect(byDay[daysAgo(0)]!.inStock, isTrue);
      expect(byDay[daysAgo(1)]!.inStock, isTrue, reason: 'the delivery day');
      expect(byDay[daysAgo(2)]!.inStock, isFalse, reason: 'empty until then');
      expect(byDay[daysAgo(3)]!.inStock, isFalse);
    });

    test('before the last count, the shelf is taken as stocked', () {
      // A count three days ago; anything older cannot be reconstructed.
      final days = sellingDays(
        soldPerDay: const {},
        stockNow: 0,
        stockChanges: [(day: daysAgo(3), change: -2.0, isCount: true)],
        asOf: today,
        windowDays: 6,
      );

      final byDay = {for (final day in days) day.day: day};
      expect(byDay[daysAgo(1)]!.inStock, isFalse, reason: 'after the count');
      expect(byDay[daysAgo(5)]!.inStock, isTrue, reason: 'unknowable, so kept');
    });
  });

  test('the days before a product existed are not days it failed to sell', () {
    // Added 10 days ago, sold 4 a day since.
    final days = sellingDays(
      soldPerDay: {for (var back = 9; back >= 0; back--) daysAgo(back): 4},
      stockNow: 20,
      stockChanges: [(day: daysAgo(9), change: 60.0, isCount: false)],
      knownFrom: daysAgo(9),
      asOf: today,
    );

    expect(days, hasLength(10));
    expect(forecastDemand(days, asOf: today).dailyQuantity, closeTo(4, 0.01));
  });

  test('orders are rounded to what an owner would ask for', () {
    expect(roundOrder(3.2), 4);
    expect(roundOrder(12.1), 15);
    expect(roundOrder(104), 110);
    expect(roundOrder(0), 0);
    expect(roundOrder(-5), 0);
  });
}
