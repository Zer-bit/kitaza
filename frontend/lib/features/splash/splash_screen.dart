import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/kitaza_logo.dart';

/// Shown while the stored session is restored.
///
/// It deliberately copies the native splash - same background per system
/// brightness, same logo, same 120dp size, centred - so the jump from the
/// platform splash to Flutter's first frame cannot be seen. It follows the
/// *system* brightness rather than the in-app theme choice because the native
/// splash can only see the system setting.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const double logoSize = 120;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const Duration _patienceThreshold = Duration(milliseconds: 700);

  bool _showProgress = false;
  Timer? _patienceTimer;

  @override
  void initState() {
    super.initState();
    // Restoring a session normally takes a few milliseconds. A spinner only
    // appears on a genuinely slow device, so the common case stays calm.
    _patienceTimer = Timer(_patienceThreshold, () {
      if (mounted) setState(() => _showProgress = true);
    });
  }

  @override
  void dispose() {
    _patienceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;

    return ColoredBox(
      color: isDark ? AppPalette.canvasDark : AppPalette.canvasLight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const KitazaLogo(size: SplashScreen.logoSize),
          Positioned(
            bottom: 96,
            child: AnimatedOpacity(
              opacity: _showProgress ? 1 : 0,
              duration: AppMotion.standard,
              child: SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: isDark ? AppPalette.tealBright : AppPalette.teal,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
