/// One of the store's figures beside the middle of similar stores.
class Comparison {
  const Comparison({
    required this.metric,
    required this.yours,
    required this.typical,
  });

  /// `gross_margin_percent`, `expense_percent` or `daily_sales`.
  final String metric;
  final double yours;
  final double typical;

  /// Whether being above the middle is the good side of it.
  bool get higherIsBetter => metric != 'expense_percent';

  bool get isAhead => higherIsBetter ? yours >= typical : yours <= typical;

  factory Comparison.fromJson(Map<String, dynamic> json) => Comparison(
    metric: json['metric'] as String,
    yours: (json['yours'] as num).toDouble(),
    typical: (json['typical'] as num).toDouble(),
  );
}

/// Why there is nothing to compare with yet.
enum NoComparison {
  notEnoughStores,
  notEnoughHistory,
  notSharing;

  static NoComparison? parse(String? raw) => switch (raw) {
    'not_enough_stores' => notEnoughStores,
    'not_enough_history' => notEnoughHistory,
    'not_sharing' => notSharing,
    _ => null,
  };
}

/// How this store sits against others of its kind and size. Only ever
/// medians, and only over enough stores that no single one can be read out
/// of them.
class BenchmarkReport {
  const BenchmarkReport({
    required this.available,
    this.sampleSize = 0,
    this.comparisons = const [],
    this.unavailableBecause,
  });

  final bool available;
  final int sampleSize;
  final List<Comparison> comparisons;
  final NoComparison? unavailableBecause;

  factory BenchmarkReport.fromJson(Map<String, dynamic> json) =>
      BenchmarkReport(
        available: json['available'] as bool? ?? false,
        sampleSize: (json['sample_size'] as num?)?.toInt() ?? 0,
        unavailableBecause: NoComparison.parse(
          json['unavailable_because'] as String?,
        ),
        comparisons: [
          for (final row in (json['comparisons'] as List?) ?? const [])
            Comparison.fromJson(row as Map<String, dynamic>),
        ],
      );
}
