import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatting/peso_formatter.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/debouncer.dart';
import '../../../data/models/product.dart';
import '../../../shared/widgets/async_content.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../products/product_controller.dart';

/// Bottom sheet for picking catalogue items into the cart. Stays open after a
/// tap so a multi-item basket is a few taps rather than a few round trips.
class ProductPickerSheet extends ConsumerStatefulWidget {
  const ProductPickerSheet({super.key, required this.onSelected});

  final ValueChanged<Product> onSelected;

  static Future<void> show(
    BuildContext context, {
    required ValueChanged<Product> onSelected,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => ProductPickerSheet(onSelected: onSelected),
    );
  }

  @override
  ConsumerState<ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends ConsumerState<ProductPickerSheet> {
  final _debouncer = Debouncer();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _debouncer.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productListProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
          ),
          child: Column(
            children: [
              TextField(
                controller: _controller,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search product or scan code',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
                onChanged: (value) => _debouncer.run(
                  () => ref
                      .read(productSearchTermProvider.notifier)
                      .update(value),
                ),
              ),
              AppSpacing.gapMd,
              Expanded(
                child: AsyncContent<List<Product>>(
                  value: products,
                  builder: (items) {
                    if (items.isEmpty) {
                      return const EmptyState(
                        icon: Icons.inventory_2_outlined,
                        title: 'No products yet',
                        message:
                            'You can still record the sale by typing the amount '
                            'on the keypad.',
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      itemCount: items.length,
                      itemExtent: 68,
                      itemBuilder: (context, index) => _ProductRow(
                        product: items[index],
                        onTap: () => widget.onSelected(items[index]),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      onTap: onTap,
      title: Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        product.isOutOfStock
            ? 'Out of stock'
            : '${product.stockQuantity.toStringAsFixed(0)} ${product.unitLabel} left',
        style: theme.textTheme.bodySmall?.copyWith(
          color: product.isLowOnStock ? theme.colorScheme.error : null,
        ),
      ),
      trailing: Text(
        PesoFormatter.format(product.sellingPrice),
        style: theme.textTheme.titleMedium,
      ),
    );
  }
}
