import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatting/quantity_formatter.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/access_grant.dart';
import '../../data/models/product.dart';
import '../../data/repositories/data_revision.dart';
import '../../data/repositories/product_repository.dart';
import '../../l10n/l10n.dart';
import '../../shared/widgets/feedback_messenger.dart';
import '../../shared/widgets/page_body.dart';
import '../authentication/auth_controller.dart';
import '../scanning/barcode_scanner.dart';
import 'product_controller.dart';
import 'widgets/margin_preview.dart';

/// One screen for both new and existing products. `productId` decides which.
class ProductEditorScreen extends ConsumerStatefulWidget {
  const ProductEditorScreen({super.key, this.productId, this.initialBarcode});

  final String? productId;

  /// Pre-filled when the owner arrives here from scanning an unknown code.
  final String? initialBarcode;

  @override
  ConsumerState<ProductEditorScreen> createState() =>
      _ProductEditorScreenState();
}

class _ProductEditorScreenState extends ConsumerState<ProductEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  late final _barcode = TextEditingController(text: widget.initialBarcode);
  final _cost = TextEditingController();
  final _price = TextEditingController();
  final _stock = TextEditingController(text: '0');
  final _reorder = TextEditingController(text: '0');

  bool _loaded = false;

  /// Carried over unchanged when editing. Saving used to reset it to "pc",
  /// quietly turning a per-kilo product into a per-piece one.
  String _unitLabel = 'pc';
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _barcode.dispose();
    _cost.dispose();
    _price.dispose();
    _stock.dispose();
    _reorder.dispose();
    super.dispose();
  }

  void _fillFrom(Product product) {
    if (_loaded) return;
    _loaded = true;

    _name.text = product.name;
    _barcode.text = product.barcode ?? '';
    _unitLabel = product.unitLabel;
    _cost.text = product.costPrice.toStringAsFixed(2);
    _price.text = product.sellingPrice.toStringAsFixed(2);
    _stock.text = QuantityFormatter.exact(product.stockQuantity);
    _reorder.text = QuantityFormatter.exact(product.reorderLevel);
  }

  Future<void> _scanBarcode() async {
    final code = await ref.read(barcodeScannerProvider).scanOnce(context);
    if (code != null && mounted) setState(() => _barcode.text = code);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      await ref
          .read(productRepositoryProvider)
          .save(
            id: widget.productId,
            name: _name.text,
            // A phone that cannot see costs holds zero for them; the server
            // keeps the owner's figure whatever is sent.
            costPrice: double.tryParse(_cost.text) ?? 0,
            sellingPrice: double.parse(_price.text),
            stockQuantity: double.tryParse(_stock.text) ?? 0,
            reorderLevel: double.tryParse(_reorder.text) ?? 0,
            unitLabel: _unitLabel,
            barcode: _barcode.text,
          );

      ref.read(dataRevisionProvider.notifier).localWrite();

      if (!mounted) return;
      FeedbackMessenger.success(context, context.l10n.productSaved);
      context.pop();
    } on Object {
      if (!mounted) return;
      setState(() => _saving = false);
      FeedbackMessenger.error(context, context.l10n.productSaveFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.productId == null
        ? null
        : ref.watch(productByIdProvider(widget.productId!)).value;

    if (existing != null) _fillFrom(existing);
    final seesCosts = ref.watch(canProvider(Permission.viewProfit));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.productId == null
              ? context.l10n.productAdd
              : context.l10n.productEdit,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: PageBody(
            maxWidth: 560,
            child: Form(
              key: _formKey,
              onChanged: () => setState(() {}),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: context.l10n.productName,
                      hintText: context.l10n.productNameHint,
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? context.l10n.commonEnterName
                        : null,
                  ),
                  AppSpacing.gapLg,
                  TextFormField(
                    controller: _barcode,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: context.l10n.productBarcode,
                      suffixIcon: ref.watch(barcodeScannerProvider).isAvailable
                          ? IconButton(
                              onPressed: _scanBarcode,
                              icon: const Icon(Icons.qr_code_scanner_rounded),
                              tooltip: context.l10n.scanAction,
                            )
                          : null,
                    ),
                  ),
                  AppSpacing.gapLg,
                  if (seesCosts) ...[
                    Row(
                      children: [
                        Expanded(
                          child: _MoneyInput(
                            controller: _cost,
                            label: context.l10n.productCost,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _MoneyInput(
                            controller: _price,
                            label: context.l10n.productPrice,
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.gapMd,
                    MarginPreview(
                      cost: double.tryParse(_cost.text) ?? 0,
                      price: double.tryParse(_price.text) ?? 0,
                    ),
                  ] else ...[
                    _MoneyInput(
                      controller: _price,
                      label: context.l10n.productPrice,
                    ),
                    AppSpacing.gapSm,
                    Text(
                      context.l10n.productCostSetByOwner,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  AppSpacing.gapLg,
                  Row(
                    children: [
                      Expanded(
                        child: _NumberInput(
                          controller: _stock,
                          label: context.l10n.productStock,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _NumberInput(
                          controller: _reorder,
                          label: context.l10n.productReorder,
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.gapXl,
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
                        : Text(context.l10n.productSave),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MoneyInput extends StatelessWidget {
  const _MoneyInput({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label, prefixText: '₱ '),
      validator: (value) {
        final parsed = double.tryParse(value ?? '');
        if (parsed == null || parsed < 0) return context.l10n.commonEnterAmount;
        return null;
      },
    );
  }
}

class _NumberInput extends StatelessWidget {
  const _NumberInput({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label),
    );
  }
}
