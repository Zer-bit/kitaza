import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

/// The three buttons the whole product is built around: Add Sale, Add Expense,
/// Check Profit. They are the largest tap targets on the screen and never move.
class QuickActionBar extends StatelessWidget {
  const QuickActionBar({
    super.key,
    required this.onRecordSale,
    required this.onRecordExpense,
    required this.onViewReports,
  });

  final VoidCallback onRecordSale;
  final VoidCallback onRecordExpense;
  final VoidCallback onViewReports;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: _PrimaryAction(
            icon: Icons.add_shopping_cart_rounded,
            label: 'Add sale',
            onPressed: onRecordSale,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _SecondaryAction(
            icon: Icons.remove_circle_outline_rounded,
            label: 'Expense',
            onPressed: onRecordExpense,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _SecondaryAction(
            icon: Icons.insights_rounded,
            label: 'Profit',
            onPressed: onViewReports,
          ),
        ),
      ],
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(60)),
    );
  }
}

class _SecondaryAction extends StatelessWidget {
  const _SecondaryAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(60),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}
