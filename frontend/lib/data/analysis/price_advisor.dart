import '../models/product.dart';
import 'demand_forecast.dart';

/// Why a price is worth a second look.
enum PriceIssue {
  /// Sold for less than it cost. Every sale loses money.
  belowCost,

  /// Almost nothing left after the cost, on something that sells well.
  thinMargin,

  /// Barely sells. Money sitting on the shelf, not a price to raise.
  slowMover,
}

class PriceAdvice {
  const PriceAdvice({
    required this.product,
    required this.issue,
    required this.marginPercent,
    required this.monthlyQuantity,
    this.suggestedPrice,
    this.extraPerMonth = 0,
  });

  final Product product;
  final PriceIssue issue;
  final double marginPercent;
  final double monthlyQuantity;

  /// Absent for a slow mover, where a price change is not the answer.
  final double? suggestedPrice;

  /// What the suggested price would add in a month at the current rate.
  final double extraPerMonth;
}

/// The margin a suggestion aims for, and the floor under what is worth
/// mentioning. Nagging an owner about ₱5 a month is how advice gets ignored.
const double targetMarginPercent = 15;
const double worthMentioningPerMonth = 50;

/// Prices worth a second look, most valuable first.
///
/// Only ever a suggestion with its arithmetic shown; nothing changes a price.
List<PriceAdvice> suggestPrices(
  Map<Product, DemandForecast> catalogue, {
  bool storeHasHistory = true,
  int limit = 5,
}) {
  final advice = <PriceAdvice>[];

  for (final MapEntry(key: product, value: forecast) in catalogue.entries) {
    if (!product.isActive || product.sellingPrice <= 0) continue;

    final monthly = forecast.dailyQuantity * 30;
    final suggested = priceForMargin(product.costPrice, targetMarginPercent);
    final extra = (suggested - product.sellingPrice) * monthly;

    if (product.costPrice > 0 && product.sellingPrice < product.costPrice) {
      advice.add(
        PriceAdvice(
          product: product,
          issue: PriceIssue.belowCost,
          marginPercent: product.marginPercent,
          monthlyQuantity: monthly,
          suggestedPrice: suggested,
          extraPerMonth: extra > 0 ? extra : 0,
        ),
      );
      continue;
    }

    if (forecast.isReliable &&
        product.marginPercent < 8 &&
        extra >= worthMentioningPerMonth) {
      advice.add(
        PriceAdvice(
          product: product,
          issue: PriceIssue.thinMargin,
          marginPercent: product.marginPercent,
          monthlyQuantity: monthly,
          suggestedPrice: suggested,
          extraPerMonth: extra,
        ),
      );
      continue;
    }

    // Slow movers never look reliable - that is the point - so they are
    // judged on having enough history and almost no sales in it. In a store
    // that has barely traded, nothing is a slow mover yet.
    if (storeHasHistory &&
        forecast.daysCounted >= 21 &&
        forecast.totalSold <= 2 &&
        product.stockQuantity >= 5) {
      advice.add(
        PriceAdvice(
          product: product,
          issue: PriceIssue.slowMover,
          marginPercent: product.marginPercent,
          monthlyQuantity: monthly,
        ),
      );
    }
  }

  advice.sort((a, b) {
    final byIssue = a.issue.index.compareTo(b.issue.index);
    return byIssue != 0 ? byIssue : b.extraPerMonth.compareTo(a.extraPerMonth);
  });
  return advice.take(limit).toList(growable: false);
}

/// The price that leaves [marginPercent] of itself after the cost, rounded up
/// to the half peso that prices are actually written in.
double priceForMargin(double cost, double marginPercent) {
  if (cost <= 0) return 0;
  final exact = cost / (1 - marginPercent / 100);
  return (exact * 2).ceil() / 2;
}
