import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/storage_mode.dart';
import '../../core/formatting/day_formatter.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_controller.dart';
import '../../data/repositories/sync_coordinator.dart';
import '../../shared/widgets/feedback_messenger.dart';
import '../../shared/widgets/page_body.dart';
import '../../shared/widgets/section_header.dart';
import '../authentication/auth_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(currentSessionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          PageBody(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionHeader(title: 'Appearance'),
                ThemeModeCard(
                  selected: ref.watch(themeControllerProvider),
                  onChanged: (mode) =>
                      ref.read(themeControllerProvider.notifier).select(mode),
                ),
                AppSpacing.gapXl,
                const SectionHeader(title: 'Your data'),
                if (session != null) _StorageCard(mode: session.mode),
                AppSpacing.gapXl,
                const SectionHeader(title: 'Account'),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.person_outline_rounded),
                        title: Text(session?.owner.fullName ?? 'Owner'),
                        subtitle: Text(
                          session?.owner.email ?? 'Offline profile',
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.logout_rounded),
                        title: const Text('Sign out'),
                        onTap: () => _confirmSignOut(context, ref),
                      ),
                    ],
                  ),
                ),
                AppSpacing.gapXl,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final isLocal = ref.read(currentSessionProvider)?.mode == StorageMode.local;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: Text(
          isLocal
              ? 'Your records are only on this phone. Signing out erases them.'
              : 'Your records stay safe in the cloud. You can sign back in '
                    'any time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await ref
        .read(authControllerProvider.notifier)
        .signOut(eraseLocalData: isLocal);
  }
}

class ThemeModeCard extends StatelessWidget {
  const ThemeModeCard({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final ThemeMode selected;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dark mode is easier at night; auto follows your phone.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            AppSpacing.gapMd,
            _selector(),
          ],
        ),
      ),
    );
  }

  Widget _selector() => Builder(
    builder: (context) => SizedBox(
      width: double.infinity,
      child: SegmentedButton<ThemeMode>(
        segments: const [
          ButtonSegment(value: ThemeMode.light, label: Text('Light')),
          ButtonSegment(value: ThemeMode.system, label: Text('Auto')),
          ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
        ],
        selected: {selected},
        showSelectedIcon: false,
        onSelectionChanged: (selection) => onChanged(selection.first),
      ),
    ),
  );
}

class _StorageCard extends ConsumerWidget {
  const _StorageCard({required this.mode});

  final StorageMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    if (mode == StorageMode.local) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.phone_android_rounded),
          title: const Text('Saved on this phone'),
          subtitle: const Text(
            'Nothing leaves this device. Create an account to add a backup.',
          ),
        ),
      );
    }

    final status = ref.watch(syncCoordinatorProvider);

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.cloud_done_outlined),
            title: const Text('Backed up to the cloud'),
            subtitle: Text(
              status.lastSyncedAt == null
                  ? 'Not synced yet'
                  : 'Last synced ${DayFormatter.relative(status.lastSyncedAt!)}',
            ),
          ),
          if (status.hasPendingWork) ...[
            const Divider(height: 1),
            ListTile(
              leading: Icon(
                Icons.cloud_upload_outlined,
                color: theme.colorScheme.secondary,
              ),
              title: Text('${status.pendingCount} waiting to upload'),
              subtitle: const Text('These will go up when you have signal.'),
            ),
          ],
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.sync_rounded),
            title: const Text('Sync now'),
            onTap: () async {
              await ref.read(syncCoordinatorProvider.notifier).syncNow();
              if (context.mounted) {
                FeedbackMessenger.success(context, 'Sync finished.');
              }
            },
          ),
        ],
      ),
    );
  }
}
