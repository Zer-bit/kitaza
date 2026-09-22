import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../data/models/expense_category.dart';
import '../../../l10n/l10n.dart';

/// Categories as one grid of large, labelled targets. Faster and far less
/// error-prone than a dropdown when you are standing at a counter.
class CategoryPicker extends StatelessWidget {
  const CategoryPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final ExpenseCategory selected;
  final ValueChanged<ExpenseCategory> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final category in ExpenseCategory.values)
          ChoiceChip(
            avatar: Icon(
              category.icon,
              size: 18,
              color: category == selected
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            label: Text(context.l10n.expenseCategory(category)),
            selected: category == selected,
            onSelected: (_) => onChanged(category),
          ),
      ],
    );
  }
}
