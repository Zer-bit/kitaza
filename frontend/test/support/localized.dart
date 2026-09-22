import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:kitaza_app/core/theme/app_theme.dart';
import 'package:kitaza_app/l10n/l10n.dart';

const localizationDelegates = <LocalizationsDelegate<Object>>[
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

/// Wraps a widget the way the real app does: theme, translations, and a
/// chosen language.
Widget localized(
  Widget child, {
  Locale locale = const Locale('en'),
  Brightness platformBrightness = Brightness.light,
}) {
  return MediaQuery(
    data: MediaQueryData(platformBrightness: platformBrightness),
    child: MaterialApp(
      theme: AppTheme.light(),
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: localizationDelegates,
      home: child,
    ),
  );
}
