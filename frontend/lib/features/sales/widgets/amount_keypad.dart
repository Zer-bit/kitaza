import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

/// A large on-screen keypad. The system keyboard is slower to reach and its
/// keys are smaller, and speed of entry is the whole point of this screen.
class AmountKeypad extends StatelessWidget {
  const AmountKeypad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    required this.onClear,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onClear;

  static const List<String> _keys = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '.',
    '0',
    '<',
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1.9,
      children: [
        for (final key in _keys)
          _KeypadButton(
            label: key,
            onPressed: () => key == '<' ? onBackspace() : onDigit(key),
            onLongPress: key == '<' ? onClear : null,
          ),
      ],
    );
  }
}

class _KeypadButton extends StatelessWidget {
  const _KeypadButton({
    required this.label,
    required this.onPressed,
    this.onLongPress,
  });

  final String label;
  final VoidCallback onPressed;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBackspace = label == '<';

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: AppRadius.fieldAll,
      child: InkWell(
        onTap: onPressed,
        onLongPress: onLongPress,
        borderRadius: AppRadius.fieldAll,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: AppRadius.fieldAll,
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: isBackspace
              ? Icon(
                  Icons.backspace_outlined,
                  color: theme.colorScheme.onSurface,
                )
              : Text(label, style: theme.textTheme.headlineSmall),
        ),
      ),
    );
  }
}
