import 'subscription.dart';

class PlanOffer {
  const PlanOffer({
    required this.plan,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.storeLimit,
    required this.allowsStaff,
  });

  final PlanTier plan;
  final double monthlyPrice;
  final double yearlyPrice;
  final int storeLimit;
  final bool allowsStaff;

  double priceFor(int months) => months == 12 ? yearlyPrice : monthlyPrice;

  factory PlanOffer.fromJson(Map<String, dynamic> json) => PlanOffer(
    plan: PlanTier.parse(json['plan'] as String?) ?? PlanTier.basic,
    monthlyPrice: (json['monthly_price'] as num).toDouble(),
    yearlyPrice: (json['yearly_price'] as num).toDouble(),
    storeLimit: (json['store_limit'] as num).toInt(),
    allowsStaff: json['allows_staff'] as bool? ?? false,
  );
}

class PaymentRecord {
  const PaymentRecord({
    required this.id,
    required this.plan,
    required this.months,
    required this.amount,
    required this.paidAt,
    this.method,
  });

  final String id;
  final PlanTier plan;
  final int months;
  final double amount;
  final DateTime paidAt;
  final String? method;

  factory PaymentRecord.fromJson(Map<String, dynamic> json) => PaymentRecord(
    id: json['id'] as String,
    plan: PlanTier.parse(json['plan'] as String?) ?? PlanTier.basic,
    months: (json['months'] as num).toInt(),
    amount: (json['amount'] as num).toDouble(),
    paidAt: DateTime.parse((json['paid_at'] ?? json['created_at']) as String)
        .toLocal(),
    method: json['method'] as String?,
  );
}

class BillingOverview {
  const BillingOverview({
    required this.enabled,
    required this.subscription,
    required this.plans,
    required this.payments,
  });

  /// False on a server that does not charge.
  final bool enabled;
  final Subscription subscription;
  final List<PlanOffer> plans;
  final List<PaymentRecord> payments;

  factory BillingOverview.fromJson(Map<String, dynamic> json) =>
      BillingOverview(
        enabled: json['enabled'] as bool? ?? false,
        subscription: Subscription.fromJson(
          json['subscription'] as Map<String, dynamic>?,
        ),
        plans: [
          for (final row in (json['plans'] as List?) ?? const [])
            PlanOffer.fromJson(row as Map<String, dynamic>),
        ],
        payments: [
          for (final row in (json['payments'] as List?) ?? const [])
            PaymentRecord.fromJson(row as Map<String, dynamic>),
        ],
      );
}
