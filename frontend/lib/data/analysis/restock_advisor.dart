import '../models/product.dart';
import 'demand_forecast.dart';

/// What the advice is built on, so the app can say which it used.
enum RestockBasis {
  /// How fast the product has actually been selling.
  sellingRate,

  /// The owner's own reorder level, when there is not enough history yet.
  /// This is the Phase 3 rule, kept as the floor under everything here.
  reorderLevel,
}

class RestockAdvice {
  const RestockAdvice({
    required this.product,
    required this.orderQuantity,
    required this.basis,
    required this.dailyQuantity,
    this.coverDays,
  });

  final Product product;

  /// How much to order, rounded to something an owner would ask for.
  final double orderQuantity;
  final RestockBasis basis;

  /// Units a day; zero when the advice comes from the reorder level.
  final double dailyQuantity;

  /// How many days the stock on hand lasts. Null without a rate.
  final double? coverDays;

  bool get isOutOfStock => product.stockQuantity <= 0;
}

/// How long a delivery takes to arrive, and how long an order should last.
const int deliveryDays = 2;
const int targetCoverDays = 10;

/// What to reorder, soonest first.
///
/// A product with enough history is judged by how fast it sells; one without
/// falls back to the reorder level the owner set. Nothing here orders
/// anything: it is a list to look at before going to the supplier.
List<RestockAdvice> suggestRestocks(
  Map<Product, DemandForecast> catalogue, {
  int limit = 6,
}) {
  final byRate = <RestockAdvice>[];
  final byLevel = <RestockAdvice>[];

  for (final MapEntry(key: product, value: forecast) in catalogue.entries) {
    if (!product.isActive) continue;

    if (forecast.isReliable) {
      final cover = forecast.coverDays(product.stockQuantity)!;
      if (cover > deliveryDays + 1) continue;

      final order = roundOrder(
        forecast.dailyQuantity * (targetCoverDays + deliveryDays) -
            product.stockQuantity,
      );
      if (order <= 0) continue;

      byRate.add(
        RestockAdvice(
          product: product,
          orderQuantity: order,
          basis: RestockBasis.sellingRate,
          dailyQuantity: forecast.dailyQuantity,
          coverDays: cover,
        ),
      );
      continue;
    }

    if (product.reorderLevel > 0 &&
        product.stockQuantity <= product.reorderLevel) {
      byLevel.add(
        RestockAdvice(
          product: product,
          orderQuantity: roundOrder(
            (product.reorderLevel * 2) - product.stockQuantity,
          ),
          basis: RestockBasis.reorderLevel,
          dailyQuantity: 0,
        ),
      );
    }
  }

  // Whatever runs out first comes first; products judged by a reorder level
  // follow, since there is less behind those.
  byRate.sort((a, b) => a.coverDays!.compareTo(b.coverDays!));
  byLevel.sort(
    (a, b) => (a.product.stockQuantity / a.product.reorderLevel).compareTo(
      b.product.stockQuantity / b.product.reorderLevel,
    ),
  );

  return [...byRate, ...byLevel].take(limit).toList(growable: false);
}
