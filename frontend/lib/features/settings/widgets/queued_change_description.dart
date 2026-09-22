import 'package:flutter/material.dart';

import '../../../core/formatting/centavos.dart';
import '../../../data/local/dao/sync_queue_dao.dart';
import '../../../data/models/expense_category.dart';
import '../../../l10n/l10n.dart';

/// Turns an outbox row back into something an owner recognises: "Sale ·
/// ₱105.00" rather than an entity name and a UUID.
class QueuedChangeDescription {
  const QueuedChangeDescription({
    required this.icon,
    required this.title,
    this.amount,
  });

  final IconData icon;
  final String title;
  final double? amount;

  static QueuedChangeDescription of(
    QueuedChange change,
    AppLocalizations l10n,
  ) {
    final payload = change.payload;

    return switch (change.entity) {
      QueuedEntity.sales => QueuedChangeDescription(
        icon: Icons.point_of_sale_rounded,
        title: l10n.problemsSale,
        amount: _saleTotal(payload),
      ),
      QueuedEntity.expenses => QueuedChangeDescription(
        icon: Icons.receipt_long_rounded,
        title: l10n.problemsExpense(
          payload['description'] as String? ??
              l10n.expenseCategory(
                ExpenseCategory.parse(payload['category'] as String?),
              ),
        ),
        amount: readDouble(payload['amount']),
      ),
      QueuedEntity.withdrawals => QueuedChangeDescription(
        icon: Icons.wallet_rounded,
        title: l10n.problemsWithdrawal,
        amount: readDouble(payload['amount']),
      ),
      QueuedEntity.products => QueuedChangeDescription(
        icon: Icons.inventory_2_rounded,
        title: l10n.problemsProduct(payload['name'] as String? ?? ''),
      ),
      QueuedEntity.stockMovements => QueuedChangeDescription(
        icon: Icons.swap_vert_rounded,
        title: l10n.problemsStockChange,
      ),
      QueuedEntity.deletions => QueuedChangeDescription(
        icon: Icons.delete_outline_rounded,
        title: l10n.problemsRemoval(_deletedThing(payload['entity'], l10n)),
      ),
      _ => QueuedChangeDescription(
        icon: Icons.sync_problem_rounded,
        title: l10n.problemsChange,
      ),
    };
  }

  static String _deletedThing(Object? entity, AppLocalizations l10n) {
    final word = switch (entity) {
      DeletedEntity.sale => l10n.problemsSale,
      DeletedEntity.expense => l10n.actionExpense,
      DeletedEntity.withdrawal => l10n.problemsWithdrawal,
      DeletedEntity.product => l10n.saleProduct,
      _ => l10n.problemsChange,
    };
    return word.toLowerCase();
  }

  static double _saleTotal(Map<String, Object?> payload) {
    final items = (payload['items'] as List?) ?? const [];
    final gross = items.fold<double>(0, (sum, item) {
      final line = item as Map;
      return sum +
          readDouble(line['unit_price']) * readDouble(line['quantity']);
    });
    return gross - readDouble(payload['discount_amount']);
  }
}
