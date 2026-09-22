import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../l10n/l10n.dart';
import '../../products/product_controller.dart';
import '../../products/widgets/starter_catalog_sheet.dart';

/// Shown on the dashboard only while the store has no products at all - the
/// first minutes after setup - and gone for good once any product exists.
class StarterPromptCard extends ConsumerWidget {
  const StarterPromptCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(productCountProvider).value;
    if (count == null || count > 0) return const SizedBox.shrink();

    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Card(
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      l10n.starterPromptTitle,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              AppSpacing.gapSm,
              Text(
                l10n.starterPromptMessage,
                style: theme.textTheme.bodyMedium,
              ),
              AppSpacing.gapMd,
              OutlinedButton(
                onPressed: () => StarterCatalogSheet.show(context),
                child: Text(l10n.starterOffer),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
