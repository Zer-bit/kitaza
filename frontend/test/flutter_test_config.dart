import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

/// Runs before every test file.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // A tap that lands on nothing - because the target is scrolled off screen
  // or covered by a sheet - is otherwise only a printed warning, and the
  // test carries on as if the owner had pressed the button. Make it fail.
  WidgetController.hitTestWarningShouldBeFatal = true;
  await testMain();
}
