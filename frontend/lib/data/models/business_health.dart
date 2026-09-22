enum HealthRating {
  green,
  yellow,
  red;

  static HealthRating parse(String? raw) => switch (raw) {
    'green' => HealthRating.green,
    'red' => HealthRating.red,
    _ => HealthRating.yellow,
  };
}

class BusinessHealth {
  const BusinessHealth({
    required this.rating,
    required this.score,
    required this.headline,
    required this.reasons,
  });

  final HealthRating rating;
  final int score;
  final String headline;
  final List<String> reasons;

  factory BusinessHealth.fromJson(Map<String, dynamic> json) => BusinessHealth(
    rating: HealthRating.parse(json['rating'] as String?),
    score: (json['score'] as num?)?.toInt() ?? 0,
    headline: json['headline'] as String? ?? '',
    reasons: (json['reasons'] as List?)?.cast<String>() ?? const [],
  );

  static const BusinessHealth unknown = BusinessHealth(
    rating: HealthRating.yellow,
    score: 50,
    headline: 'No sales recorded yet',
    reasons: ['Record your first sale to see how your store is doing.'],
  );
}
