import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../data/models/staff_member.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/feedback_messenger.dart';

/// The one time a join code is shown. It is kept only as a hash, so if the
/// owner closes this without sharing it, they make a new one.
class InviteCodeSheet extends StatelessWidget {
  const InviteCodeSheet({
    super.key,
    required this.staffName,
    required this.storeName,
    required this.invite,
  });

  final String staffName;
  final String storeName;
  final JoinInvite invite;

  static Future<void> show(
    BuildContext context, {
    required String staffName,
    required String storeName,
    required JoinInvite invite,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => InviteCodeSheet(
        staffName: staffName,
        storeName: storeName,
        invite: invite,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.inviteTitle(staffName),
              style: theme.textTheme.titleLarge,
            ),
            AppSpacing.gapSm,
            Text(l10n.inviteSteps(staffName)),
            AppSpacing.gapLg,
            Container(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: SelectableText(
                  invite.code,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 4,
                  ),
                ),
              ),
            ),
            AppSpacing.gapSm,
            Text(
              l10n.inviteExpires(l10n.relativeDay(invite.expiresAt)),
              style: theme.textTheme.bodySmall,
            ),
            AppSpacing.gapLg,
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.sm,
              children: [
                FilledButton.icon(
                  onPressed: () => SharePlus.instance.share(
                    ShareParams(
                      text: l10n.inviteShareText(storeName, invite.code),
                    ),
                  ),
                  icon: const Icon(Icons.share_rounded),
                  label: Text(l10n.inviteShare),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: invite.code));
                    if (context.mounted) {
                      FeedbackMessenger.success(context, l10n.inviteCopied);
                    }
                  },
                  icon: const Icon(Icons.copy_rounded),
                  label: Text(l10n.inviteCopy),
                ),
              ],
            ),
            AppSpacing.gapMd,
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.inviteDone),
            ),
          ],
        ),
      ),
    );
  }
}
