import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_typography.dart';
import '../../l10n/l10n.dart';

/// A peso input that opens the number pad and rejects anything that is not a
/// valid amount, so nobody can type their way into a broken total.
class AmountField extends StatelessWidget {
  const AmountField({
    super.key,
    required this.controller,
    this.label,
    this.autofocus = false,
    this.onSubmitted,
    this.validator,
  });

  final TextEditingController controller;

  /// Defaults to the word for "Amount" in the owner's language.
  final String? label;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.done,
      onFieldSubmitted: onSubmitted,
      validator:
          validator ??
          (raw) => _defaultValidator(raw, context.l10n.commonEnterAmount),
      style: AppTypography.money(Theme.of(context).colorScheme.onSurface, 28),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      decoration: InputDecoration(
        labelText: label ?? context.l10n.commonAmount,
        prefixText: '₱ ',
        prefixStyle: AppTypography.money(
          Theme.of(context).colorScheme.onSurfaceVariant,
          28,
        ),
      ),
    );
  }

  static String? _defaultValidator(String? raw, String message) {
    final value = double.tryParse(raw ?? '');
    if (value == null || value <= 0) return message;
    return null;
  }
}
