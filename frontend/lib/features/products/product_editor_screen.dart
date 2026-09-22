import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatting/quantity_formatter.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/product.dart';
import '../../data/repositories/data_revision.dart';
import '../../data/repositories/product_repository.dart';
import '../../shared/widgets/feedback_messenger.dart';
import '../../shared/widgets/page_body.dart';
import 'product_controller.dart';
import 'widgets/margin_preview.dart';

/// One screen for both new and existing products. `productId` decides which.
class ProductEditorScreen extends ConsumerStatefulWidget {
  const ProductEditorScreen({super.key, this.productId});

  final String? productId;

  @override
  ConsumerState<ProductEditorScreen> createState() =>
      _ProductEditorScreenState();
}

class _ProductEditorScreenState extends ConsumerState<ProductEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _cost = TextEditingController();
  final _price = TextEditingController();
  final _stock = TextEditingController(text: '0');
  final _reorder = TextEditingController(text: '0');

  bool _loaded = false;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
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
    _cost.text = product.costPrice.toStringAsFixed(2);
    _price.text = product.sellingPrice.toStringAsFixed(2);
    _stock.text = QuantityFormatter.exact(product.stockQuantity);
    _reorder.text = QuantityFormatter.exact(product.reorderLevel);
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
            costPrice: double.parse(_cost.text),
            sellingPrice: double.parse(_price.text),
            stockQuantity: double.tryParse(_stock.text) ?? 0,
            reorderLevel: double.tryParse(_reorder.text) ?? 0,
          );

      ref.read(dataRevisionProvider.notifier).localWrite();

      if (!mounted) return;
      FeedbackMessenger.success(context, 'Product saved.');
      context.pop();
    } on Object {
      if (!mounted) return;
      setState(() => _saving = false);
      FeedbackMessenger.error(context, 'Could not save the product.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.productId == null
        ? null
        : ref.watch(productByIdProvider(widget.productId!)).value;

    if (existing != null) _fillFrom(existing);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.productId == null ? 'Add product' : 'Edit product'),
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
                    decoration: const InputDecoration(
                      labelText: 'Product name',
                      hintText: 'Lucky Me Pancit Canton',
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'Enter a name'
                        : null,
                  ),
                  AppSpacing.gapLg,
                  Row(
                    children: [
                      Expanded(
                        child: _MoneyInput(
                          controller: _cost,
                          label: 'Cost (puhunan)',
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _MoneyInput(
                          controller: _price,
                          label: 'Selling price',
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.gapMd,
                  MarginPreview(
                    cost: double.tryParse(_cost.text) ?? 0,
                    price: double.tryParse(_price.text) ?? 0,
                  ),
                  AppSpacing.gapLg,
                  Row(
                    children: [
                      Expanded(
                        child: _NumberInput(
                          controller: _stock,
                          label: 'Stock on hand',
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _NumberInput(
                          controller: _reorder,
                          label: 'Warn me below',
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
                        : const Text('Save product'),
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
        if (parsed == null || parsed < 0) return 'Enter an amount';
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
