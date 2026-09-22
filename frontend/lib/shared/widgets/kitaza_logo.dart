import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';

/// The Kitaza mark. Rendered from the same PNG the launcher icon and splash are
/// generated from, so every appearance of the logo stays identical when the
/// placeholder is replaced.
class KitazaLogo extends StatelessWidget {
  const KitazaLogo({super.key, this.size = 44});

  final double size;

  static const String assetPath = 'assets/brand/app_icon.png';

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      // Matches the corner ratio of the generated splash tile.
      borderRadius: BorderRadius.circular(size * 0.225),
      child: Image.asset(
        assetPath,
        width: size,
        height: size,
        filterQuality: FilterQuality.medium,
        semanticLabel: context.l10n.appName,
      ),
    );
  }
}
