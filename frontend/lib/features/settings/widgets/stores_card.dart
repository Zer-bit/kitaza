import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../data/models/store_profile.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/feedback_messenger.dart';
import '../../authentication/auth_controller.dart';

/// The owner's stores: which one is open, switching between them, and adding
/// or renaming one.
class StoresCard extends ConsumerWidget {
  const StoresCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final session = ref.watch(currentSessionProvider);
    if (session == null) return const SizedBox.shrink();

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: AppSpacing.cardPadding,
            child: Text(
              l10n.storesHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          for (final store in session.stores)
            _StoreTile(store: store, isOpen: store.id == session.store.id),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.add_business_outlined),
            title: Text(l10n.storesAdd),
            onTap: () => _add(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final name = await askStoreName(
      context,
      title: l10n.storesAddTitle,
      submitLabel: l10n.storesAddSubmit,
    );
    if (name == null || !context.mounted) return;

    try {
      await ref
          .read(authControllerProvider.notifier)
          .addStore(name: name, businessType: 'sari_sari');
      if (context.mounted) {
        FeedbackMessenger.success(context, l10n.storesSwitched(name));
      }
    } on Object catch (error) {
      if (context.mounted) {
        FeedbackMessenger.error(context, l10n.failure(error));
      }
    }
  }
}

class _StoreTile extends ConsumerWidget {
  const _StoreTile({required this.store, required this.isOpen});

  final StoreProfile store;
  final bool isOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(
        isOpen ? Icons.storefront_rounded : Icons.storefront_outlined,
        color: isOpen ? theme.colorScheme.primary : null,
      ),
      title: Text(store.name),
      subtitle: isOpen ? Text(l10n.storesOpenNow) : null,
      selected: isOpen,
      onTap: isOpen ? null : () => _open(context, ref),
      trailing: IconButton(
        icon: const Icon(Icons.edit_outlined),
        tooltip: l10n.storesRename,
        onPressed: () => _rename(context, ref),
      ),
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    await ref.read(authControllerProvider.notifier).switchStore(store);
    if (context.mounted) {
      FeedbackMessenger.success(
        context,
        context.l10n.storesSwitched(store.name),
      );
    }
  }

  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final name = await askStoreName(
      context,
      title: l10n.storesRename,
      submitLabel: l10n.commonSave,
      initial: store.name,
    );
    if (name == null || name == store.name || !context.mounted) return;

    try {
      await ref.read(authControllerProvider.notifier).renameStore(store, name);
    } on Object catch (error) {
      if (context.mounted) {
        FeedbackMessenger.error(context, l10n.failure(error));
      }
    }
  }
}

/// Asks for a store name. Null if the owner backed out.
Future<String?> askStoreName(
  BuildContext context, {
  required String title,
  required String submitLabel,
  String? initial,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _StoreNameDialog(
      title: title,
      submitLabel: submitLabel,
      initial: initial,
    ),
  );
}

class _StoreNameDialog extends StatefulWidget {
  const _StoreNameDialog({
    required this.title,
    required this.submitLabel,
    this.initial,
  });

  final String title;
  final String submitLabel;
  final String? initial;

  @override
  State<_StoreNameDialog> createState() => _StoreNameDialogState();
}

class _StoreNameDialogState extends State<_StoreNameDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, _name.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _name,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(labelText: l10n.commonStoreName),
          onFieldSubmitted: (_) => _submit(),
          validator: (value) => (value ?? '').trim().length < 2
              ? l10n.commonEnterStoreName
              : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(onPressed: _submit, child: Text(widget.submitLabel)),
      ],
    );
  }
}
