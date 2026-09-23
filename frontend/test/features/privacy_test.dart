import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitaza_app/app/route_paths.dart';
import 'package:kitaza_app/data/models/auth_session.dart';
import 'package:kitaza_app/data/models/legal_document.dart';
import 'package:kitaza_app/data/models/privacy_state.dart';
import 'package:kitaza_app/data/remote/privacy_api.dart';
import 'package:kitaza_app/features/authentication/auth_controller.dart';
import 'package:kitaza_app/features/authentication/sign_up_screen.dart';
import 'package:kitaza_app/features/legal/legal_screen.dart';
import 'package:kitaza_app/features/privacy/close_account_screen.dart';
import 'package:kitaza_app/features/privacy/privacy_screen.dart';
import 'package:kitaza_app/features/settings/settings_screen.dart';

import '../support/app_harness.dart';
import '../support/privacy_fakes.dart';
import '../support/team_fakes.dart';

void main() {
  late FakePrivacyApi privacy;

  setUp(() => privacy = FakePrivacyApi());

  Map<String, WidgetBuilder> privacyScreens() => {
    RoutePaths.privacy: (_) => const PrivacyScreen(),
    RoutePaths.closeAccount: (_) => const CloseAccountScreen(),
    RoutePaths.settings: (_) => const SettingsScreen(),
    for (final document in LegalDocument.values)
      RoutePaths.legalFor(document): (_) => LegalScreen(document: document),
  };

  Future<TestPhone> open(
    WidgetTester tester, {
    AuthSession? session,
    bool cloud = false,
    Locale locale = const Locale('en'),
    Map<String, WidgetBuilder> extraScreens = const {},
  }) => TestPhone.open(
    tester,
    locale: locale,
    cloud: cloud,
    screens: {...privacyScreens(), ...extraScreens},
    overrides: (_, _) => [
      privacyApiProvider.overrideWithValue(privacy),
      if (session != null) currentSessionProvider.overrideWithValue(session),
    ],
  );

  group('the documents', () {
    testWidgets('the privacy notice says what is never collected', (
      tester,
    ) async {
      final phone = await open(tester);
      await phone.goTo(
        tester,
        RoutePaths.legalFor(LegalDocument.privacyNotice),
      );

      expect(find.text('What we never hold'), findsOneWidget);
      expect(
        find.textContaining('We do not record your customers'),
        findsOneWidget,
      );
      expect(
        find.textContaining('never see card numbers'),
        findsOneWidget,
        reason: 'payment details go to the gateway, not to us',
      );
    });

    testWidgets('it names the rights the law gives, and the regulator', (
      tester,
    ) async {
      final phone = await open(tester);
      await phone.goTo(
        tester,
        RoutePaths.legalFor(LegalDocument.privacyNotice),
      );

      await tester.scrollUntilVisible(find.text('Your rights'), 300);
      expect(find.textContaining('National Privacy Commission'), findsWidgets);
      expect(find.textContaining('privacy.gov.ph'), findsWidgets);
    });

    testWidgets('the terms say what Kitaza is not', (tester) async {
      final phone = await open(tester);
      await phone.goTo(tester, RoutePaths.legalFor(LegalDocument.terms));

      expect(find.text('What Kitaza is not'), findsOneWidget);
      expect(
        find.textContaining('not a BIR filing tool'),
        findsOneWidget,
        reason: 'promising tax compliance would be the dangerous claim',
      );
    });

    testWidgets('and both are readable in Filipino', (tester) async {
      final phone = await open(tester, locale: const Locale('fil'));
      await phone.goTo(
        tester,
        RoutePaths.legalFor(LegalDocument.privacyNotice),
      );

      expect(find.text('Paunawa sa privacy'), findsWidgets);
      expect(
        find.textContaining('Hindi namin itinatala ang mga suki mo'),
        findsOneWidget,
      );
    });
  });

  group('agreeing before an account exists', () {
    testWidgets('sign-up will not go through without agreeing', (tester) async {
      final phone = await open(
        tester,
        extraScreens: {RoutePaths.signUp: (_) => const SignUpScreen()},
      );
      await phone.goTo(tester, RoutePaths.signUp);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Store name'),
        "Nena's Store",
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Your name'),
        'Nena Reyes',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'nena@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'a-good-password',
      );
      await phone.tapAfterScrolling(tester, find.text('Create account'));

      expect(
        find.text('Please read and agree to both before continuing.'),
        findsOneWidget,
      );
    });

    testWidgets('the box starts unticked, and the documents open from it', (
      tester,
    ) async {
      final phone = await open(
        tester,
        extraScreens: {RoutePaths.signUp: (_) => const SignUpScreen()},
      );
      await phone.goTo(tester, RoutePaths.signUp);

      // The form is one scroll view, so everything in it is built.
      final box = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(box.value, isFalse, reason: 'pre-ticked consent is not consent');

      await phone.tapAfterScrolling(tester, find.text('Privacy notice'));
      expect(find.text('Who holds your records'), findsOneWidget);
    });
  });

  group('your data and privacy', () {
    testWidgets('an offline store is told its records never left the phone', (
      tester,
    ) async {
      final phone = await open(tester);
      await phone.goTo(tester, RoutePaths.privacy);

      expect(
        find.textContaining('On this phone only'),
        findsOneWidget,
        reason: 'an offline store must be told plainly that we hold nothing',
      );
      expect(
        find.text('Close my account'),
        findsNothing,
        reason: 'there is no account on a server to close',
      );
      expect(find.text('Nothing to close'), findsOneWidget);
    });

    testWidgets('a cloud store can close its account', (tester) async {
      final phone = await open(tester, cloud: true, session: cloudOwner());
      await phone.goTo(tester, RoutePaths.privacy);

      await phone.tapAfterScrolling(
        tester,
        find.text('Delete everything we hold about you'),
      );

      expect(
        find.textContaining('will be deleted from our servers'),
        findsOneWidget,
      );
      expect(find.textContaining('30 days'), findsOneWidget);
    });

    testWidgets('closing asks for the store name, not just a tap', (
      tester,
    ) async {
      final phone = await open(tester, cloud: true, session: cloudOwner());
      await phone.goTo(tester, RoutePaths.closeAccount);

      await phone.tapAfterScrolling(
        tester,
        find.widgetWithText(FilledButton, 'Close my account'),
      );

      expect(privacy.deletionRequests, 0);
      expect(
        find.text('That does not match the name of your store.'),
        findsOneWidget,
      );
    });

    testWidgets('and goes through once the name matches', (tester) async {
      final phone = await open(tester, cloud: true, session: cloudOwner());
      await phone.goTo(tester, RoutePaths.closeAccount);

      await tester.enterText(find.byType(TextFormField), 'Test Store');
      await phone.tapAfterScrolling(
        tester,
        find.widgetWithText(FilledButton, 'Close my account'),
      );

      expect(privacy.deletionRequests, 1);
    });

    testWidgets('a deletion already asked for can be called off', (
      tester,
    ) async {
      privacy.reported = PrivacyState(
        deletion: PendingDeletion(
          requestedAt: DateTime(2026, 9, 1),
          deletesAt: DateTime(2026, 10, 1),
        ),
      );
      final phone = await open(tester, cloud: true, session: cloudOwner());
      await phone.goTo(tester, RoutePaths.closeAccount);

      expect(find.textContaining('1 October 2026'), findsWidgets);
      await phone.tapAfterScrolling(tester, find.text('Keep my account'));

      expect(privacy.cancellations, 1);
    });

    testWidgets('settings leads here', (tester) async {
      final phone = await open(tester);
      await phone.goTo(tester, RoutePaths.settings);

      await phone.tapAfterScrolling(tester, find.text('Your data and privacy'));

      expect(find.text('Where your records are'), findsOneWidget);
    });
  });
}
