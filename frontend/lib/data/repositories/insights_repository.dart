import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../analysis/demand_forecast.dart';
import '../analysis/price_advisor.dart';
import '../analysis/restock_advisor.dart';
import '../analysis/seasonality.dart';
import '../local/dao/insights_dao.dart';
import '../models/product.dart';
import 'store_scope.dart';

/// How far back the patterns look. Two months covers two paydays, which is
/// the least that can show a rhythm at all.
const int patternWindowDays = 60;

/// What the store's own numbers suggest, with nothing hidden behind them.
class StoreInsights {
  const StoreInsights({
    required this.restock,
    required this.prices,
    required this.payday,
    required this.nextPayday,
    required this.daysOfHistory,
    this.busiestDay,
  });

  final List<RestockAdvice> restock;
  final List<PriceAdvice> prices;
  final PaydayPattern payday;
  final BusiestDay? busiestDay;
  final DateTime nextPayday;

  /// Days on which anything was sold. Below two weeks the app says so
  /// rather than pretending to know the store.
  final int daysOfHistory;

  bool get hasAnything =>
      restock.isNotEmpty ||
      prices.isNotEmpty ||
      payday.isReliable ||
      (busiestDay?.isReliable ?? false);

  static const int enoughHistoryDays = 14;
  bool get isEarlyDays => daysOfHistory < enoughHistoryDays;
}

/// Works out the suggestions from what is already on the phone. Nothing here
/// needs a connection: an owner on a jeepney with no signal gets the same
/// advice as one in the store.
class InsightsRepository {
  const InsightsRepository({required this.dao, required this.storeId});

  final InsightsDao dao;
  final String storeId;

  Future<StoreInsights> compile({DateTime? asOf}) async {
    final today = asOf ?? DateTime.now();
    final from = today.subtract(const Duration(days: patternWindowDays));

    final products = await dao.activeProducts(storeId);
    final sold = await dao.soldPerProductPerDay(storeId, from);
    final changes = await dao.stockChanges(storeId, from);
    final dailySales = await dao.dailySales(storeId, from);

    final forecasts = <Product, DemandForecast>{
      for (final product in products)
        product: forecastDemand(
          sellingDays(
            soldPerDay: sold[product.id] ?? const {},
            stockNow: product.stockQuantity,
            stockChanges: changes[product.id] ?? const [],
            knownFrom: _firstSeen(sold[product.id], changes[product.id]),
            asOf: today,
          ),
          asOf: today,
        ),
    };

    final daysOfHistory = dailySales.length;

    return StoreInsights(
      restock: suggestRestocks(forecasts),
      prices: suggestPrices(
        forecasts,
        storeHasHistory: daysOfHistory >= StoreInsights.enoughHistoryDays,
      ),
      payday: detectPaydayPattern(dailySales),
      busiestDay: busiestWeekday(dailySales),
      nextPayday: nextPayday(today),
      daysOfHistory: daysOfHistory,
    );
  }
}

final insightsRepositoryProvider = Provider<InsightsRepository>((ref) {
  return InsightsRepository(
    dao: InsightsDao(ref.watch(databaseProvider)),
    storeId: ref.watch(activeStoreIdProvider),
  );
});

/// The first day a product was sold or delivered, if that happened inside
/// the window. A product added last week has no history before last week.
DateTime? _firstSeen(Map<DateTime, double>? sold, List<StockChange>? changes) {
  final days = [...?sold?.keys, ...?changes?.map((change) => change.day)];
  if (days.isEmpty) return null;
  return days.reduce((a, b) => a.isBefore(b) ? a : b);
}
