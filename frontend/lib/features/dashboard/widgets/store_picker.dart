import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/feedback_messenger.dart';
import '../../authentication/auth_controller.dart';

/// Switches between an owner's stores from the dashboard. Each store's
/// records stay on the phone, so this is instant and works offline.
class StorePicker extends ConsumerWidget {
  const StorePicker({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => const StorePicker(),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final session = ref.watch(currentSessionProvider);
    if (session == null) return const SizedBox.shrink();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Text(
                l10n.storesPickerTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            for (final store in session.stores)
              ListTile(
                leading: Icon(
                  store.id == session.store.id
                      ? Icons.storefront_rounded
                      : Icons.storefront_outlined,
                ),
                title: Text(store.name),
                selected: store.id == session.store.id,
                trailing: store.id == session.store.id
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () async {
                  if (store.id != session.store.id) {
                    await ref
                        .read(authControllerProvider.notifier)
                        .switchStore(store);
                    if (!context.mounted) return;
                    FeedbackMessenger.success(
                      context,
                      l10n.storesSwitched(store.name),
                    );
                  }
                  if (context.mounted) Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }
}
