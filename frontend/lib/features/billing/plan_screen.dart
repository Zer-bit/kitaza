import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatting/day_formatter.dart';
import '../../core/formatting/peso_formatter.dart';
import '../../core/platform/link_opener.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/billing_overview.dart';
import '../../data/models/subscription.dart';
import '../../data/remote/billing_api.dart';
import '../../l10n/l10n.dart';
import '../../shared/widgets/async_content.dart';
import '../../shared/widgets/feedback_messenger.dart';
import '../../shared/widgets/page_body.dart';
import '../../shared/widgets/section_header.dart';
import '../authentication/auth_controller.dart';
import 'billing_text.dart';

final billingOverviewProvider = FutureProvider.autoDispose<BillingOverview>(
  (ref) => ref.watch(billingApiProvider).overview(),
);

/// The owner's plan: where it stands, paying ahead with GCash or Maya, and
/// the way out to free offline use that keeps every record.
class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({super.key});

  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends ConsumerState<PlanScreen> {
  PlanTier? _chosen;
  int _months = 1;
  bool _opening = false;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Paying happens in the browser. Coming back is the moment to look.
    _lifecycle = AppLifecycleListener(onResume: _checkForPayment);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _checkForPayment() async {
    final before = ref.read(subscriptionProvider);
    ref.invalidate(billingOverviewProvider);
    try {
      await ref.read(authControllerProvider.notifier).refreshAccount();
    } on Object {
      return;
    }
    final after = ref.read(subscriptionProvider);
    if (mounted && after != before && !after.isPaused) {
      FeedbackMessenger.success(context, context.l10n.planPaid);
    }
  }

  Future<void> _pay(PlanTier plan) async {
    final l10n = context.l10n;
    setState(() => _opening = true);
    try {
      final link = await ref.read(billingApiProvider).checkout(plan, _months);
      final opened = await ref.read(linkOpenerProvider).open(link);
      if (!mounted) return;
      opened
          ? FeedbackMessenger.success(context, l10n.planFinishInBrowser)
          : FeedbackMessenger.error(context, l10n.planCouldNotOpen);
    } on Object catch (error) {
      if (mounted) FeedbackMessenger.error(context, l10n.failure(error));
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  Future<void> _leaveCloud() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.planLeaveConfirmTitle),
        content: Text(l10n.planLeaveConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.planLeaveConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    await ref.read(authControllerProvider.notifier).leaveCloud();
    messenger.showSnackBar(SnackBar(content: Text(l10n.planLeft)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final overview = ref.watch(billingOverviewProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.planTitle)),
      body: RefreshIndicator(
        onRefresh: _checkForPayment,
        child: AsyncContent<BillingOverview>(
          value: overview,
          onRetry: () => ref.invalidate(billingOverviewProvider),
          builder: (data) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              PageBody(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _StatusCard(subscription: data.subscription),
                    if (data.enabled) ..._offers(data),
                    if (data.payments.isNotEmpty) ...[
                      AppSpacing.gapXl,
                      SectionHeader(title: l10n.planHistory),
                      Card(
                        child: Column(
                          children: [
                            for (final payment in data.payments)
                              _PaymentTile(payment: payment),
                          ],
                        ),
                      ),
                    ],
                    AppSpacing.gapXl,
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.phone_android_rounded),
                        title: Text(l10n.planLeaveTitle),
                        subtitle: Text(l10n.planLeaveHint),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: _leaveCloud,
                      ),
                    ),
                    AppSpacing.gapXl,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _offers(BillingOverview data) {
    final l10n = context.l10n;
    final current = data.subscription;
    final chosen =
        _chosen ??
        (current.status == SubscriptionStatus.active ? current.plan : null) ??
        PlanTier.pro;
    final offer = data.plans.firstWhere(
      (plan) => plan.plan == chosen,
      orElse: () => data.plans.first,
    );

    return [
      AppSpacing.gapXl,
      SizedBox(
        width: double.infinity,
        child: SegmentedButton<int>(
          segments: [
            ButtonSegment(value: 1, label: Text(l10n.planMonthly)),
            ButtonSegment(value: 12, label: Text(l10n.planYearly)),
          ],
          selected: {_months},
          showSelectedIcon: false,
          onSelectionChanged: (selection) =>
              setState(() => _months = selection.first),
        ),
      ),
      AppSpacing.gapMd,
      for (final plan in data.plans) ...[
        _PlanCard(
          offer: plan,
          months: _months,
          selected: plan.plan == chosen,
          current:
              current.status == SubscriptionStatus.active &&
              current.plan == plan.plan,
          onTap: () => setState(() => _chosen = plan.plan),
        ),
        AppSpacing.gapMd,
      ],
      FilledButton(
        onPressed: _opening ? null : () => _pay(offer.plan),
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
        child: _opening
            ? const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                l10n.planPay(PesoFormatter.format(offer.priceFor(_months))),
                textAlign: TextAlign.center,
              ),
      ),
      AppSpacing.gapSm,
      Text(l10n.planPayHint, style: Theme.of(context).textTheme.bodySmall),
    ];
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.subscription});

  final Subscription subscription;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final paused = subscription.isPaused;

    return Card(
      color: paused ? theme.colorScheme.errorContainer : null,
      child: ListTile(
        leading: Icon(
          paused ? Icons.pause_circle_outline_rounded : Icons.verified_outlined,
          color: paused ? theme.colorScheme.onErrorContainer : null,
        ),
        title: Text(
          context.l10n.subscriptionStatus(subscription, DateTime.now()),
          style: paused
              ? TextStyle(color: theme.colorScheme.onErrorContainer)
              : null,
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.offer,
    required this.months,
    required this.selected,
    required this.current,
    required this.onTap,
  });

  final PlanOffer offer;
  final int months;
  final bool selected;
  final bool current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final price = PesoFormatter.format(offer.priceFor(months));

    return Semantics(
      selected: selected,
      button: true,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: AppSpacing.cardPadding,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: selected ? theme.colorScheme.primary : null,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: AppSpacing.sm,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            l10n.planName(offer.plan),
                            style: theme.textTheme.titleMedium,
                          ),
                          if (current)
                            Chip(
                              label: Text(l10n.planCurrent),
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                      AppSpacing.gapXs,
                      Text(l10n.planPoints(offer.plan)),
                      AppSpacing.gapSm,
                      Text(
                        months == 12
                            ? l10n.planPerYear(price)
                            : l10n.planPerMonth(price),
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({required this.payment});

  final PaymentRecord payment;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final period = payment.months == 12 ? l10n.planOneYear : l10n.planOneMonth;

    return ListTile(
      leading: const Icon(Icons.receipt_outlined),
      title: Text(l10n.commonSeparator(l10n.planName(payment.plan), period)),
      subtitle: Text(DayFormatter.fullDate(payment.paidAt)),
      trailing: Text(
        PesoFormatter.format(payment.amount),
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}
