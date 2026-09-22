import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/route_paths.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/l10n.dart';
import '../backup/restore_flow.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/storage_mode_card.dart';

/// The first screen a new device sees. It asks one question - where should
/// your records live - in language an owner can answer without help.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return AuthScaffold(
      title: l10n.tagline,
      subtitle: l10n.welcomeSubtitle,
      children: [
        StorageModeCard(
          icon: Icons.phone_android_rounded,
          title: l10n.welcomeLocalTitle,
          description: l10n.welcomeLocalDescription,
          badge: l10n.welcomeStartHere,
          bullets: [
            l10n.welcomeLocalPoint1,
            l10n.welcomeLocalPoint2,
            l10n.welcomeLocalPoint3,
          ],
          onTap: () => context.push(RoutePaths.localSetup),
        ),
        AppSpacing.gapLg,
        StorageModeCard(
          icon: Icons.cloud_sync_rounded,
          title: l10n.welcomeCloudTitle,
          description: l10n.welcomeCloudDescription,
          bullets: [
            l10n.welcomeCloudPoint1,
            l10n.welcomeCloudPoint2,
            l10n.welcomeCloudPoint3,
          ],
          onTap: () => context.push(RoutePaths.signUp),
        ),
        AppSpacing.gapXl,
        TextButton(
          onPressed: () => context.push(RoutePaths.signIn),
          child: Text(l10n.welcomeHaveAccount),
        ),
        TextButton(
          onPressed: () => context.push(RoutePaths.joinStore),
          child: Text(l10n.welcomeJoinStaff),
        ),
        // A phone that was lost or replaced: bring the store back from the
        // backup file the owner saved.
        TextButton(
          onPressed: () => restoreFromBackup(context, ref),
          child: Text(l10n.backupRestore),
        ),
      ],
    );
  }
}
