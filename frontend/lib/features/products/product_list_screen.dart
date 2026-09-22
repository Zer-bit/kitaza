import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/route_paths.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/debouncer.dart';
import '../../data/models/access_grant.dart';
import '../../data/models/product.dart';
import '../../l10n/l10n.dart';
import '../../shared/widgets/async_content.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/page_body.dart';
import '../authentication/auth_controller.dart';
import 'product_controller.dart';
import 'widgets/product_tile.dart';
import 'widgets/starter_catalog_sheet.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final _debouncer = Debouncer();
  final _search = TextEditingController();

  @override
  void dispose() {
    _debouncer.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productListProvider);
    final canManage = ref.watch(canProvider(Permission.manageProducts));
    final seesCosts = ref.watch(canProvider(Permission.viewProfit));

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.navProducts)),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => context.push(RoutePaths.productEditor),
              icon: const Icon(Icons.add_rounded),
              label: Text(context.l10n.productAdd),
            )
          : null,
      body: Column(
        children: [
          PageBody(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: context.l10n.productSearch,
                prefixIcon: const Icon(Icons.search_rounded),
              ),
              onChanged: (value) => _debouncer.run(
                () =>
                    ref.read(productSearchTermProvider.notifier).update(value),
              ),
            ),
          ),
          Expanded(
            child: AsyncContent<List<Product>>(
              value: products,
              onRetry: () => ref.invalidate(productListProvider),
              builder: (items) {
                if (items.isEmpty) {
                  return EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: context.l10n.productEmptyTitle,
                    message: context.l10n.productEmptyMessage,
                    actionLabel: canManage ? context.l10n.starterOffer : null,
                    onAction: canManage
                        ? () => StarterCatalogSheet.show(context)
                        : null,
                    secondaryActionLabel: canManage
                        ? context.l10n.productEmptyAction
                        : null,
                    onSecondaryAction: canManage
                        ? () => context.push(RoutePaths.productEditor)
                        : null,
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 96),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) => ProductTile(
                    product: items[index],
                    showMargin: seesCosts,
                    onTap: canManage
                        ? () => context.push(
                            '${RoutePaths.productEditor}?id=${items[index].id}',
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
