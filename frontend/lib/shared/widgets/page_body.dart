import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

/// Caps content width on tablets and desktops. Without it, a form stretches
/// into an unreadable single line across a 27-inch screen.
class PageBody extends StatelessWidget {
  const PageBody({
    super.key,
    required this.child,
    this.maxWidth = 760,
    this.padding = AppSpacing.screenPadding,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      // Wraps its content vertically. Without this it fills whatever height
      // it is offered, which in a bottom bar means the whole screen.
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
