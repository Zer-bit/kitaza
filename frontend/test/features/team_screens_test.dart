import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitaza_app/app/route_paths.dart';
import 'package:kitaza_app/data/models/access_grant.dart';
import 'package:kitaza_app/data/models/activity_event.dart';
import 'package:kitaza_app/data/models/staff_member.dart';
import 'package:kitaza_app/data/remote/team_api.dart';
import 'package:kitaza_app/features/authentication/auth_controller.dart';
import 'package:kitaza_app/features/team/activity_screen.dart';
import 'package:kitaza_app/features/team/devices_screen.dart';
import 'package:kitaza_app/features/team/staff_screen.dart';
import 'package:kitaza_app/l10n/l10n.dart';

import '../support/app_harness.dart';
import '../support/team_fakes.dart';

void main() {
  late FakeTeamApi api;

  setUp(() => api = FakeTeamApi());

  Future<TestPhone> open(
    WidgetTester tester,
    String path,
    WidgetBuilder screen, {
    Locale locale = const Locale('en'),
  }) async {
    final phone = await TestPhone.open(
      tester,
      screens: {path: screen},
      locale: locale,
      overrides: (_, _) => [
        currentSessionProvider.overrideWithValue(cloudOwner()),
        teamApiProvider.overrideWithValue(api),
      ],
    );
    await phone.goTo(tester, path);
    return phone;
  }

  group('staff', () {
    testWidgets('adding a cashier who may also record expenses gives a code', (
      tester,
    ) async {
      final phone = await open(
        tester,
        RoutePaths.staff,
        (_) => const StaffScreen(),
      );
      expect(find.text('No staff yet'), findsOneWidget);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Liza');
      await tester.tap(find.text('Record expenses'));
      await tester.pumpAndSettle();
      await phone.tapAfterScrolling(
        tester,
        find.widgetWithText(FilledButton, 'Add staff'),
      );

      expect(api.added.single.name, 'Liza');
      expect(api.added.single.permissions, {Permission.recordExpenses});
      expect(find.text('Join code for Liza'), findsOneWidget);
      expect(find.text('ABCDE-FGHJK'), findsOneWidget);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.text('Liza'), findsOneWidget);
      expect(find.textContaining('Sells, expenses'), findsOneWidget);
    });

    testWidgets('a name is required', (tester) async {
      final phone = await open(
        tester,
        RoutePaths.staff,
        (_) => const StaffScreen(),
      );

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await phone.tapAfterScrolling(
        tester,
        find.widgetWithText(FilledButton, 'Add staff'),
      );

      expect(find.text('Enter a name'), findsOneWidget);
      expect(api.added, isEmpty);
    });

    testWidgets('removing someone warns about their unsent sales first', (
      tester,
    ) async {
      api.staffList.add(
        const StaffMember(
          id: 'liza',
          displayName: 'Liza',
          permissions: {},
          signedInDevices: 1,
        ),
      );
      final phone = await open(
        tester,
        RoutePaths.staff,
        (_) => const StaffScreen(),
      );
      expect(find.textContaining('Signed in on 1 phone'), findsOneWidget);

      await tester.tap(find.text('Liza'));
      await tester.pumpAndSettle();
      await phone.tapAfterScrolling(tester, find.text('Remove from store'));

      expect(find.textContaining('signed out straight away'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Remove from store'));
      await tester.pumpAndSettle();

      expect(api.removed, ['liza']);
      expect(find.text('Liza was removed'), findsOneWidget);
      expect(find.text('No staff yet'), findsOneWidget);
    });

    testWidgets('with no signal, the owner is told and can try again', (
      tester,
    ) async {
      api.failWith = offline;
      await open(tester, RoutePaths.staff, (_) => const StaffScreen());

      expect(find.textContaining('offline'), findsOneWidget);
      api.failWith = null;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('No staff yet'), findsOneWidget);
    });
  });

  group('devices', () {
    testWidgets('a lost phone can be signed out; this one cannot', (
      tester,
    ) async {
      api.deviceList = sampleDevices();
      await open(tester, RoutePaths.devices, (_) => const DevicesScreen());

      expect(find.textContaining('This phone'), findsOneWidget);
      expect(
        find.widgetWithText(TextButton, 'Sign out'),
        findsOneWidget,
        reason: 'only the other phone offers it',
      );

      await tester.tap(find.widgetWithText(TextButton, 'Sign out'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('stops syncing straight away'),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
      await tester.pumpAndSettle();

      expect(api.signedOut, ['counter']);
      const other = 'Vivo Y12s counter phone with a long name';
      expect(find.widgetWithText(ListTile, other), findsNothing);
      expect(find.text('$other was signed out'), findsOneWidget);
    });
  });

  group('activity', () {
    testWidgets('reads as sentences, with the detail that matters', (
      tester,
    ) async {
      api.activityPages = [ActivityPage(events: sampleActivity())];
      await open(tester, RoutePaths.activity, (_) => const ActivityScreen());

      expect(
        find.text('Nena Reyes voided a sale of ₱1,250.50'),
        findsOneWidget,
      );
      expect(
        find.text('Liza Dela Cruz-Santos recorded a sale of ₱75.00'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Price ₱70.00 to ₱75.00\nCost ₱60.00 to ₱68.00'),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.textContaining('-3 from what was expected'),
        200,
      );
      expect(find.text('Yesterday'), findsOneWidget);
    });

    testWidgets('in Filipino too', (tester) async {
      api.activityPages = [ActivityPage(events: sampleActivity())];
      await open(
        tester,
        RoutePaths.activity,
        (_) => const ActivityScreen(),
        locale: const Locale('fil'),
      );

      expect(
        find.text('Nag-void si Nena Reyes ng benta na ₱1,250.50'),
        findsOneWidget,
      );
      expect(find.text('Lahat'), findsOneWidget);
    });

    testWidgets('can be narrowed to voids and deletions, and paged back', (
      tester,
    ) async {
      final events = sampleActivity();
      api.activityPages = [
        ActivityPage(events: events.take(3).toList(), nextBefore: 4),
        ActivityPage(events: events.skip(3).toList()),
        ActivityPage(
          events: events.where((event) => event.action.isRemoval).toList(),
        ),
      ];
      final phone = await open(
        tester,
        RoutePaths.activity,
        (_) => const ActivityScreen(),
      );

      // The button is the list's last row, built only once scrolled to.
      await tester.scrollUntilVisible(find.text('Show older'), 200);
      await phone.tapAfterScrolling(tester, find.text('Show older'));
      expect(api.activityRequests.last.before, 4);
      expect(find.text('Show older'), findsNothing);

      await tester.tap(find.text('Voids and deletions'));
      await tester.pumpAndSettle();
      expect(api.activityRequests.last.onlyRemovals, isTrue);
      expect(find.textContaining('recorded a sale'), findsNothing);
      expect(find.textContaining('voided a sale'), findsOneWidget);
    });

    test('every kind of entry reads as a sentence in both languages', () {
      // An entry the app has no words for would show as a blank line.
      for (final locale in const [Locale('en'), Locale('fil')]) {
        final l10n = lookupAppLocalizations(locale);
        for (final action in ActivityAction.values) {
          final event = ActivityEvent(
            id: 1,
            action: action,
            actorName: 'Liza',
            isStaff: true,
            deviceName: 'Vivo',
            details: const {'name': 'Coke', 'total': 10, 'amount': 5},
            occurredAt: DateTime(2026, 9, 20),
          );
          expect(
            l10n.activitySentence(event),
            contains('Liza'),
            reason: '${locale.languageCode} ${action.name}',
          );
        }
      }
    });
  });
}
