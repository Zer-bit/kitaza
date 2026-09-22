import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_controller.dart';
import '../../shared/widgets/page_body.dart';
import '../../shared/widgets/section_header.dart';
import '../authentication/auth_controller.dart';
import 'widgets/account_card.dart';
import 'widgets/storage_status_card.dart';
import 'widgets/theme_mode_selector.dart';

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
                Card(
                  child: Padding(
                    padding: AppSpacing.cardPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dark mode is easier at night; Auto follows your phone.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        AppSpacing.gapMd,
                        SizedBox(
                          width: double.infinity,
                          child: ThemeModeSelector(
                            selected: ref.watch(themeControllerProvider),
                            onChanged: (mode) => ref
                                .read(themeControllerProvider.notifier)
                                .select(mode),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                AppSpacing.gapXl,
                const SectionHeader(title: 'Your data'),
                const StorageStatusCard(),
                AppSpacing.gapXl,
                const SectionHeader(title: 'Account'),
                if (session != null) AccountCard(session: session),
                AppSpacing.gapXl,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
