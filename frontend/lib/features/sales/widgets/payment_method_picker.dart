import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../data/models/payment_method.dart';
import '../../../l10n/l10n.dart';

/// One scrolling row rather than a wrapping block: five chips wrapped onto
/// three lines on a small phone and pushed the Save button off the screen.
/// Cash is first and selected by default, so most sales never touch this.
class PaymentMethodPicker extends StatelessWidget {
  const PaymentMethodPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final PaymentMethod selected;
  final ValueChanged<PaymentMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final method in PaymentMethod.values) ...[
            if (method != PaymentMethod.values.first)
              const SizedBox(width: AppSpacing.sm),
            ChoiceChip(
              label: Text(context.l10n.paymentMethod(method)),
              selected: method == selected,
              onSelected: (_) => onChanged(method),
            ),
          ],
        ],
      ),
    );
  }
}
