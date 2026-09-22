import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/locale_controller.dart';
import '../../../l10n/l10n.dart';

/// English, Filipino, or whatever the phone is set to. Each option is shown
/// in its own language, so someone who cannot read the current one can still
/// find theirs.
class LanguageSelector extends ConsumerWidget {
  const LanguageSelector({super.key});

  static const _auto = 'auto';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final chosen = ref.watch(localeControllerProvider)?.languageCode ?? _auto;

    return SegmentedButton<String>(
      segments: [
        ButtonSegment(value: _auto, label: Text(l10n.settingsLanguageAuto)),
        const ButtonSegment(value: 'en', label: Text('English')),
        const ButtonSegment(value: 'fil', label: Text('Filipino')),
      ],
      selected: {chosen},
      showSelectedIcon: false,
      onSelectionChanged: (selection) {
        final code = selection.first;
        ref
            .read(localeControllerProvider.notifier)
            .select(code == _auto ? null : Locale(code));
      },
    );
  }
}
