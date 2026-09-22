import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatting/peso_formatter.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/repositories/data_revision.dart';
import '../../data/repositories/sale_repository.dart';
import '../../shared/widgets/feedback_messenger.dart';
import '../../shared/widgets/page_body.dart';
import 'sale_cart_controller.dart';
import 'widgets/amount_keypad.dart';
import 'widgets/cart_line_tile.dart';
import 'widgets/payment_method_picker.dart';
import 'widgets/product_picker_sheet.dart';

/// The five-second path: open, tap the amount, press Save. Everything else -
/// picking products, changing payment method, adding a note - is optional and
/// stays out of the way until asked for.
class RecordSaleScreen extends ConsumerStatefulWidget {
  const RecordSaleScreen({super.key});

  @override
  ConsumerState<RecordSaleScreen> createState() => _RecordSaleScreenState();
}

class _RecordSaleScreenState extends ConsumerState<RecordSaleScreen> {
  String _typed = '';
  bool _saving = false;

  double get _typedAmount => double.tryParse(_typed) ?? 0;

  void _appendDigit(String digit) {
    if (digit == '.' && _typed.contains('.')) return;
    if (_typed.contains('.') && _typed.split('.').last.length >= 2) return;

    setState(() => _typed = _typed == '0' ? digit : '$_typed$digit');
  }

  void _backspace() {
    if (_typed.isEmpty) return;
    setState(() => _typed = _typed.substring(0, _typed.length - 1));
  }

  Future<void> _save() async {
    final cart = <CartLine>[...ref.read(saleCartProvider)];

    // A typed amount that was never added is still clearly part of the sale.
    if (_typedAmount > 0) cart.add(CartLine.quick(_typedAmount));

    if (cart.isEmpty) {
      FeedbackMessenger.warn(
        context,
        'Enter an amount or pick a product first.',
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await ref
          .read(saleRepositoryProvider)
          .record(
            cart: cart,
            paymentMethod: ref.read(selectedPaymentMethodProvider),
          );

      ref.read(dataRevisionProvider.notifier).localWrite();
      ref.read(saleCartProvider.notifier).clear();

      if (!mounted) return;
      FeedbackMessenger.success(context, 'Sale recorded.');
      context.pop();
    } on Object {
      if (!mounted) return;
      setState(() => _saving = false);
      FeedbackMessenger.error(
        context,
        'Could not save the sale. Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(saleCartProvider);
    final cartTotal = cart.fold<double>(0, (sum, line) => sum + line.total);
    final total = cartTotal + _typedAmount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add sale'),
        actions: [
          TextButton.icon(
            onPressed: () => ProductPickerSheet.show(
              context,
              onSelected: (product) {
                ref.read(saleCartProvider.notifier).addProduct(product);
                FeedbackMessenger.success(context, '${product.name} added.');
              },
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Product'),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(
        child: PageBody(
          maxWidth: 560,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TotalDisplay(total: total, typed: _typed),
              AppSpacing.gapLg,
              if (cart.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    itemCount: cart.length,
                    itemBuilder: (context, index) => CartLineTile(
                      line: cart[index],
                      onQuantityChanged: (quantity) => ref
                          .read(saleCartProvider.notifier)
                          .changeQuantity(cart[index].key, quantity),
                      onRemove: () => ref
                          .read(saleCartProvider.notifier)
                          .remove(cart[index].key),
                    ),
                  ),
                )
              else
                const Spacer(),
              AmountKeypad(
                onDigit: _appendDigit,
                onBackspace: _backspace,
                onClear: () => setState(() => _typed = ''),
              ),
              AppSpacing.gapLg,
              PaymentMethodPicker(
                selected: ref.watch(selectedPaymentMethodProvider),
                onChanged: (method) => ref
                    .read(selectedPaymentMethodProvider.notifier)
                    .select(method),
              ),
              AppSpacing.gapLg,
              FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(60),
                ),
                child: _saving
                    ? const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('Save ${PesoFormatter.format(total)}'),
              ),
              AppSpacing.gapMd,
            ],
          ),
        ),
      ),
    );
  }
}

class _TotalDisplay extends StatelessWidget {
  const _TotalDisplay({required this.total, required this.typed});

  final double total;
  final String typed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Total', style: theme.textTheme.labelMedium),
        AppSpacing.gapXs,
        AnimatedSwitcher(
          duration: AppMotion.quick,
          child: Text(
            PesoFormatter.format(total),
            key: ValueKey(total),
            style: AppTypography.money(theme.colorScheme.primary, 40),
          ),
        ),
        if (typed.isNotEmpty)
          Text('Typing ₱$typed', style: theme.textTheme.bodySmall),
      ],
    );
  }
}
