import 'package:flutter/widgets.dart';

/// Kitaza runs on a ₱3,000 Android phone, a shared tablet at the counter and
/// a laptop in the back room. These are the three shapes it adapts to.
enum ScreenSize { compact, medium, expanded }

extension ResponsiveContext on BuildContext {
  ScreenSize get screenSize {
    final width = MediaQuery.sizeOf(this).width;
    if (width < 600) return ScreenSize.compact;
    if (width < 1000) return ScreenSize.medium;
    return ScreenSize.expanded;
  }

  bool get isCompact => screenSize == ScreenSize.compact;
  bool get isExpanded => screenSize == ScreenSize.expanded;

  /// Grid columns for stat cards, so the dashboard reflows instead of
  /// stretching one card across a desktop window.
  int get statColumns => switch (screenSize) {
    ScreenSize.compact => 2,
    ScreenSize.medium => 3,
    ScreenSize.expanded => 4,
  };
}
