import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

/// Shared chrome for every onboarding screen: the mark, a heading, and a body
/// that stays centred and readable at any window size.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.onBack,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: onBack == null
          ? null
          : AppBar(
              leading: IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'Back',
              ),
            ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _BrandMark(),
                  AppSpacing.gapXl,
                  Text(title, style: theme.textTheme.headlineMedium),
                  AppSpacing.gapSm,
                  Text(subtitle, style: theme.textTheme.bodyMedium),
                  AppSpacing.gapXl,
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: AppRadius.fieldAll,
          ),
          child: Icon(
            Icons.storefront_rounded,
            color: theme.colorScheme.onPrimary,
            size: 24,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Text('Kitaza', style: theme.textTheme.headlineSmall),
      ],
    );
  }
}
