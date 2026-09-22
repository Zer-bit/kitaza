import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../data/models/staff_member.dart';
import '../../l10n/l10n.dart';
import '../../shared/widgets/async_content.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/feedback_messenger.dart';
import '../authentication/auth_controller.dart';
import 'staff_editor_screen.dart';
import 'team_providers.dart';
import 'widgets/invite_code_sheet.dart';

/// The people who help at the counter, and what each may do.
class StaffScreen extends ConsumerWidget {
  const StaffScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final staff = ref.watch(staffListProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.staffTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context, ref),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: Text(l10n.staffAdd),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(staffListProvider.future),
        child: AsyncContent<List<StaffMember>>(
          value: staff,
          onRetry: () => ref.invalidate(staffListProvider),
          builder: (members) {
            if (members.isEmpty) {
              return EmptyState(
                icon: Icons.groups_2_outlined,
                title: l10n.staffEmptyTitle,
                message: l10n.staffEmptyMessage,
                actionLabel: l10n.staffAdd,
                onAction: () => _edit(context, ref),
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 96),
              itemCount: members.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) => _StaffTile(
                member: members[index],
                onTap: () => _edit(context, ref, members[index]),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref, [
    StaffMember? member,
  ]) async {
    final outcome = await StaffEditorScreen.open(context, existing: member);
    if (outcome == null || !context.mounted) return;

    ref.invalidate(staffListProvider);
    final l10n = context.l10n;
    switch (outcome) {
      case InviteMade(:final name, :final invite):
        await InviteCodeSheet.show(
          context,
          staffName: name,
          storeName: ref.read(currentSessionProvider)?.store.name ?? '',
          invite: invite,
        );
      case StaffSaved():
        FeedbackMessenger.success(context, l10n.staffSaved);
      case StaffRemoved(:final name):
        FeedbackMessenger.success(context, l10n.staffRemoved(name));
    }
  }
}

class _StaffTile extends StatelessWidget {
  const _StaffTile({required this.member, required this.onTap});

  final StaffMember member;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final status = member.signedInDevices == 0 && member.hasPendingInvite
        ? l10n.staffCodeWorksUntil(l10n.relativeDay(member.inviteExpiresAt!))
        : l10n.staffDevices(member.signedInDevices);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      leading: CircleAvatar(
        child: Text(
          member.displayName.characters.first.toUpperCase(),
          semanticsLabel: '',
        ),
      ),
      title: Text(member.displayName),
      subtitle: Text('${l10n.staffAbilities(member.permissions)}\n$status'),
      isThreeLine: true,
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
