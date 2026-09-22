import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_palette.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Both themes are built from one description so light and dark never drift
/// apart. Every colour below has a deliberate counterpart on the other side.
abstract final class AppTheme {
  static ThemeData light() => _build(
    brightness: Brightness.light,
    scheme: const ColorScheme.light(
      primary: AppPalette.teal,
      onPrimary: Colors.white,
      primaryContainer: AppPalette.tealSoft,
      onPrimaryContainer: AppPalette.tealDeep,
      secondary: AppPalette.amber,
      onSecondary: Colors.white,
      secondaryContainer: AppPalette.amberSoft,
      onSecondaryContainer: Color(0xFF6B3A05),
      surface: AppPalette.surfaceLight,
      onSurface: AppPalette.inkStrong,
      onSurfaceVariant: AppPalette.inkMuted,
      outline: AppPalette.line,
      error: AppPalette.alert,
      onError: Colors.white,
    ),
    canvas: AppPalette.canvasLight,
    ink: AppPalette.inkStrong,
    muted: AppPalette.inkMuted,
    line: AppPalette.line,
  );

  static ThemeData dark() => _build(
    brightness: Brightness.dark,
    scheme: const ColorScheme.dark(
      primary: AppPalette.tealBright,
      onPrimary: Color(0xFF00322D),
      primaryContainer: Color(0xFF12453F),
      onPrimaryContainer: AppPalette.tealBright,
      secondary: AppPalette.amberBright,
      onSecondary: Color(0xFF3A2500),
      secondaryContainer: Color(0xFF4A3208),
      onSecondaryContainer: AppPalette.amberBright,
      surface: AppPalette.surfaceDark,
      onSurface: AppPalette.inkOnDark,
      onSurfaceVariant: AppPalette.inkMutedOnDark,
      outline: AppPalette.lineDark,
      error: AppPalette.alertDark,
      onError: Color(0xFF3A0A0A),
    ),
    canvas: AppPalette.canvasDark,
    ink: AppPalette.inkOnDark,
    muted: AppPalette.inkMutedOnDark,
    line: AppPalette.lineDark,
  );

  static ThemeData _build({
    required Brightness brightness,
    required ColorScheme scheme,
    required Color canvas,
    required Color ink,
    required Color muted,
    required Color line,
  }) {
    final text = AppTypography.forColor(ink, muted);
    final isLight = brightness == Brightness.light;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: canvas,
      textTheme: text,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      // iOS and macOS are left on Flutter's own Cupertino default, which is
      // what those platforms' users expect. Everywhere else gets the Material 3
      // fade-through, which is cheaper to render than a shadowed slide.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: canvas,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: text.headlineSmall,
        systemOverlayStyle: isLight
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardAll,
          side: BorderSide(color: line),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSpacing.minTapTarget),
          textStyle: text.labelLarge,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.fieldAll),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSpacing.minTapTarget),
          textStyle: text.labelLarge,
          side: BorderSide(color: line, width: 1.5),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.fieldAll),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(textStyle: text.labelLarge),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight
            ? AppPalette.canvasLight
            : AppPalette.surfaceDarkRaised,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        labelStyle: text.bodyMedium?.copyWith(color: muted),
        hintStyle: text.bodyMedium?.copyWith(color: muted),
        border: OutlineInputBorder(
          borderRadius: AppRadius.fieldAll,
          borderSide: BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.fieldAll,
          borderSide: BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.fieldAll,
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.fieldAll,
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isLight
            ? AppPalette.canvasLight
            : AppPalette.surfaceDarkRaised,
        selectedColor: scheme.primaryContainer,
        labelStyle: text.labelMedium!.copyWith(color: ink),
        side: BorderSide(color: line),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.pillAll),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        height: 72,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStatePropertyAll(text.labelMedium),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        selectedLabelTextStyle: text.labelMedium!.copyWith(color: ink),
        unselectedLabelTextStyle: text.labelMedium,
      ),
      dividerTheme: DividerThemeData(color: line, space: 1, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isLight
            ? AppPalette.inkStrong
            : AppPalette.surfaceDarkRaised,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: isLight ? Colors.white : AppPalette.inkOnDark,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.fieldAll),
      ),
      listTileTheme: ListTileThemeData(
        titleTextStyle: text.titleMedium,
        subtitleTextStyle: text.bodySmall,
        minVerticalPadding: AppSpacing.md,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.fieldAll),
      ),
    );
  }
}
