import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitaza_app/core/storage/preferences_store.dart';
import 'package:kitaza_app/core/theme/app_theme.dart';
import 'package:kitaza_app/core/theme/theme_controller.dart';
import 'package:kitaza_app/core/theme/theme_reveal.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Counts how often something that depends on the theme is rebuilt, which is
/// what makes a theme change expensive.
class _ThemeProbe extends StatelessWidget {
  const _ThemeProbe({required this.onBuild});

  final VoidCallback onBuild;

  @override
  Widget build(BuildContext context) {
    onBuild();
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: const SizedBox.expand(),
    );
  }
}

void main() {
  late int builds;
  late WidgetRef ref;
  late BuildContext screen;

  /// The app root as it really is: themes, no built-in blend, and the reveal
  /// wrapped around the navigator.
  Future<void> openApp(
    WidgetTester tester, {
    ThemeMode start = ThemeMode.light,
    bool reduceMotion = false,
    Duration blend = Duration.zero,
    bool withReveal = true,
  }) async {
    SharedPreferences.setMockInitialValues({'kitaza.theme_mode': start.name});
    final preferences = PreferencesStore(await SharedPreferences.getInstance());
    builds = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [preferencesStoreProvider.overrideWithValue(preferences)],
        child: Consumer(
          builder: (context, widgetRef, _) {
            ref = widgetRef;
            return MaterialApp(
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode: widgetRef.watch(themeControllerProvider),
              themeAnimationDuration: blend,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  disableAnimations: reduceMotion,
                  platformBrightness: Brightness.light,
                ),
                child: withReveal ? ThemeReveal(child: child!) : child!,
              ),
              home: Builder(
                builder: (context) {
                  screen = context;
                  return _ThemeProbe(onBuild: () => builds++);
                },
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    builds = 0;
  }

  Brightness shown(WidgetTester tester) =>
      Theme.of(tester.element(find.byType(_ThemeProbe))).brightness;

  Finder revealOverlay() => find.byWidgetPredicate(
    (widget) =>
        widget is CustomPaint &&
        widget.painter.runtimeType.toString() == '_UncoverPainter',
  );

  testWidgets('the new theme is fully in place from the first frame', (
    tester,
  ) async {
    await openApp(tester);

    ThemeReveal.switchTo(
      screen,
      ref,
      ThemeMode.dark,
      from: const Offset(200, 300),
    );
    await tester.pump();

    expect(
      shown(tester),
      Brightness.dark,
      reason: 'no half-way colours for anything to jump through',
    );
    expect(revealOverlay(), findsOneWidget, reason: 'the old screen on top');
  });

  testWidgets('the circle finishes and the old screen is let go', (
    tester,
  ) async {
    await openApp(tester);

    ThemeReveal.switchTo(screen, ref, ThemeMode.dark, from: Offset.zero);
    await tester.pump();
    await tester.pump(ThemeReveal.duration + const Duration(milliseconds: 50));

    expect(revealOverlay(), findsNothing);
    expect(shown(tester), Brightness.dark);
  });

  testWidgets('the app underneath is rebuilt once, not on every frame', (
    tester,
  ) async {
    await openApp(tester);

    ThemeReveal.switchTo(screen, ref, ThemeMode.dark, from: Offset.zero);
    for (var frame = 0; frame < 30; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(
      builds,
      1,
      reason: 'only the picture of the old screen moves; the app does not',
    );
  });

  testWidgets('the blend it replaces rebuilt the app on every frame', (
    tester,
  ) async {
    // Kept as the measurement behind the change: Flutter's own theme fade,
    // at the 280 ms the app used before.
    await openApp(
      tester,
      withReveal: false,
      blend: const Duration(milliseconds: 280),
    );

    ref.read(themeControllerProvider.notifier).select(ThemeMode.dark);
    for (var frame = 0; frame < 30; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(builds, greaterThan(15));
  });

  testWidgets('a choice that looks the same on screen reveals nothing', (
    tester,
  ) async {
    // Auto on a phone that is already light is still light.
    await openApp(tester);

    ThemeReveal.switchTo(screen, ref, ThemeMode.system, from: Offset.zero);
    await tester.pump();

    expect(revealOverlay(), findsNothing);
    expect(ref.read(themeControllerProvider), ThemeMode.system);
  });

  testWidgets('with animations turned off on the phone, it simply switches', (
    tester,
  ) async {
    await openApp(tester, reduceMotion: true);

    ThemeReveal.switchTo(screen, ref, ThemeMode.dark, from: Offset.zero);
    await tester.pump();

    expect(revealOverlay(), findsNothing);
    expect(shown(tester), Brightness.dark);
  });

  testWidgets('the choice is still saved for next time', (tester) async {
    await openApp(tester);

    ThemeReveal.switchTo(screen, ref, ThemeMode.dark, from: Offset.zero);
    await tester.pumpAndSettle();

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('kitaza.theme_mode'), 'dark');
  });

  testWidgets('taps go through to the new screen while the circle grows', (
    tester,
  ) async {
    await openApp(tester);

    ThemeReveal.switchTo(screen, ref, ThemeMode.dark, from: Offset.zero);
    await tester.pump(const Duration(milliseconds: 100));

    final blocking = find.ancestor(
      of: revealOverlay(),
      matching: find.byType(IgnorePointer),
    );
    expect(
      tester.widget<IgnorePointer>(blocking.first).ignoring,
      isTrue,
      reason: 'an owner who taps again straight away must not be ignored',
    );
  });
}
