import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/route_paths.dart';
import '../../../l10n/l10n.dart';
import '../../authentication/auth_controller.dart';
import '../../billing/billing_text.dart';

/// The owner's way into staff, devices and the activity log.
class TeamCard extends StatelessWidget {
  const TeamCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Card(
      child: Column(
        children: [
          const _PlanTile(),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.groups_2_outlined),
            title: Text(l10n.staffTitle),
            subtitle: Text(l10n.staffTileHint),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(RoutePaths.staff),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.devices_other_rounded),
            title: Text(l10n.devicesTitle),
            subtitle: Text(l10n.devicesTileHint),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(RoutePaths.devices),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.history_rounded),
            title: Text(l10n.activityTitle),
            subtitle: Text(l10n.activityTileHint),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(RoutePaths.activity),
          ),
        ],
      ),
    );
  }
}

/// For an offline store: what staff and more stores need, and the way there.
class TeamNeedsCloudCard extends StatelessWidget {
  const TeamNeedsCloudCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Card(
      child: ListTile(
        leading: const Icon(Icons.groups_2_outlined),
        title: Text(l10n.teamLocalTitle),
        subtitle: Text(l10n.teamLocalMessage),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => context.push(RoutePaths.cloudUpgrade),
      ),
    );
  }
}

class _PlanTile extends ConsumerWidget {
  const _PlanTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final subscription = ref.watch(subscriptionProvider);

    return ListTile(
      leading: const Icon(Icons.workspace_premium_outlined),
      title: Text(l10n.settingsPlan),
      subtitle: Text(l10n.subscriptionStatus(subscription, DateTime.now())),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => context.push(RoutePaths.plan),
    );
  }
}
