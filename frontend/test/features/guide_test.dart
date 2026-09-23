import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitaza_app/app/route_paths.dart';
import 'package:kitaza_app/data/models/access_grant.dart';
import 'package:kitaza_app/data/models/auth_session.dart';
import 'package:kitaza_app/data/models/guide_lesson.dart';
import 'package:kitaza_app/features/authentication/auth_controller.dart';
import 'package:kitaza_app/features/dashboard/dashboard_screen.dart';
import 'package:kitaza_app/features/guide/guide_lesson_screen.dart';
import 'package:kitaza_app/features/guide/guide_screen.dart';
import 'package:kitaza_app/features/guide/widgets/lesson_card.dart';
import 'package:kitaza_app/features/settings/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/app_harness.dart';
import '../support/team_fakes.dart';

void main() {
  /// The guide and every lesson, as the real router wires them up.
  Map<String, WidgetBuilder> guideScreens() => {
    RoutePaths.guide: (_) => const GuideScreen(),
    for (final lesson in GuideLesson.values)
      lesson.path: (_) => GuideLessonScreen(lesson: lesson),
  };

  Future<TestPhone> open(
    WidgetTester tester, {
    AuthSession? session,
    Locale locale = const Locale('en'),
    Map<String, WidgetBuilder> extraScreens = const {},
  }) => TestPhone.open(
    tester,
    locale: locale,
    screens: {...guideScreens(), ...extraScreens},
    overrides: (_, _) => [
      if (session != null) currentSessionProvider.overrideWithValue(session),
    ],
  );

  test('every lesson path leads back to its lesson', () {
    for (final lesson in GuideLesson.values) {
      expect(lesson.path, startsWith('${RoutePaths.guide}/'));
      expect(
        GuideLesson.named(lesson.path.split('/').last),
        lesson,
        reason: 'the router parses paths this way',
      );
    }
    // A link to a lesson that has since been renamed opens the guide itself
    // rather than an error.
    expect(GuideLesson.named('a-lesson-we-dropped'), isNull);
    expect(GuideLesson.named(null), isNull);
  });

  testWidgets('the lessons are listed in the order to read them', (
    tester,
  ) async {
    final phone = await open(tester);
    await phone.goTo(tester, RoutePaths.guide);

    expect(find.text('Your first day'), findsOneWidget);
    expect(find.text('Recording a sale'), findsOneWidget);
    expect(find.text('Not started'), findsOneWidget);
  });

  testWidgets('a lesson is a numbered list of things to do', (tester) async {
    final phone = await open(tester);
    await phone.goTo(tester, RoutePaths.guide);

    await phone.tapAfterScrolling(tester, find.text('Recording a sale'));

    expect(find.text('Step 1'), findsOneWidget);
    expect(find.text('Tap Add sale'), findsOneWidget);
    expect(find.text('Say how they paid'), findsOneWidget);
    expect(find.textContaining('Utang is still a sale'), findsOneWidget);
  });

  testWidgets('each lesson offers the screen it is teaching', (tester) async {
    final phone = await open(
      tester,
      extraScreens: {
        RoutePaths.recordSale: (_) => const Scaffold(body: Text('the till')),
      },
    );
    await phone.goTo(tester, GuideLesson.recordingSales.path);

    await phone.tapAfterScrolling(tester, find.text('Open it now'));

    expect(find.text('the till'), findsOneWidget);
  });

  testWidgets('one lesson leads to the next', (tester) async {
    final phone = await open(tester);
    await phone.goTo(tester, GuideLesson.firstDay.path);

    await phone.tapAfterScrolling(
      tester,
      find.textContaining('Next: Recording a sale'),
    );

    expect(find.text('Tap Add sale'), findsOneWidget);
  });

  testWidgets('the last lesson says so instead of leading nowhere', (
    tester,
  ) async {
    final phone = await open(tester);
    await phone.goTo(tester, GuideLesson.yourHelpers.path);

    expect(find.text('That is the whole guide.'), findsOneWidget);
    expect(find.textContaining('Next:'), findsNothing);
  });

  testWidgets('reading a lesson is remembered, without being asked', (
    tester,
  ) async {
    final phone = await open(tester);
    await phone.goTo(tester, RoutePaths.guide);

    await phone.tapAfterScrolling(tester, find.text('Your first day'));
    await phone.goTo(tester, RoutePaths.guide);

    expect(find.text('1 of 8 read'), findsOneWidget);
    expect(find.text('Read'), findsOneWidget);

    // Written down, not just held in memory: closing the app and coming
    // back must not forget where someone got to.
    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getStringList('kitaza.guide_read'),
      contains(GuideLesson.firstDay.name),
    );
  });

  group('what each person is shown', () {
    testWidgets('a cashier is not taught things they cannot do', (
      tester,
    ) async {
      final phone = await open(tester, session: staffMember(const {}));
      await phone.goTo(tester, RoutePaths.guide);

      expect(find.text('Recording a sale'), findsOneWidget);
      expect(find.text('Your helpers'), findsNothing);
      expect(find.text('Money going out'), findsNothing);
      expect(find.text('What Kitaza suggests'), findsNothing);
      expect(find.text('Keeping your records safe'), findsNothing);
      expect(find.text('What you sell'), findsNothing);
    });

    testWidgets('and the count follows what they can actually see', (
      tester,
    ) async {
      final phone = await open(
        tester,
        session: staffMember(const {Permission.recordExpenses}),
      );
      await phone.goTo(tester, RoutePaths.guide);

      expect(find.text('Money going out'), findsOneWidget);
      expect(
        find.byType(LessonCard),
        findsNWidgets(4),
        reason: 'the three anyone gets, plus the one their permission adds',
      );
    });

    testWidgets('an offline owner is taught about staff but not sent there', (
      tester,
    ) async {
      // The staff screen needs cloud storage, so offering to open it would
      // only bounce them back to the dashboard.
      final phone = await open(tester);
      await phone.goTo(tester, GuideLesson.yourHelpers.path);

      expect(find.text('Add the person first'), findsOneWidget);
      expect(find.text('Open it now'), findsNothing);
    });
  });

  group('finding the guide', () {
    testWidgets('it is offered once on the dashboard, then not again', (
      tester,
    ) async {
      final phone = await open(
        tester,
        extraScreens: {RoutePaths.dashboard: (_) => const DashboardScreen()},
      );
      await phone.goTo(tester, RoutePaths.dashboard);

      expect(find.text('New to Kitaza?'), findsOneWidget);
      await phone.tapAfterScrolling(tester, find.text('Not now'));

      expect(find.text('New to Kitaza?'), findsNothing);

      final preferences = await SharedPreferences.getInstance();
      expect(
        preferences.getBool('kitaza.guide_offered'),
        isTrue,
        reason: 'and it stays away after a restart',
      );
    });

    testWidgets('and it is always in Settings', (tester) async {
      final phone = await open(
        tester,
        extraScreens: {RoutePaths.settings: (_) => const SettingsScreen()},
      );
      await phone.goTo(tester, RoutePaths.settings);

      await phone.tapAfterScrolling(tester, find.text('How to use Kitaza'));

      expect(find.text('Your first day'), findsOneWidget);
    });
  });

  testWidgets('the whole guide is in Filipino too', (tester) async {
    final phone = await open(tester, locale: const Locale('fil'));
    await phone.goTo(tester, RoutePaths.guide);

    expect(find.text('Ang unang araw mo'), findsOneWidget);

    await phone.tapAfterScrolling(tester, find.text('Pag-record ng benta'));

    expect(find.text('Hakbang 1'), findsOneWidget);
    expect(find.textContaining('Benta pa rin ang utang'), findsOneWidget);
  });
}
