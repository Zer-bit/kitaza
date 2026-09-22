import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_failure.dart';
import '../../core/theme/app_spacing.dart';

/// One place that decides how loading and failure look, so every screen
/// handles them the same way.
class AsyncContent<T> extends StatelessWidget {
  const AsyncContent({
    super.key,
    required this.value,
    required this.builder,
    this.onRetry,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppMotion.standard,
      switchInCurve: AppMotion.easing,
      child: switch (value) {
        AsyncData(:final value) => KeyedSubtree(
          key: const ValueKey('data'),
          child: builder(value),
        ),
        AsyncError(:final error) => _FailureView(
          key: const ValueKey('error'),
          message: error is AppFailure
              ? error.message
              : 'Something went wrong. Please try again.',
          onRetry: onRetry,
        ),
        _ => const Center(
          key: ValueKey('loading'),
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.xxl),
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      },
    );
  }
}

class _FailureView extends StatelessWidget {
  const _FailureView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 32,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            AppSpacing.gapMd,
            Text(
              message,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              AppSpacing.gapLg,
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
