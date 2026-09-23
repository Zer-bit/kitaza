import 'dart:math' as math;

/// One day of one product: how much was sold, and whether there was
/// anything on the shelf to sell.
class SellingDay {
  const SellingDay({
    required this.day,
    required this.quantity,
    this.inStock = true,
  });

  final DateTime day;
  final double quantity;

  /// False for a day the product was out of stock. A day with nothing to
  /// sell says nothing about demand, and counting it as a zero is how a
  /// fast seller talks itself into never being restocked.
  final bool inStock;
}

/// How fast a product sells, and whether that is worth trusting yet.
class DemandForecast {
  const DemandForecast({
    required this.dailyQuantity,
    required this.daysCounted,
    required this.totalSold,
  });

  /// Units a day, over the days the product could actually be sold.
  final double dailyQuantity;

  /// Days of history behind the figure, out of the window looked at.
  final int daysCounted;
  final double totalSold;

  /// Below this there is not enough to go on, and the owner's own reorder
  /// level is the better guide.
  bool get isReliable =>
      daysCounted >= minimumDays &&
      totalSold >= minimumUnits &&
      dailyQuantity > 0;

  /// How long the stock on hand lasts at this rate.
  double? coverDays(double stock) =>
      dailyQuantity <= 0 ? null : stock / dailyQuantity;

  static const int minimumDays = 10;
  static const double minimumUnits = 5;

  static const DemandForecast none = DemandForecast(
    dailyQuantity: 0,
    daysCounted: 0,
    totalSold: 0,
  );
}

/// The window of history the rate is worked out from, and the shorter recent
/// window that is weighted more heavily.
const int forecastWindowDays = 28;
const int recentWindowDays = 7;

/// Works out how fast a product sells from its own history.
///
/// A plain weighted average, not a model: the last week counts for more than
/// the three before it, because a sari-sari store's shelf changes faster than
/// any trend line. Every figure it produces can be checked by hand, which is
/// what lets the app explain itself.
DemandForecast forecastDemand(List<SellingDay> history, {DateTime? asOf}) {
  final today = _startOfDay(asOf ?? DateTime.now());
  // Both windows count today, so a "7 day" window is 7 days, not 8.
  final from = today.subtract(const Duration(days: forecastWindowDays - 1));
  final recentFrom = today.subtract(const Duration(days: recentWindowDays - 1));

  final counted = [
    for (final day in history)
      if (day.inStock && !_startOfDay(day.day).isBefore(from)) day,
  ];
  if (counted.isEmpty) return DemandForecast.none;

  final recent = [
    for (final day in counted)
      if (!_startOfDay(day.day).isBefore(recentFrom)) day,
  ];
  final earlier = [
    for (final day in counted)
      if (_startOfDay(day.day).isBefore(recentFrom)) day,
  ];

  final recentRate = _mean(recent);
  final earlierRate = _mean(earlier);
  final rate = switch ((recentRate, earlierRate)) {
    (null, null) => 0.0,
    (final recent?, null) => recent,
    (null, final earlier?) => earlier,
    (final recent?, final earlier?) => recent * 0.6 + earlier * 0.4,
  };

  return DemandForecast(
    dailyQuantity: rate,
    daysCounted: counted.length,
    totalSold: counted.fold(0.0, (sum, day) => sum + day.quantity),
  );
}

/// Fills in the days a product sold nothing, and marks the days it had
/// nothing to sell.
///
/// Stock is walked backwards from what is on the shelf now. A counted
/// adjustment sets a total rather than a change, so anything before the last
/// count cannot be reconstructed; those days are taken as in stock, which is
/// the safer guess.
List<SellingDay> sellingDays({
  required Map<DateTime, double> soldPerDay,
  required double stockNow,
  required List<({DateTime day, double change, bool isCount})> stockChanges,
  DateTime? asOf,
  DateTime? knownFrom,
  int windowDays = forecastWindowDays,
}) {
  final today = _startOfDay(asOf ?? DateTime.now());
  final sold = {
    for (final entry in soldPerDay.entries) _startOfDay(entry.key): entry.value,
  };
  final changes = <DateTime, double>{};
  DateTime? countedOn;
  for (final change in stockChanges) {
    final day = _startOfDay(change.day);
    if (change.isCount) {
      countedOn = countedOn == null || day.isAfter(countedOn) ? day : countedOn;
    }
    changes[day] = (changes[day] ?? 0) + change.change;
  }

  // Days before the product was first sold or delivered are not days it
  // failed to sell: it was not on the shelf to be sold.
  final firstKnownDay = knownFrom == null ? null : _startOfDay(knownFrom);

  final days = <SellingDay>[];
  var stockAtEndOfDay = stockNow;

  for (var back = 0; back < windowDays; back++) {
    final day = today.subtract(Duration(days: back));
    if (firstKnownDay != null && day.isBefore(firstKnownDay)) break;
    final quantity = sold[day] ?? 0;
    // Before the last count, the reconstruction stops being trustworthy.
    final known = countedOn == null || !day.isBefore(countedOn);
    final ranOut = known && stockAtEndOfDay <= 0 && quantity <= 0;

    days.add(SellingDay(day: day, quantity: quantity, inStock: !ranOut));

    // Yesterday's closing stock: undo today's sales and stock changes.
    stockAtEndOfDay = stockAtEndOfDay + quantity - (changes[day] ?? 0);
  }

  return days.reversed.toList(growable: false);
}

/// Rounds an order up to something an owner would actually ask for.
double roundOrder(double quantity) {
  if (quantity <= 0) return 0;
  if (quantity < 10) return quantity.ceilToDouble();
  if (quantity < 100) return (quantity / 5).ceil() * 5;
  return (quantity / 10).ceil() * 10;
}

double? _mean(List<SellingDay> days) {
  if (days.isEmpty) return null;
  final total = days.fold(0.0, (sum, day) => sum + math.max(0, day.quantity));
  return total / days.length;
}

DateTime _startOfDay(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}
