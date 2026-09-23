import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the handful of things that are only wrong once the app is on a
/// stranger's phone, where nobody is watching a console.
void main() {
  final manifest = File('android/app/src/main/AndroidManifest.xml')
      .readAsStringSync();
  final pubspec = File('pubspec.yaml').readAsStringSync();
  final gradle = File('android/app/build.gradle.kts').readAsStringSync();

  test('the name under the icon is the product, not the project folder', () {
    expect(manifest, contains('android:label="Kitaza"'));
    expect(
      manifest,
      isNot(contains('kitaza_app')),
      reason: 'an owner should never see the Flutter template default',
    );
  });

  test('the version is a single line in pubspec, which a release bumps', () {
    final version = RegExp(
      r'^version:\s*(\d+\.\d+\.\d+)\+(\d+)$',
      multiLine: true,
    ).firstMatch(pubspec);

    expect(version, isNotNull, reason: 'version: <name>+<build> in pubspec');
    expect(int.parse(version!.group(2)!), greaterThan(0));
    expect(gradle, contains('versionCode = flutter.versionCode'));
    expect(gradle, contains('versionName = flutter.versionName'));
  });

  test('a release cannot be signed with the debug key by accident', () {
    expect(gradle, contains('key.properties'));
    expect(gradle, contains('allowDebugSigning'));
  });

  test('no signing material is sitting in the repository', () {
    final loose = Directory('android')
        .listSync(recursive: true)
        .whereType<File>()
        .map((file) => file.path)
        .where(
          (path) =>
              path.endsWith('key.properties') ||
              path.endsWith('.jks') ||
              path.endsWith('.keystore') ||
              path.endsWith('.p12'),
        )
        .where((path) => !path.contains('build/'));

    // `key.properties` itself is git-ignored and may exist on a release
    // machine; a keystore file inside the project never should.
    expect(
      loose.where((path) => !path.endsWith('key.properties')),
      isEmpty,
      reason: 'keep the keystore outside the repository',
    );
  });

  test('the app describes itself, for the store listing and pub', () {
    expect(pubspec, isNot(contains('A new Flutter project')));
  });
}
