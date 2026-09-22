import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

/// The offline/online choice, presented as two plain options with their real
/// trade-offs spelled out rather than as a toggle labelled "sync".
class StorageModeCard extends StatelessWidget {
  const StorageModeCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.bullets,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String description;
  final List<String> bullets;
  final VoidCallback onTap;

  /// A short tag such as "Start here"; shown only on the suggested option.
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.cardAll,
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: theme.colorScheme.primary, size: 26),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(title, style: theme.textTheme.titleLarge),
                  ),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: AppRadius.pillAll,
                      ),
                      child: Text(
                        badge!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                ],
              ),
              AppSpacing.gapSm,
              Text(description, style: theme.textTheme.bodyMedium),
              AppSpacing.gapMd,
              ...bullets.map(
                (bullet) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(bullet, style: theme.textTheme.bodySmall),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
