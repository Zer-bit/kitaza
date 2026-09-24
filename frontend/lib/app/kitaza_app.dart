import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/config/app_config.dart';
import '../core/localization/locale_controller.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_controller.dart';
import '../core/theme/theme_reveal.dart';
import '../l10n/l10n.dart';
import 'app_router.dart';

class KitazaApp extends ConsumerWidget {
  const KitazaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chosenLocale = ref.watch(localeControllerProvider);

    return MaterialApp.router(
      title: AppConfig.appName,
      locale: chosenLocale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeListResolutionCallback: (preferred, _) =>
          chosenLocale ?? LocaleController.resolve(preferred),
      debugShowCheckedModeBanner: false,
      routerConfig: ref.watch(appRouterProvider),
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeControllerProvider),
      // No blend between themes: ThemeReveal switches instantly under a
      // picture of the old screen. Blending would rebuild the whole app on
      // every frame of the fade.
      themeAnimationDuration: Duration.zero,
      builder: (context, child) {
        // Dates and month names outside Material widgets follow this.
        Intl.defaultLocale = Localizations.localeOf(context).toLanguageTag();

        // Honour the system font size, but stop at a scale that would break
        // the money layouts.
        final scale = MediaQuery.textScalerOf(context)
            .clamp(minScaleFactor: 1.0, maxScaleFactor: 1.4);

        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: scale),
          child: ThemeReveal(child: child ?? const SizedBox.shrink()),
        );
      },
    );
  }
}
