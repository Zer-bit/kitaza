import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/route_paths.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/debouncer.dart';
import '../../data/models/product.dart';
import '../../shared/widgets/async_content.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/page_body.dart';
import 'product_controller.dart';
import 'widgets/product_tile.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RoutePaths.productEditor),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add product'),
      ),
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
              decoration: const InputDecoration(
                hintText: 'Search products',
                prefixIcon: Icon(Icons.search_rounded),
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
                    title: 'No products yet',
                    message:
                        'Adding your regular items makes each sale one tap, '
                        'and lets Kitaza tell you which ones actually earn.',
                    actionLabel: 'Add your first product',
                    onAction: () => context.push(RoutePaths.productEditor),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 96),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) => ProductTile(
                    product: items[index],
                    onTap: () => context.push(
                      '${RoutePaths.productEditor}?id=${items[index].id}',
                    ),
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
