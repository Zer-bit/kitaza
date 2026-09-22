import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatting/day_formatter.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/activity_event.dart';
import '../../l10n/l10n.dart';
import '../../shared/widgets/async_content.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/feedback_messenger.dart';
import '../../shared/widgets/page_body.dart';
import 'team_providers.dart';

/// Who recorded, changed and voided what, on every phone. The first place an
/// owner looks when the cash drawer and the sales do not agree.
class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final feed = ref.watch(activityProvider);
    final onlyRemovals = feed.value?.onlyRemovals ?? false;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.activityTitle)),
      body: Column(
        children: [
          PageBody(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<bool>(
                segments: [
                  ButtonSegment(
                    value: false,
                    label: Text(l10n.activityFilterAll),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text(l10n.activityFilterRemovals),
                  ),
                ],
                selected: {onlyRemovals},
                showSelectedIcon: false,
                onSelectionChanged: (selection) => ref
                    .read(activityProvider.notifier)
                    .showOnlyRemovals(selection.first),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.refresh(activityProvider.future),
              child: AsyncContent<ActivityFeed>(
                value: feed,
                onRetry: () => ref.invalidate(activityProvider),
                builder: (data) => data.events.isEmpty
                    ? EmptyState(
                        icon: Icons.history_rounded,
                        title: l10n.activityEmptyTitle,
                        message: l10n.activityEmptyMessage,
                      )
                    : _EventList(feed: data),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventList extends ConsumerWidget {
  const _EventList({required this.feed});

  final ActivityFeed feed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = feed.events;

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      itemCount: events.length + (feed.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == events.length) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Center(
              child: feed.loadingMore
                  ? const CircularProgressIndicator(strokeWidth: 2.5)
                  : OutlinedButton(
                      onPressed: () => _loadOlder(context, ref),
                      child: Text(context.l10n.activityShowOlder),
                    ),
            ),
          );
        }

        final event = events[index];
        final startsDay =
            index == 0 ||
            !_sameDay(events[index - 1].occurredAt, event.occurredAt);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (startsDay) _DayHeader(day: event.occurredAt),
            _EventTile(event: event),
          ],
        );
      },
    );
  }

  Future<void> _loadOlder(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(activityProvider.notifier).loadOlder();
    } on Object catch (error) {
      if (context.mounted) {
        FeedbackMessenger.error(context, context.l10n.failure(error));
      }
    }
  }
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Semantics(
        header: true,
        child: Text(
          context.l10n.dayHeading(day),
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});

  final ActivityEvent event;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final detail = l10n.activityDetail(event);
    final removal = event.action.isRemoval;
    final meta = l10n.commonSeparator(
      event.deviceName,
      DayFormatter.timeOfDay(event.occurredAt),
    );

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      leading: Icon(
        _iconFor(event.action),
        color: removal ? theme.colorScheme.error : null,
      ),
      title: Text(l10n.activitySentence(event)),
      subtitle: Text(detail == null ? meta : '$detail\n$meta'),
      isThreeLine: detail != null,
      trailing: event.isStaff
          ? Chip(
              label: Text(l10n.activityStaffBadge),
              visualDensity: VisualDensity.compact,
            )
          : null,
    );
  }

  static IconData _iconFor(ActivityAction action) => switch (action) {
    ActivityAction.saleRecorded => Icons.point_of_sale_rounded,
    ActivityAction.saleVoided => Icons.cancel_outlined,
    ActivityAction.expenseRecorded => Icons.receipt_long_outlined,
    ActivityAction.expenseDeleted => Icons.delete_outline_rounded,
    ActivityAction.withdrawalRecorded ||
    ActivityAction.withdrawalDeleted => Icons.wallet_rounded,
    ActivityAction.productAdded ||
    ActivityAction.productChanged ||
    ActivityAction.productRemoved => Icons.inventory_2_outlined,
    ActivityAction.stockReceived ||
    ActivityAction.stockRemoved ||
    ActivityAction.stockCounted ||
    ActivityAction.stockSpoiled => Icons.fact_check_outlined,
    ActivityAction.staffAdded ||
    ActivityAction.staffChanged ||
    ActivityAction.staffRemoved ||
    ActivityAction.staffInvited ||
    ActivityAction.staffJoined => Icons.badge_outlined,
    ActivityAction.deviceSignedOut => Icons.phonelink_erase_rounded,
    ActivityAction.storeAdded ||
    ActivityAction.storeRenamed => Icons.storefront_outlined,
    ActivityAction.other => Icons.history_rounded,
  };
}
