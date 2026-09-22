import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/route_paths.dart';
import '../../core/formatting/peso_formatter.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/repositories/data_revision.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/sale_repository.dart';
import '../../l10n/l10n.dart';
import '../../shared/widgets/feedback_messenger.dart';
import '../../shared/widgets/page_body.dart';
import '../scanning/barcode_scanner.dart';
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

  /// The last code scanned that matched no product, offered for adding once
  /// the camera closes.
  String? _unknownCode;

  double get _typedAmount => double.tryParse(_typed) ?? 0;

  /// Checkout scanning: every code either lands in the cart or is noted as
  /// unknown. Returns the line shown under the camera.
  Future<void> _scan() async {
    final l10n = context.l10n;
    final products = ref.read(productRepositoryProvider);
    final cart = ref.read(saleCartProvider.notifier);
    _unknownCode = null;

    await ref
        .read(barcodeScannerProvider)
        .scanContinuously(
          context,
          onCode: (code) async {
            final product = await products.findByBarcode(code);
            if (product == null) {
              _unknownCode = code;
              return l10n.scanUnknownTitle;
            }
            cart.addProduct(product);
            return l10n.scanAdded(product.name);
          },
        );

    final unknown = _unknownCode;
    if (unknown != null && mounted) await _offerToAdd(unknown);
  }

  Future<void> _offerToAdd(String code) async {
    final l10n = context.l10n;
    final add = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.scanUnknownTitle),
        content: Text(l10n.scanUnknownMessage(code)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.scanAddProduct),
          ),
        ],
      ),
    );

    if (add == true && mounted) {
      await context.push(
        Uri(
          path: RoutePaths.productEditor,
          queryParameters: {'barcode': code},
        ).toString(),
      );
    }
  }

  void _pickProduct() {
    ProductPickerSheet.show(
      context,
      onSelected: (product) {
        ref.read(saleCartProvider.notifier).addProduct(product);
        FeedbackMessenger.success(
          context,
          context.l10n.saleProductAdded(product.name),
        );
      },
    );
  }

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
      FeedbackMessenger.warn(context, context.l10n.saleNeedsSomething);
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
      FeedbackMessenger.success(context, context.l10n.saleRecorded);
      context.pop();
    } on Object {
      if (!mounted) return;
      setState(() => _saving = false);
      FeedbackMessenger.error(context, context.l10n.saleSaveFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(saleCartProvider);
    final cartTotal = cart.fold<double>(0, (sum, line) => sum + line.total);
    final total = cartTotal + _typedAmount;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.saleTitle)),
      body: SafeArea(
        child: PageBody(
          maxWidth: 560,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            0,
          ),
          // Everything above the Save button scrolls if it has to, so no
          // screen size or text size can push content off the edge.
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _TotalDisplay(total: total, typed: _typed),
                ),
              ),
              // In the body rather than the app bar: with large text two
              // labelled actions squeezed the title until it vanished, and
              // down here they are within reach of the cashier's thumb.
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Row(
                    children: [
                      if (ref.watch(barcodeScannerProvider).isAvailable) ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _scan,
                            icon: const Icon(Icons.qr_code_scanner_rounded),
                            label: Text(context.l10n.scanAction),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                      ],
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickProduct,
                          icon: const Icon(Icons.add_rounded),
                          label: Text(context.l10n.saleProduct),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverList.builder(
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
              SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const SizedBox(height: AppSpacing.md),
                    Flexible(
                      child: AmountKeypad(
                        onDigit: _appendDigit,
                        onBackspace: _backspace,
                        onClear: () => setState(() => _typed = ''),
                      ),
                    ),
                    AppSpacing.gapLg,
                    PaymentMethodPicker(
                      selected: ref.watch(selectedPaymentMethodProvider),
                      onChanged: (method) => ref
                          .read(selectedPaymentMethodProvider.notifier)
                          .select(method),
                    ),
                    AppSpacing.gapMd,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      // Pinned, so the one action this screen exists for is never scrolled
      // out of reach.
      bottomNavigationBar: SafeArea(
        child: PageBody(
          maxWidth: 560,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(60),
            ),
            child: _saving
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    context.l10n.saleSaveAmount(PesoFormatter.format(total)),
                  ),
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
        Text(context.l10n.saleTotal, style: theme.textTheme.labelMedium),
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
          Text(
            context.l10n.saleTyping('₱$typed'),
            style: theme.textTheme.bodySmall,
          ),
      ],
    );
  }
}
