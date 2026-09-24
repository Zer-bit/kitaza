import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme_controller.dart';

/// Switches between light and dark without asking the phone to animate the
/// theme itself.
///
/// Blending two whole themes rebuilds every widget in the app on every frame
/// of the fade, which a cheap phone cannot do in time, and anything that picks
/// its colours by brightness jumps halfway through instead of fading. So this
/// takes a picture of the screen as it is, switches the theme instantly
/// underneath, and opens a widening circle in the picture from where the
/// owner tapped. The new theme is fully drawn from the first frame; the only
/// thing that moves is one image.
class ThemeReveal extends ConsumerStatefulWidget {
  const ThemeReveal({super.key, required this.child});

  final Widget child;

  static const Duration duration = Duration(milliseconds: 480);

  /// Null outside the app's root, where a switch simply happens at once.
  static ThemeRevealState? maybeOf(BuildContext context) =>
      context.findAncestorStateOfType<ThemeRevealState>();

  /// Changes the theme, revealing it from [from] when there is somewhere to
  /// reveal it from.
  static void switchTo(
    BuildContext context,
    WidgetRef ref,
    ThemeMode mode, {
    Offset? from,
  }) {
    final reveal = maybeOf(context);
    if (reveal == null) {
      ref.read(themeControllerProvider.notifier).select(mode);
      return;
    }
    reveal.switchTo(mode, from: from);
  }

  @override
  ConsumerState<ThemeReveal> createState() => ThemeRevealState();
}

class ThemeRevealState extends ConsumerState<ThemeReveal>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final _screen = GlobalKey();
  late final AnimationController _progress = AnimationController(
    vsync: this,
    duration: ThemeReveal.duration,
  );
  late final Animation<double> _eased = CurvedAnimation(
    parent: _progress,
    curve: Curves.easeInOutCubic,
  );

  /// The screen as it looked before the switch, while it is being uncovered.
  ui.Image? _before;
  Offset? _origin;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _progress.dispose();
    _before?.dispose();
    super.dispose();
  }

  void switchTo(ThemeMode mode, {Offset? from}) {
    final controller = ref.read(themeControllerProvider.notifier);
    final platform = MediaQuery.platformBrightnessOf(context);
    final looksDifferent =
        _resolve(ref.read(themeControllerProvider), platform) !=
        _resolve(mode, platform);

    // Light to Auto on a phone that is already light changes nothing on
    // screen, so there is nothing to reveal.
    if (looksDifferent) _captureBeforeChange(from);
    controller.select(mode);
  }

  /// The phone switched itself to dark at sunset, and the app follows it.
  @override
  void didChangePlatformBrightness() {
    if (ref.read(themeControllerProvider) == ThemeMode.system) {
      _captureBeforeChange(null);
    }
  }

  void _captureBeforeChange(Offset? from) {
    if (MediaQuery.disableAnimationsOf(context)) return;

    final boundary = _screen.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary || !boundary.hasSize) return;

    final ui.Image picture;
    try {
      picture = boundary.toImageSync(
        pixelRatio: MediaQuery.devicePixelRatioOf(context),
      );
    } on Object {
      // A picture that cannot be taken is a switch without the flourish,
      // never a switch that fails.
      return;
    }

    setState(() {
      _before?.dispose();
      _before = picture;
      _origin = from;
    });
    _progress.forward(from: 0).whenCompleteOrCancel(() {
      if (!mounted) return;
      setState(() {
        _before?.dispose();
        _before = null;
      });
    });
  }

  static Brightness _resolve(ThemeMode mode, Brightness platform) =>
      switch (mode) {
        ThemeMode.light => Brightness.light,
        ThemeMode.dark => Brightness.dark,
        ThemeMode.system => platform,
      };

  @override
  Widget build(BuildContext context) {
    final before = _before;

    return RepaintBoundary(
      key: _screen,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          // Its own layer, so the circle growing over it each frame does not
          // repaint the app underneath.
          RepaintBoundary(child: widget.child),
          if (before != null)
            Positioned.fill(
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _eased,
                    builder: (context, _) => CustomPaint(
                      painter: _UncoverPainter(
                        picture: before,
                        origin: _origin,
                        progress: _eased.value,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Draws the old screen with a hole in it that grows until nothing is left.
/// Without a tap to start from, it fades instead.
class _UncoverPainter extends CustomPainter {
  const _UncoverPainter({
    required this.picture,
    required this.origin,
    required this.progress,
  });

  final ui.Image picture;
  final Offset? origin;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final whole = Offset.zero & size;
    final source = Rect.fromLTWH(
      0,
      0,
      picture.width.toDouble(),
      picture.height.toDouble(),
    );
    final paint = Paint()..filterQuality = FilterQuality.low;

    final from = origin;
    if (from == null) {
      paint.color = Color.fromRGBO(0, 0, 0, 1 - progress);
      canvas.drawImageRect(picture, source, whole, paint);
      return;
    }

    // Far enough to reach the corner furthest from the tap.
    final reach = [
      whole.topLeft,
      whole.topRight,
      whole.bottomLeft,
      whole.bottomRight,
    ].map((corner) => (corner - from).distance).reduce(math.max);

    final hole = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(whole)
      ..addOval(Rect.fromCircle(center: from, radius: reach * progress));

    canvas
      ..save()
      ..clipPath(hole)
      ..drawImageRect(picture, source, whole, paint)
      ..restore();
  }

  @override
  bool shouldRepaint(_UncoverPainter old) =>
      old.progress != progress ||
      old.picture != picture ||
      old.origin != origin;
}
