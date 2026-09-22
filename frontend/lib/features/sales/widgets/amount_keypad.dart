import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../l10n/l10n.dart';

/// A large on-screen keypad. The system keyboard is slower to reach and its
/// keys are smaller, and speed of entry is the whole point of this screen.
///
/// Keys stretch to use whatever height the screen can spare, between the
/// minimum comfortable tap target and a cap that stops them turning into
/// slabs on a tablet.
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

  static const double maxKeyHeight = 84;

  static const List<List<String>> _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['.', '0', '<'],
  ];

  /// Height at which every key sits at the minimum tap target.
  static const double minimumHeight =
      _rowCount * AppSpacing.minTapTarget + (_rowCount - 1) * AppSpacing.sm;

  static const int _rowCount = 4;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: minimumHeight,
        maxHeight: _rowCount * maxKeyHeight + (_rowCount - 1) * AppSpacing.sm,
      ),
      child: Column(
        children: [
          for (var row = 0; row < _rows.length; row++) ...[
            if (row > 0) const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var column = 0; column < 3; column++) ...[
                    if (column > 0) const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _KeypadButton(
                        label: _rows[row][column],
                        onPressed: () => _rows[row][column] == '<'
                            ? onBackspace()
                            : onDigit(_rows[row][column]),
                        onLongPress: _rows[row][column] == '<' ? onClear : null,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
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
    final l10n = context.l10n;

    // Screen readers announce each key; "<" and "." alone would be read as
    // symbols, so they get words.
    return Semantics(
      button: true,
      label: switch (label) {
        '<' => l10n.keypadBackspace,
        '.' => l10n.keypadDecimal,
        _ => label,
      },
      onLongPressHint: onLongPress == null ? null : l10n.keypadBackspaceHint,
      excludeSemantics: true,
      child: Material(
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
      ),
    );
  }
}
