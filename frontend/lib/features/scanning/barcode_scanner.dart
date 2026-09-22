import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'scanner_screen.dart';

/// Opens the camera to read barcodes. Behind a provider so the flows that
/// use it can be tested without a camera.
class BarcodeScanner {
  const BarcodeScanner();

  /// Phones and tablets only: there is no camera support on desktop builds.
  bool get isAvailable =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Reads one code and closes. Null if the owner backs out.
  Future<String?> scanOnce(BuildContext context) {
    return Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const ScannerScreen.single()),
    );
  }

  /// Keeps the camera open, handing every new code to [onCode], the way a
  /// checkout scanner works. [onCode] returns what to show under the camera.
  Future<void> scanContinuously(
    BuildContext context, {
    required FutureOr<String?> Function(String code) onCode,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ScannerScreen.continuous(onCode: onCode),
      ),
    );
  }
}

final barcodeScannerProvider = Provider<BarcodeScanner>(
  (ref) => const BarcodeScanner(),
);
