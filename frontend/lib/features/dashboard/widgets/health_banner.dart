import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/health_colors.dart';
import '../../../data/models/business_health.dart';
import '../../../l10n/l10n.dart';

/// The traffic light, spelled out. The rating word and the icon carry the
/// message on their own so it still reads for a colour-blind owner.
class HealthBanner extends StatelessWidget {
  const HealthBanner({super.key, required this.health});

  final BusinessHealth health;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final appearance = HealthAppearance.of(context, health.rating);
    final reasons = l10n.healthReasons(health);
    return MergeSemantics(
      child: AnimatedContainer(
        duration: AppMotion.standard,
        curve: AppMotion.easing,
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: appearance.surface,
          borderRadius: AppRadius.cardAll,
          border: Border.all(color: appearance.color.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // The rating sits above the headline rather than beside it: side by
            // side, a long headline and "Katamtaman · 55" at large text did not
            // fit a small phone.
            Row(
              children: [
                Icon(appearance.icon, color: appearance.color, size: 26),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: _RatingChip(
                    appearance: appearance,
                    label: l10n.healthRatingChip(
                      l10n.healthRating(health.rating),
                      health.score,
                    ),
                  ),
                ),
              ],
            ),
            AppSpacing.gapSm,
            Text(
              l10n.healthHeadline(health),
              style: theme.textTheme.titleLarge?.copyWith(
                color: appearance.color,
              ),
            ),
            if (reasons.isNotEmpty) ...[
              AppSpacing.gapMd,
              ...reasons.map(
                (reason) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Icon(
                          Icons.circle,
                          size: 6,
                          color: appearance.color,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(reason, style: theme.textTheme.bodyMedium),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RatingChip extends StatelessWidget {
  const _RatingChip({required this.appearance, required this.label});

  final HealthAppearance appearance;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: appearance.color,
        borderRadius: AppRadius.pillAll,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.surface,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
