import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/route_paths.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/subscription.dart';
import '../../../l10n/l10n.dart';
import '../../authentication/auth_controller.dart';
import '../billing_text.dart';

/// A quiet reminder on the home screen when the plan is nearly over, has
/// run out, or has paused uploads. Never a wall: the store keeps working.
class PlanBanner extends ConsumerWidget {
  const PlanBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscription = ref.watch(subscriptionProvider);
    final now = DateTime.now();
    if (!subscription.needsAttention(now)) return const SizedBox.shrink();

    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isOwner = ref.watch(currentAccessProvider).isOwner;
    final paused = subscription.status == SubscriptionStatus.paused;
    final background = paused
        ? theme.colorScheme.errorContainer
        : theme.colorScheme.secondaryContainer;
    final foreground = paused
        ? theme.colorScheme.onErrorContainer
        : theme.colorScheme.onSecondaryContainer;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Card(
        color: background,
        margin: EdgeInsets.zero,
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    paused
                        ? Icons.pause_circle_outline_rounded
                        : Icons.event_outlined,
                    color: foreground,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      isOwner
                          ? l10n.subscriptionReminder(subscription, now)
                          : '${l10n.subscriptionReminder(subscription, now)} '
                                '${l10n.planBannerStaff}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: foreground,
                      ),
                    ),
                  ),
                ],
              ),
              if (isOwner) ...[
                AppSpacing.gapSm,
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: FilledButton.tonal(
                    onPressed: () => context.push(RoutePaths.plan),
                    child: Text(l10n.planBannerAction),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
