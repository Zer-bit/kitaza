import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitaza_app/app/route_paths.dart';
import 'package:kitaza_app/core/config/build_info.dart';
import 'package:kitaza_app/features/settings/settings_screen.dart';

import '../support/app_harness.dart';

void main() {
  /// What the platform channel was last asked to put on the clipboard.
  String? copied;

  setUp(() {
    copied = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String?;
          }
          return null;
        });
  });

  Future<TestPhone> openSettings(WidgetTester tester) => TestPhone.open(
    tester,
    screens: {RoutePaths.settings: (_) => const SettingsScreen()},
    overrides: (_, _) => [
      buildInfoProvider.overrideWithValue(
        const BuildInfo(version: '1.4.0+21', platform: 'android 14'),
      ),
    ],
  );

  testWidgets('an owner can read which build they are running', (tester) async {
    final phone = await openSettings(tester);
    await phone.goTo(tester, RoutePaths.settings);

    await tester.scrollUntilVisible(find.text('Kitaza 1.4.0+21'), 250);
    expect(find.text('android 14'), findsOneWidget);
  });

  testWidgets('a build that was never pointed at a server says so', (
    tester,
  ) async {
    // The test build carries the default, which is the emulator's route to
    // the developer's own machine.
    final phone = await openSettings(tester);
    await phone.goTo(tester, RoutePaths.settings);

    await tester.scrollUntilVisible(find.text('Kitaza 1.4.0+21'), 250);
    expect(
      find.text('Test build. Cloud storage will not connect.'),
      findsOneWidget,
    );
  });

  testWidgets('and copy it into a message to support', (tester) async {
    final phone = await openSettings(tester);
    await phone.goTo(tester, RoutePaths.settings);

    await tester.scrollUntilVisible(find.text('Kitaza 1.4.0+21'), 250);
    await phone.tapAfterScrolling(tester, find.text('Kitaza 1.4.0+21'));

    expect(copied, 'Kitaza 1.4.0+21 on android 14');
    expect(find.text('Version copied'), findsOneWidget);
  });
}
