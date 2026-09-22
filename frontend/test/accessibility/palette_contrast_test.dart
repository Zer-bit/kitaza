import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitaza_app/core/theme/app_palette.dart';
import 'package:kitaza_app/core/theme/app_theme.dart';

/// WCAG 2.x contrast ratio between two opaque colours.
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// Body text must reach 4.5:1 (WCAG AA). Large text and non-text marks such
/// as chart bars need 3:1.
const double bodyText = 4.5;
const double largeOrGraphic = 3.0;

void main() {
  for (final (name, theme, canvas) in [
    ('light', AppTheme.light(), AppPalette.canvasLight),
    ('dark', AppTheme.dark(), AppPalette.canvasDark),
  ]) {
    group('$name theme', () {
      final scheme = theme.colorScheme;

      final pairs = <String, (Color, Color, double)>{
        'text on cards': (scheme.onSurface, scheme.surface, bodyText),
        'text on the page background': (scheme.onSurface, canvas, bodyText),
        'secondary text on cards': (
          scheme.onSurfaceVariant,
          scheme.surface,
          bodyText,
        ),
        'secondary text on the page': (
          scheme.onSurfaceVariant,
          canvas,
          bodyText,
        ),
        'links and text buttons': (scheme.primary, scheme.surface, bodyText),
        'filled button labels': (scheme.onPrimary, scheme.primary, bodyText),
        'error text': (scheme.error, scheme.surface, bodyText),
        'selected chips': (
          scheme.onPrimaryContainer,
          scheme.primaryContainer,
          bodyText,
        ),
        'accent containers': (
          scheme.onSecondaryContainer,
          scheme.secondaryContainer,
          bodyText,
        ),
      };

      pairs.forEach((label, pair) {
        final (foreground, background, minimum) = pair;
        test('$label reach ${minimum.toStringAsFixed(1)}:1', () {
          expect(
            contrast(foreground, background),
            greaterThanOrEqualTo(minimum),
            reason:
                '$label: ${contrast(foreground, background).toStringAsFixed(2)}:1',
          );
        });
      });
    });
  }

  group('health banner', () {
    for (final (name, isLight) in [('light', true), ('dark', false)]) {
      final ratings = isLight
          ? {
              'good': (AppPalette.good, const Color(0xFFE6F4EA)),
              'average': (AppPalette.caution, const Color(0xFFFBF3DC)),
              'warning': (AppPalette.alert, const Color(0xFFFBE9E9)),
            }
          : {
              'good': (AppPalette.goodDark, const Color(0xFF14301F)),
              'average': (AppPalette.cautionDark, const Color(0xFF332A10)),
              'warning': (AppPalette.alertDark, const Color(0xFF3A1717)),
            };
      final surface = isLight
          ? AppPalette.surfaceLight
          : AppPalette.surfaceDark;

      ratings.forEach((rating, colours) {
        final (color, banner) = colours;
        test('$name "$rating" headline is readable on its banner', () {
          expect(contrast(color, banner), greaterThanOrEqualTo(bodyText));
        });
        test('$name "$rating" rating chip label is readable', () {
          expect(contrast(surface, color), greaterThanOrEqualTo(bodyText));
        });
      });
    }
  });

  test('chart bars stand out from the card in both themes', () {
    expect(
      contrast(AppPalette.chartProfit, AppPalette.surfaceLight),
      greaterThanOrEqualTo(largeOrGraphic),
    );
    expect(
      contrast(AppPalette.chartLoss, AppPalette.surfaceLight),
      greaterThanOrEqualTo(largeOrGraphic),
    );
    expect(
      contrast(AppPalette.chartProfitDark, AppPalette.surfaceDark),
      greaterThanOrEqualTo(largeOrGraphic),
    );
    expect(
      contrast(AppPalette.chartLossDark, AppPalette.surfaceDark),
      greaterThanOrEqualTo(largeOrGraphic),
    );
  });
}
