import '../../core/formatting/centavos.dart';

/// Money the owner takes for personal use. Kept out of expenses so profit
/// stays a measure of the business, not of the household.
class OwnerWithdrawal {
  const OwnerWithdrawal({
    required this.id,
    required this.amount,
    required this.occurredAt,
    this.reason,
  });

  final String id;
  final double amount;
  final String? reason;
  final DateTime occurredAt;

  Map<String, Object?> toRow() => {
    'id': id,
    'amount': Centavos.fromPesos(amount),
    'reason': reason,
    'occurred_at': occurredAt.toUtc().toIso8601String(),
    'updated_at': DateTime.now().toUtc().toIso8601String(),
  };

  factory OwnerWithdrawal.fromRow(Map<String, Object?> row) => OwnerWithdrawal(
    id: row['id'] as String,
    amount: Centavos.toPesos(row['amount'] as int? ?? 0),
    reason: row['reason'] as String?,
    occurredAt: readDate(row['occurred_at']),
  );

  Map<String, Object?> toPushJson() => {
    'id': id,
    'amount': amount,
    'reason': reason,
    'occurred_at': occurredAt.toUtc().toIso8601String(),
  };
}
