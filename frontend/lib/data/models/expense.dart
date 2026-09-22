import '../../core/formatting/centavos.dart';
import 'expense_category.dart';

class Expense {
  const Expense({
    required this.id,
    required this.category,
    required this.amount,
    required this.occurredAt,
    this.description,
  });

  final String id;
  final ExpenseCategory category;
  final String? description;
  final double amount;
  final DateTime occurredAt;

  Map<String, Object?> toRow() => {
    'id': id,
    'category': category.wireName,
    'description': description,
    'amount': Centavos.fromPesos(amount),
    'occurred_at': occurredAt.toUtc().toIso8601String(),
    'updated_at': DateTime.now().toUtc().toIso8601String(),
  };

  factory Expense.fromRow(Map<String, Object?> row) => Expense(
    id: row['id'] as String,
    category: ExpenseCategory.parse(row['category'] as String?),
    description: row['description'] as String?,
    amount: Centavos.toPesos(row['amount'] as int? ?? 0),
    occurredAt: readDate(row['occurred_at']),
  );

  Map<String, Object?> toPushJson() => {
    'id': id,
    'category': category.wireName,
    'description': description,
    'amount': amount,
    'occurred_at': occurredAt.toUtc().toIso8601String(),
  };
}
