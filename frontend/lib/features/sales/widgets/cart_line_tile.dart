import 'package:flutter/material.dart';

import '../../../core/formatting/peso_formatter.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/repositories/sale_repository.dart';

class CartLineTile extends StatelessWidget {
  const CartLineTile({
    super.key,
    required this.line,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  final CartLine line;
  final ValueChanged<double> onQuantityChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dismissible(
      key: ValueKey(line.key),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: AppRadius.fieldAll,
        ),
        child: Icon(
          Icons.delete_outline_rounded,
          color: theme.colorScheme.onErrorContainer,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(line.productName, style: theme.textTheme.titleMedium),
                  Text(
                    '${PesoFormatter.format(line.unitPrice)} each',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            _QuantityStepper(
              quantity: line.quantity,
              onChanged: onQuantityChanged,
            ),
            const SizedBox(width: AppSpacing.md),
            SizedBox(
              width: 88,
              child: Text(
                PesoFormatter.format(line.total),
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({required this.quantity, required this.onChanged});

  final double quantity;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = quantity == quantity.roundToDouble()
        ? quantity.toInt().toString()
        : quantity.toStringAsFixed(2);

    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.pillAll,
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => onChanged(quantity - 1),
            icon: const Icon(Icons.remove_rounded, size: 20),
            visualDensity: VisualDensity.compact,
            tooltip: 'Less',
          ),
          SizedBox(
            width: 28,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
          ),
          IconButton(
            onPressed: () => onChanged(quantity + 1),
            icon: const Icon(Icons.add_rounded, size: 20),
            visualDensity: VisualDensity.compact,
            tooltip: 'More',
          ),
        ],
      ),
    );
  }
}
