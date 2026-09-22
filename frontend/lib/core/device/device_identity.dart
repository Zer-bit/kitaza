import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How this phone introduces itself when signing in, so an owner can tell
/// "Samsung SM-A125F" from "Counter tablet" in their list of devices.
class DeviceIdentity {
  const DeviceIdentity();

  /// The platform, for the server's records.
  String get tag => kIsWeb ? 'web' : Platform.operatingSystem;

  /// Never throws: a phone that will not say what it is still signs in.
  Future<String> name() async {
    try {
      final info = DeviceInfoPlugin();
      if (kIsWeb) return 'Web browser';
      if (Platform.isAndroid) {
        final android = await info.androidInfo;
        return _join(_capitalised(android.manufacturer), android.model);
      }
      if (Platform.isIOS) return (await info.iosInfo).name;
      if (Platform.isLinux) return (await info.linuxInfo).prettyName;
      if (Platform.isMacOS) return (await info.macOsInfo).computerName;
      if (Platform.isWindows) return (await info.windowsInfo).computerName;
    } on Object {
      // Fall through to the platform name.
    }
    return tag;
  }

  /// "Samsung SM-A125F", not "samsung samsung SM-A125F".
  static String _join(String maker, String model) =>
      model.toLowerCase().startsWith(maker.toLowerCase())
      ? model
      : '$maker $model';

  static String _capitalised(String value) =>
      value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';
}

final deviceIdentityProvider = Provider<DeviceIdentity>(
  (ref) => const DeviceIdentity(),
);
