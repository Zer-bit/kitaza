import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';

class ThemeModeSelector extends StatefulWidget {
  const ThemeModeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final ThemeMode selected;

  /// [from] is where the finger landed, in screen coordinates, so the new
  /// theme can open out from under it.
  final void Function(ThemeMode mode, Offset? from) onChanged;

  @override
  State<ThemeModeSelector> createState() => _ThemeModeSelectorState();
}

class _ThemeModeSelectorState extends State<ThemeModeSelector> {
  Offset? _lastTouch;

  @override
  Widget build(BuildContext context) {
    // The segmented button reports what was chosen but not where, so the
    // touch is noted on the way down.
    return Listener(
      onPointerDown: (event) => _lastTouch = event.position,
      child: SegmentedButton<ThemeMode>(
        segments: [
          ButtonSegment(
            value: ThemeMode.light,
            icon: const Icon(Icons.light_mode_outlined),
            label: Text(context.l10n.settingsThemeLight),
          ),
          ButtonSegment(
            value: ThemeMode.system,
            icon: const Icon(Icons.brightness_auto_outlined),
            label: Text(context.l10n.settingsThemeAuto),
          ),
          ButtonSegment(
            value: ThemeMode.dark,
            icon: const Icon(Icons.dark_mode_outlined),
            label: Text(context.l10n.settingsThemeDark),
          ),
        ],
        selected: {widget.selected},
        showSelectedIcon: false,
        onSelectionChanged: (selection) =>
            widget.onChanged(selection.first, _lastTouch),
      ),
    );
  }
}
