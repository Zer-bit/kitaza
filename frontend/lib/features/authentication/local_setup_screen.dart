import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/feedback_messenger.dart';
import 'auth_controller.dart';
import 'widgets/auth_scaffold.dart';

/// Offline setup asks for two things and nothing else. No password: there is
/// no remote account to protect, and a forgotten one would lock an owner out
/// of their own books.
class LocalSetupScreen extends ConsumerStatefulWidget {
  const LocalSetupScreen({super.key});

  @override
  ConsumerState<LocalSetupScreen> createState() => _LocalSetupScreenState();
}

class _LocalSetupScreenState extends ConsumerState<LocalSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ownerName = TextEditingController();
  final _storeName = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _ownerName.dispose();
    _storeName.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    await ref
        .read(authControllerProvider.notifier)
        .continueOffline(
          ownerName: _ownerName.text,
          storeName: _storeName.text,
        );

    if (!mounted) return;
    setState(() => _submitting = false);

    final failure = ref.read(authControllerProvider).error;
    if (failure != null) {
      FeedbackMessenger.error(context, 'Could not set up. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Set up your store',
      subtitle: 'This takes about ten seconds.',
      onBack: () => context.pop(),
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _storeName,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Store name',
                  hintText: 'Aling Nena Sari-Sari Store',
                ),
                validator: (value) => (value == null || value.trim().length < 2)
                    ? 'Enter a name'
                    : null,
              ),
              AppSpacing.gapLg,
              TextFormField(
                controller: _ownerName,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  labelText: 'Your name',
                  hintText: 'Nena Reyes',
                ),
                validator: (value) => (value == null || value.trim().length < 2)
                    ? 'Enter your name'
                    : null,
              ),
            ],
          ),
        ),
        AppSpacing.gapXl,
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Start using Kitaza'),
        ),
      ],
    );
  }
}
