import 'package:flutter/material.dart';

import '../../../core/formatting/day_formatter.dart';
import '../../../core/formatting/peso_formatter.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/report_models.dart';
import '../../../l10n/l10n.dart';

/// Daily net profit for the last two weeks.
///
/// Drawn with `CustomPaint` rather than a charting package: one measure, one
/// axis, a few dozen bars. A dependency would add weight to every build for
/// features this chart will never use.
///
/// Sign is carried by three things at once - which side of the baseline the
/// bar sits on, its colour, and the labelled best and worst days - so the
/// chart still reads without colour vision.
class ProfitTrendChart extends StatefulWidget {
  const ProfitTrendChart({super.key, required this.points});

  final List<DailyProfitPoint> points;

  @override
  State<ProfitTrendChart> createState() => _ProfitTrendChartState();
}

class _ProfitTrendChartState extends State<ProfitTrendChart> {
  int? _focusedIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    final profitColor = isLight
        ? AppPalette.chartProfit
        : AppPalette.chartProfitDark;
    final lossColor = isLight ? AppPalette.chartLoss : AppPalette.chartLossDark;

    final focused = _focusedIndex == null
        ? null
        : widget.points[_focusedIndex!];

    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.reportTrendTitle,
              style: theme.textTheme.titleMedium,
            ),
            AppSpacing.gapXs,
            Text(
              focused == null
                  ? context.l10n.reportTrendHint
                  : context.l10n.commonSeparator(
                      DayFormatter.dayMonth(focused.day),
                      PesoFormatter.signed(focused.netProfit),
                    ),
              style: theme.textTheme.bodySmall,
            ),
            AppSpacing.gapLg,
            Semantics(
              label: _spokenSummary(context),
              child: SizedBox(
                height: 168,
                child: LayoutBuilder(
                  builder: (context, constraints) => GestureDetector(
                    onTapDown: (details) => _focusBar(details, constraints),
                    child: CustomPaint(
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                      painter: _TrendPainter(
                        points: widget.points,
                        profitColor: profitColor,
                        lossColor: lossColor,
                        axisColor: theme.colorScheme.outline,
                        labelStyle: theme.textTheme.labelSmall!,
                        focusedIndex: _focusedIndex,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// What a screen reader says instead of drawing bars: the span, and the
  /// best and worst days, which is what a sighted owner takes from the chart
  /// at a glance.
  String _spokenSummary(BuildContext context) {
    final l10n = context.l10n;
    if (widget.points.isEmpty) return l10n.reportTrendTitle;

    final best = widget.points.reduce(
      (a, b) => a.netProfit >= b.netProfit ? a : b,
    );
    final worst = widget.points.reduce(
      (a, b) => a.netProfit <= b.netProfit ? a : b,
    );

    return l10n.reportTrendSummary(
      widget.points.length,
      DayFormatter.dayMonth(best.day),
      PesoFormatter.signed(best.netProfit),
      DayFormatter.dayMonth(worst.day),
      PesoFormatter.signed(worst.netProfit),
    );
  }

  void _focusBar(TapDownDetails details, BoxConstraints constraints) {
    if (widget.points.isEmpty) return;

    final slot = constraints.maxWidth / widget.points.length;
    final index = (details.localPosition.dx ~/ slot).clamp(
      0,
      widget.points.length - 1,
    );

    setState(() => _focusedIndex = _focusedIndex == index ? null : index);
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({
    required this.points,
    required this.profitColor,
    required this.lossColor,
    required this.axisColor,
    required this.labelStyle,
    required this.focusedIndex,
  });

  final List<DailyProfitPoint> points;
  final Color profitColor;
  final Color lossColor;
  final Color axisColor;
  final TextStyle labelStyle;
  final int? focusedIndex;

  /// A 2px gap between neighbouring bars keeps them from reading as one mass.
  static const double _barGap = 2;
  static const double _labelGutter = 18;
  static const double _cornerRadius = 4;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final plotHeight = size.height - _labelGutter;
    final magnitudes = points.map((point) => point.netProfit.abs());
    final peak = magnitudes.reduce((a, b) => a > b ? a : b);
    final scale = peak == 0 ? 0.0 : (plotHeight / 2 - 6) / peak;

    final baselineY = plotHeight / 2;
    final slot = size.width / points.length;
    final barWidth = (slot - _barGap).clamp(3.0, 28.0);

    _paintBaseline(canvas, size, baselineY);

    for (var index = 0; index < points.length; index++) {
      final value = points[index].netProfit;
      final height = (value.abs() * scale).clamp(2.0, plotHeight / 2);
      final left = index * slot + (slot - barWidth) / 2;

      final rect = value >= 0
          ? Rect.fromLTWH(left, baselineY - height, barWidth, height)
          : Rect.fromLTWH(left, baselineY, barWidth, height);

      // Rounded only on the far end, so every bar stays visually anchored to
      // the baseline it is measured from.
      final rounded = RRect.fromRectAndCorners(
        rect,
        topLeft: value >= 0
            ? const Radius.circular(_cornerRadius)
            : Radius.zero,
        topRight: value >= 0
            ? const Radius.circular(_cornerRadius)
            : Radius.zero,
        bottomLeft: value < 0
            ? const Radius.circular(_cornerRadius)
            : Radius.zero,
        bottomRight: value < 0
            ? const Radius.circular(_cornerRadius)
            : Radius.zero,
      );

      final isFocused = focusedIndex == index;
      final paint = Paint()
        ..color = (value >= 0 ? profitColor : lossColor).withValues(
          alpha: focusedIndex == null || isFocused ? 1 : 0.35,
        );

      canvas.drawRRect(rounded, paint);
    }

    _paintEdgeLabels(canvas, size, slot);
  }

  void _paintBaseline(Canvas canvas, Size size, double baselineY) {
    canvas.drawLine(
      Offset(0, baselineY),
      Offset(size.width, baselineY),
      Paint()
        ..color = axisColor
        ..strokeWidth = 1,
    );
  }

  /// Only the first and last day are labelled. A label under every bar is
  /// unreadable at phone width and adds nothing.
  void _paintEdgeLabels(Canvas canvas, Size size, double slot) {
    _drawLabel(
      canvas,
      DayFormatter.dayMonth(points.first.day),
      0,
      size.height - _labelGutter + 4,
    );

    if (points.length > 1) {
      final text = DayFormatter.dayMonth(points.last.day);
      final painter = _textPainter(text);
      _drawLabel(
        canvas,
        text,
        size.width - painter.width,
        size.height - _labelGutter + 4,
      );
    }
  }

  void _drawLabel(Canvas canvas, String text, double dx, double dy) {
    _textPainter(text).paint(canvas, Offset(dx, dy));
  }

  TextPainter _textPainter(String text) {
    return TextPainter(
      text: TextSpan(text: text, style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  @override
  bool shouldRepaint(_TrendPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.focusedIndex != focusedIndex ||
      oldDelegate.profitColor != profitColor;
}
