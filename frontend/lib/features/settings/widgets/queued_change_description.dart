import 'package:flutter/material.dart';

import '../../../core/formatting/centavos.dart';
import '../../../data/local/dao/sync_queue_dao.dart';

/// Turns an outbox row back into something an owner recognises: "Sale of
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

  static QueuedChangeDescription of(QueuedChange change) {
    final payload = change.payload;

    return switch (change.entity) {
      QueuedEntity.sales => QueuedChangeDescription(
        icon: Icons.point_of_sale_rounded,
        title: 'Sale',
        amount: _saleTotal(payload),
      ),
      QueuedEntity.expenses => QueuedChangeDescription(
        icon: Icons.receipt_long_rounded,
        title:
            'Expense: ${payload['description'] ?? payload['category'] ?? ''}',
        amount: readDouble(payload['amount']),
      ),
      QueuedEntity.withdrawals => QueuedChangeDescription(
        icon: Icons.wallet_rounded,
        title: 'Withdrawal',
        amount: readDouble(payload['amount']),
      ),
      QueuedEntity.products => QueuedChangeDescription(
        icon: Icons.inventory_2_rounded,
        title: 'Product: ${payload['name'] ?? ''}',
      ),
      QueuedEntity.stockMovements => const QueuedChangeDescription(
        icon: Icons.swap_vert_rounded,
        title: 'Stock change',
      ),
      QueuedEntity.deletions => QueuedChangeDescription(
        icon: Icons.delete_outline_rounded,
        title: 'Removal of a ${payload['entity'] ?? 'record'}',
      ),
      _ => const QueuedChangeDescription(
        icon: Icons.sync_problem_rounded,
        title: 'Change',
      ),
    };
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
