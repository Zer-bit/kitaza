import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../data/models/signed_in_device.dart';
import '../../data/remote/team_api.dart';
import '../../l10n/l10n.dart';
import '../../shared/widgets/async_content.dart';
import '../../shared/widgets/feedback_messenger.dart';
import '../../shared/widgets/page_body.dart';
import 'team_providers.dart';

/// Every phone that can open the owner's stores, with a way to sign out the
/// one that was lost or belongs to someone who has left.
class DevicesScreen extends ConsumerWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final devices = ref.watch(signedInDevicesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.devicesTitle)),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(signedInDevicesProvider.future),
        child: AsyncContent<List<SignedInDevice>>(
          value: devices,
          onRetry: () => ref.invalidate(signedInDevicesProvider),
          builder: (list) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              PageBody(
                child: Text(
                  l10n.devicesIntro,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              for (final device in list) ...[
                _DeviceTile(device: device),
                const Divider(height: 1),
              ],
              AppSpacing.gapXl,
            ],
          ),
        ),
      ),
    );
  }
}

class _DeviceTile extends ConsumerWidget {
  const _DeviceTile({required this.device});

  final SignedInDevice device;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final who = device.isStaff
        ? l10n.devicesStaff(device.memberName)
        : l10n.devicesYou;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      leading: Icon(
        device.isCurrent
            ? Icons.smartphone_rounded
            : Icons.phone_android_rounded,
      ),
      title: Text(device.deviceName),
      subtitle: Text(
        '$who\n${device.isCurrent ? l10n.devicesThisPhone : l10n.devicesLastActive(l10n.relativeDay(device.lastSeenAt))}',
      ),
      isThreeLine: true,
      // This phone signs out from Settings, where the warning about unsent
      // entries lives.
      trailing: device.isCurrent
          ? null
          : TextButton(
              onPressed: () => _signOut(context, ref),
              child: Text(l10n.devicesSignOut),
            ),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.devicesSignOutTitle(device.deviceName)),
        content: Text(l10n.devicesSignOutMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.devicesSignOut),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(teamApiProvider).signOutDevice(device.id);
      ref.invalidate(signedInDevicesProvider);
      if (context.mounted) {
        FeedbackMessenger.success(
          context,
          l10n.devicesSignedOut(device.deviceName),
        );
      }
    } on Object catch (error) {
      if (context.mounted) {
        FeedbackMessenger.error(context, l10n.failure(error));
      }
    }
  }
}
