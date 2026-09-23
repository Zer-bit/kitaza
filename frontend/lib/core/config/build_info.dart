import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which build of the app this is.
///
/// Shown in Settings and attached to every error report, so a problem an
/// owner describes over the phone can be matched to the code that was
/// running when it happened.
class BuildInfo {
  const BuildInfo({required this.version, required this.platform});

  /// Version and build number together, as `1.2.0+14`.
  final String version;

  /// The operating system the app is running on.
  final String platform;

  /// Before the platform has been asked, and in tests that never ask.
  static const BuildInfo unknown = BuildInfo(
    version: 'unknown',
    platform: 'unknown',
  );
}

/// Overridden at startup with what the platform reports.
final buildInfoProvider = Provider<BuildInfo>((ref) => BuildInfo.unknown);
