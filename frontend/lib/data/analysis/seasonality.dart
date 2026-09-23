/// Patterns in when a store sells, learned from its own takings.
///
/// Nothing here is a fixed calendar. Payday weeks are checked against the
/// store's own history, because a sari-sari store beside a school and one
/// beside a factory do not share a rhythm, and neither would survive an
/// assumption written into the app.
library;

/// The days around the 15th and the end of the month, when salaries and
/// allowances land in the Philippines.
bool isPaydayWeek(DateTime day) {
  final date = day.day;
  final lastDay = DateTime(day.year, day.month + 1, 0).day;
  return (date >= 13 && date <= 17) || date >= lastDay - 3 || date <= 2;
}

/// The next payday itself: the 15th, or the last day of the month.
DateTime nextPayday(DateTime from) {
  final day = DateTime(from.year, from.month, from.day);
  final lastDay = DateTime(day.year, day.month + 1, 0).day;

  if (day.day < 15) return DateTime(day.year, day.month, 15);
  if (day.day < lastDay) return DateTime(day.year, day.month, lastDay);
  return DateTime(day.year, day.month + 1, 15);
}

/// How much better payday weeks are for this store than the rest of the
/// month.
class PaydayPattern {
  const PaydayPattern({
    required this.upliftPercent,
    required this.paydayDays,
    required this.otherDays,
  });

  final double upliftPercent;
  final int paydayDays;
  final int otherDays;

  /// Enough of both kinds of day, and a difference big enough to act on.
  bool get isReliable =>
      paydayDays >= 6 && otherDays >= 12 && upliftPercent.abs() >= 15;

  static const PaydayPattern none = PaydayPattern(
    upliftPercent: 0,
    paydayDays: 0,
    otherDays: 0,
  );
}

/// Compares takings on payday weeks with the rest of the month.
PaydayPattern detectPaydayPattern(Map<DateTime, double> dailySales) {
  var paydayTotal = 0.0;
  var otherTotal = 0.0;
  var paydayDays = 0;
  var otherDays = 0;

  for (final MapEntry(key: day, value: total) in dailySales.entries) {
    if (isPaydayWeek(day)) {
      paydayTotal += total;
      paydayDays++;
    } else {
      otherTotal += total;
      otherDays++;
    }
  }

  if (paydayDays == 0 || otherDays == 0) return PaydayPattern.none;
  final otherAverage = otherTotal / otherDays;
  if (otherAverage <= 0) return PaydayPattern.none;

  final paydayAverage = paydayTotal / paydayDays;
  return PaydayPattern(
    upliftPercent: (paydayAverage / otherAverage - 1) * 100,
    paydayDays: paydayDays,
    otherDays: otherDays,
  );
}

/// The day of the week a store does best, when one stands out.
class BusiestDay {
  const BusiestDay({
    required this.weekday,
    required this.upliftPercent,
    required this.samples,
  });

  /// `DateTime.monday` … `DateTime.sunday`.
  final int weekday;
  final double upliftPercent;
  final int samples;

  bool get isReliable => samples >= 3 && upliftPercent >= 20;
}

/// Which weekday is furthest above the store's own average.
BusiestDay? busiestWeekday(Map<DateTime, double> dailySales) {
  if (dailySales.length < 21) return null;

  final totals = <int, double>{};
  final counts = <int, int>{};
  for (final MapEntry(key: day, value: total) in dailySales.entries) {
    totals[day.weekday] = (totals[day.weekday] ?? 0) + total;
    counts[day.weekday] = (counts[day.weekday] ?? 0) + 1;
  }

  final overall =
      dailySales.values.fold(0.0, (sum, value) => sum + value) /
      dailySales.length;
  if (overall <= 0) return null;

  BusiestDay? best;
  for (final MapEntry(key: weekday, value: total) in totals.entries) {
    final samples = counts[weekday]!;
    final uplift = (total / samples / overall - 1) * 100;
    if (best == null || uplift > best.upliftPercent) {
      best = BusiestDay(
        weekday: weekday,
        upliftPercent: uplift,
        samples: samples,
      );
    }
  }

  return best;
}
