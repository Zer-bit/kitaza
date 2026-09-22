import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kitaza_app/features/authentication/welcome_screen.dart';

import '../support/localized.dart';

void main() {
  Widget welcome(Locale locale) {
    // The welcome screen navigates with go_router, so it needs one around it.
    final router = GoRouter(
      routes: [GoRoute(path: '/', builder: (_, _) => const WelcomeScreen())],
    );
    return localized(
      Builder(builder: (_) => Router.withConfig(config: router)),
      locale: locale,
    );
  }

  testWidgets('the first screen appears in English', (tester) async {
    await tester.pumpWidget(welcome(const Locale('en')));
    await tester.pumpAndSettle();

    expect(find.text('Just this phone'), findsOneWidget);
    expect(find.text('Save to the cloud'), findsOneWidget);
  });

  testWidgets('and in Filipino', (tester) async {
    await tester.pumpWidget(welcome(const Locale('fil')));
    await tester.pumpAndSettle();

    expect(find.text('Sa phone lang na ito'), findsOneWidget);
    expect(find.text('I-save sa cloud'), findsOneWidget);
    expect(find.text('Just this phone'), findsNothing);
  });
}
