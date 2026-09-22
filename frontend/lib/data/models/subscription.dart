import 'dart:convert';

enum PlanTier {
  basic,
  pro;

  static PlanTier? parse(String? raw) => switch (raw) {
    'basic' => PlanTier.basic,
    'pro' => PlanTier.pro,
    _ => null,
  };
}

enum SubscriptionStatus {
  /// The server does not charge. Everything is included.
  unlimited,
  trial,
  active,

  /// The period ended; everything still works for a few more days.
  grace,

  /// Uploads wait on the phones until someone pays. Nothing is lost.
  paused;

  static SubscriptionStatus parse(String? raw) => values.firstWhere(
    (status) => status.name == raw,
    orElse: () => unlimited,
  );
}

/// Where the owner's account stands, as the server last described it.
class Subscription {
  const Subscription({
    required this.status,
    this.plan,
    this.periodEndsAt,
    this.pausesAt,
    this.storeLimit,
    this.allowsStaff = true,
  });

  /// An offline phone, or a server that does not charge.
  const Subscription.unlimited()
    : status = SubscriptionStatus.unlimited,
      plan = null,
      periodEndsAt = null,
      pausesAt = null,
      storeLimit = null,
      allowsStaff = true;

  final SubscriptionStatus status;
  final PlanTier? plan;
  final DateTime? periodEndsAt;

  /// When uploads pause if nothing is paid, or have been paused since.
  final DateTime? pausesAt;
  final int? storeLimit;
  final bool allowsStaff;

  bool get isPaused => status == SubscriptionStatus.paused;
  bool get isCharged => status != SubscriptionStatus.unlimited;

  /// Whole days until the trial or paid period runs out; null if it is not
  /// running out.
  int? daysLeft(DateTime now) {
    final ends = periodEndsAt;
    if (ends == null) return null;
    final left = ends.difference(now);
    if (left.isNegative) return 0;
    return (left.inHours / 24).ceil();
  }

  /// Worth a word on the home screen: the trial or period is nearly over, it
  /// has run out, or uploads have paused.
  bool needsAttention(DateTime now) => switch (status) {
    SubscriptionStatus.grace || SubscriptionStatus.paused => true,
    SubscriptionStatus.trial ||
    SubscriptionStatus.active => (daysLeft(now) ?? 99) <= 5,
    SubscriptionStatus.unlimited => false,
  };

  factory Subscription.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const Subscription.unlimited();
    DateTime? date(String key) =>
        DateTime.tryParse(json[key] as String? ?? '')?.toLocal();

    return Subscription(
      status: SubscriptionStatus.parse(json['status'] as String?),
      plan: PlanTier.parse(json['plan'] as String?),
      periodEndsAt: date('period_ends_at'),
      pausesAt: date('pauses_at'),
      storeLimit: (json['store_limit'] as num?)?.toInt(),
      allowsStaff: json['allows_staff'] as bool? ?? true,
    );
  }

  Map<String, Object?> toJson() => {
    'status': status.name,
    'plan': ?plan?.name,
    'period_ends_at': ?periodEndsAt?.toUtc().toIso8601String(),
    'pauses_at': ?pausesAt?.toUtc().toIso8601String(),
    'store_limit': ?storeLimit,
    'allows_staff': allowsStaff,
  };

  String encode() => jsonEncode(toJson());

  static Subscription decode(String? stored) {
    if (stored == null || stored.isEmpty) return const Subscription.unlimited();
    try {
      return Subscription.fromJson(jsonDecode(stored) as Map<String, dynamic>);
    } on FormatException {
      return const Subscription.unlimited();
    }
  }

  @override
  bool operator ==(Object other) =>
      other is Subscription &&
      other.status == status &&
      other.plan == plan &&
      other.periodEndsAt == periodEndsAt &&
      other.pausesAt == pausesAt &&
      other.storeLimit == storeLimit &&
      other.allowsStaff == allowsStaff;

  @override
  int get hashCode => Object.hash(
    status,
    plan,
    periodEndsAt,
    pausesAt,
    storeLimit,
    allowsStaff,
  );
}
