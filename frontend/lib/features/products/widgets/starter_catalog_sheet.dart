import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatting/peso_formatter.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/catalog/starter_catalog.dart';
import '../../../data/repositories/data_revision.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/feedback_messenger.dart';

/// A reviewable checklist of common products. Everything starts ticked,
/// because most stores carry most of these; unticking is the only work.
class StarterCatalogSheet extends ConsumerStatefulWidget {
  const StarterCatalogSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const StarterCatalogSheet(),
    );
  }

  @override
  ConsumerState<StarterCatalogSheet> createState() =>
      _StarterCatalogSheetState();
}

class _StarterCatalogSheetState extends ConsumerState<StarterCatalogSheet> {
  final Set<int> _chosen = {
    for (var i = 0; i < StarterCatalog.items.length; i++) i,
  };
  bool _adding = false;

  bool get _allChosen => _chosen.length == StarterCatalog.items.length;

  Future<void> _add() async {
    setState(() => _adding = true);

    final language = Localizations.localeOf(context).languageCode;
    final repository = ref.read(productRepositoryProvider);

    for (final index in _chosen.toList()..sort()) {
      final item = StarterCatalog.items[index];
      // No stock and no reorder level: the owner enters stock as deliveries
      // arrive, and low-stock warnings would only be noise until then.
      await repository.save(
        name: item.nameFor(language),
        costPrice: item.cost,
        sellingPrice: item.price,
        stockQuantity: 0,
        reorderLevel: 0,
        unitLabel: item.unit,
      );
    }

    ref.read(dataRevisionProvider.notifier).localWrite();
    if (!mounted) return;

    final count = _chosen.length;
    Navigator.pop(context);
    FeedbackMessenger.success(context, context.l10n.starterAdded(count));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final language = Localizations.localeOf(context).languageCode;

    // A fixed-height sheet rather than a draggable one: in a draggable sheet
    // the first scroll resizes the sheet instead of moving the list, which
    // feels unpredictable when working down a checklist.
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.88,
      child: Builder(
        builder: (context) {
          // Only the Add button is fixed; the explanation scrolls with the
          // list, so long text on a small phone cannot squeeze the list away.
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.starterTitle,
                              style: theme.textTheme.titleLarge,
                            ),
                            AppSpacing.gapXs,
                            Text(
                              l10n.starterIntro,
                              style: theme.textTheme.bodyMedium,
                            ),
                            AppSpacing.gapMd,
                            _PriceNotice(message: l10n.starterPricesNotice),
                            AppSpacing.gapSm,
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: CheckboxListTile(
                        value: _allChosen,
                        title: Text(l10n.starterAll),
                        onChanged: (_) => setState(() {
                          if (_allChosen) {
                            _chosen.clear();
                          } else {
                            _chosen.addAll(
                              List.generate(
                                StarterCatalog.items.length,
                                (i) => i,
                              ),
                            );
                          }
                        }),
                      ),
                    ),
                    const SliverToBoxAdapter(child: Divider(height: 1)),
                    SliverList.builder(
                      itemCount: StarterCatalog.items.length,
                      itemBuilder: (context, index) {
                        final item = StarterCatalog.items[index];
                        return CheckboxListTile(
                          value: _chosen.contains(index),
                          title: Text(item.nameFor(language)),
                          secondary: Text(
                            PesoFormatter.format(item.price),
                            style: theme.textTheme.titleMedium,
                          ),
                          onChanged: (checked) => setState(() {
                            if (checked ?? false) {
                              _chosen.add(index);
                            } else {
                              _chosen.remove(index);
                            }
                          }),
                        );
                      },
                    ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: FilledButton(
                    onPressed: _chosen.isEmpty || _adding ? null : _add,
                    child: _adding
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.starterAdd(_chosen.length)),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PriceNotice extends StatelessWidget {
  const _PriceNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: AppRadius.fieldAll,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: theme.colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
