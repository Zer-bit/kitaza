import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../data/models/expense_category.dart';
import '../../data/repositories/data_revision.dart';
import '../../data/repositories/expense_repository.dart';
import '../../l10n/l10n.dart';
import '../../shared/widgets/amount_field.dart';
import '../../shared/widgets/feedback_messenger.dart';
import '../../shared/widgets/page_body.dart';
import '../../shared/widgets/section_header.dart';
import 'widgets/category_picker.dart';

class RecordExpenseScreen extends ConsumerStatefulWidget {
  const RecordExpenseScreen({super.key});

  @override
  ConsumerState<RecordExpenseScreen> createState() =>
      _RecordExpenseScreenState();
}

class _RecordExpenseScreenState extends ConsumerState<RecordExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _description = TextEditingController();
  ExpenseCategory _category = ExpenseCategory.inventory;
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      await ref
          .read(expenseRepositoryProvider)
          .record(
            category: _category,
            amount: double.parse(_amount.text),
            description: _description.text,
          );

      ref.read(dataRevisionProvider.notifier).localWrite();

      if (!mounted) return;
      FeedbackMessenger.success(context, context.l10n.expenseRecorded);
      context.pop();
    } on Object {
      if (!mounted) return;
      setState(() => _saving = false);
      FeedbackMessenger.error(context, context.l10n.expenseSaveFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.expenseTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          child: PageBody(
            maxWidth: 560,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AmountField(controller: _amount, autofocus: true),
                  AppSpacing.gapXl,
                  SectionHeader(title: context.l10n.expenseWhatFor),
                  CategoryPicker(
                    selected: _category,
                    onChanged: (category) =>
                        setState(() => _category = category),
                  ),
                  AppSpacing.gapXl,
                  TextFormField(
                    controller: _description,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: context.l10n.commonNoteOptional,
                      hintText: context.l10n.expenseNoteHint,
                    ),
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
                        : Text(context.l10n.expenseSave),
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
