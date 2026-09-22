import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitaza_app/core/theme/app_palette.dart';
import 'package:kitaza_app/features/splash/splash_screen.dart';
import 'package:kitaza_app/shared/widgets/kitaza_logo.dart';

void main() {
  Widget host({Brightness brightness = Brightness.light}) {
    return MediaQuery(
      data: MediaQueryData(platformBrightness: brightness),
      child: const Directionality(
        textDirection: TextDirection.ltr,
        child: SplashScreen(),
      ),
    );
  }

  testWidgets('shows the logo at the same size as the native splash', (
    tester,
  ) async {
    await tester.pumpWidget(host());

    final logo = tester.widget<KitazaLogo>(find.byType(KitazaLogo));
    expect(logo.size, SplashScreen.logoSize);
  });

  testWidgets('matches the native splash background in both brightnesses', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    expect(
      tester.widget<ColoredBox>(find.byType(ColoredBox).first).color,
      AppPalette.canvasLight,
    );

    await tester.pumpWidget(host(brightness: Brightness.dark));
    expect(
      tester.widget<ColoredBox>(find.byType(ColoredBox).first).color,
      AppPalette.canvasDark,
    );
  });

  testWidgets('only shows a spinner if startup is genuinely slow', (
    tester,
  ) async {
    await tester.pumpWidget(host());

    double spinnerOpacity() =>
        tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity;

    expect(spinnerOpacity(), 0);

    await tester.pump(const Duration(milliseconds: 800));
    expect(spinnerOpacity(), 1);
  });
}
