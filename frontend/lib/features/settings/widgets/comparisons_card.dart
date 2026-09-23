import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n.dart';
import '../../../shared/widgets/feedback_messenger.dart';
import '../../authentication/auth_controller.dart';

/// The owner's choice about joining the anonymous comparisons. Off means
/// their figures are not pooled, and they see no comparisons either.
class ComparisonsCard extends ConsumerWidget {
  const ComparisonsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final session = ref.watch(currentSessionProvider);
    if (session == null) return const SizedBox.shrink();
    final sharing = session.store.shareBenchmarks;

    return Card(
      child: SwitchListTile(
        secondary: const Icon(Icons.groups_outlined),
        value: sharing,
        title: Text(l10n.benchmarkSharingTitle),
        subtitle: Text(
          sharing ? l10n.benchmarkSharingHint : l10n.benchmarkSharingOff,
        ),
        isThreeLine: true,
        onChanged: (value) async {
          try {
            await ref
                .read(authControllerProvider.notifier)
                .setBenchmarkSharing(value);
          } on Object catch (error) {
            if (context.mounted) {
              FeedbackMessenger.error(context, l10n.failure(error));
            }
          }
        },
      ),
    );
  }
}
