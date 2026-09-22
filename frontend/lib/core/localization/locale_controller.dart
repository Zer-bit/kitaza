import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/preferences_store.dart';

/// The owner's language choice. Null means "follow the phone".
class LocaleController extends Notifier<Locale?> {
  static const Locale english = Locale('en');
  static const Locale filipino = Locale('fil');

  @override
  Locale? build() =>
      switch (ref.read(preferencesStoreProvider).readLanguage()) {
        'en' => english,
        'fil' => filipino,
        _ => null,
      };

  Future<void> select(Locale? locale) async {
    state = locale;
    await ref
        .read(preferencesStoreProvider)
        .writeLanguage(locale?.languageCode);
  }

  /// Picks the app language for the phone's settings. Older Android versions
  /// report Filipino as `tl`, so both codes lead to the Filipino text; any
  /// other language falls back to English.
  static Locale resolve(List<Locale>? preferred) {
    for (final locale in preferred ?? const <Locale>[]) {
      switch (locale.languageCode) {
        case 'fil' || 'tl':
          return filipino;
        case 'en':
          return english;
      }
    }
    return english;
  }
}

final localeControllerProvider = NotifierProvider<LocaleController, Locale?>(
  LocaleController.new,
);
