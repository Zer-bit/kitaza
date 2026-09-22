import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/route_paths.dart';
import '../../core/theme/app_spacing.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/storage_mode_card.dart';

/// The first screen a new device sees. It asks one question - where should
/// your records live - in language an owner can answer without help.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Know where every peso goes',
      subtitle:
          'Pick how you want to keep your records. You can change this later.',
      children: [
        StorageModeCard(
          icon: Icons.phone_android_rounded,
          title: 'Just this phone',
          description: 'Everything stays on this device. No account needed.',
          isRecommended: true,
          bullets: const [
            'Works with no load and no signal',
            'Nothing to pay, nothing to sign up for',
            'Only this device can see your records',
          ],
          onTap: () => context.push(RoutePaths.localSetup),
        ),
        AppSpacing.gapLg,
        StorageModeCard(
          icon: Icons.cloud_sync_rounded,
          title: 'Save to the cloud',
          description: 'Still works offline, and backs up so you never lose your history.',
          bullets: const [
            'Use the same store on your phone and tablet',
            'Safe if your phone is lost or broken',
            'Your helper can record sales while you are out',
          ],
          onTap: () => context.push(RoutePaths.signUp),
        ),
        AppSpacing.gapXl,
        TextButton(
          onPressed: () => context.push(RoutePaths.signIn),
          child: const Text('I already have an account'),
        ),
      ],
    );
  }
}
