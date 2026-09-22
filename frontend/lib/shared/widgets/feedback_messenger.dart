import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

/// Confirmations and warnings, phrased for someone behind a counter.
abstract final class FeedbackMessenger {
  static void success(BuildContext context, String message) =>
      _show(context, message, Icons.check_circle_rounded, AppPalette.goodDark);

  static void warn(BuildContext context, String message) =>
      _show(context, message, Icons.info_rounded, AppPalette.cautionDark);

  static void error(BuildContext context, String message) =>
      _show(context, message, Icons.error_rounded, AppPalette.alertDark);

  static void _show(
    BuildContext context,
    String message,
    IconData icon,
    Color accent,
  ) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 3),
          content: Row(
            children: [
              Icon(icon, color: accent, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }
}
