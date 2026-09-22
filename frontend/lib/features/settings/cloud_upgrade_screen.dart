import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_failure.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/repositories/sync_coordinator.dart';
import '../../shared/widgets/feedback_messenger.dart';
import '../../shared/widgets/page_body.dart';
import '../authentication/auth_controller.dart';

/// Moves a store that has only lived on this phone into the cloud, keeping
/// every sale, expense and stock count recorded so far.
class CloudUpgradeScreen extends ConsumerStatefulWidget {
  const CloudUpgradeScreen({super.key});

  @override
  ConsumerState<CloudUpgradeScreen> createState() => _CloudUpgradeScreenState();
}

class _CloudUpgradeScreenState extends ConsumerState<CloudUpgradeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _createAccount = true;
  bool _obscure = true;
  bool _working = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _working = true);

    try {
      await ref
          .read(authControllerProvider.notifier)
          .upgradeToCloud(
            email: _email.text,
            password: _password.text,
            createAccount: _createAccount,
          );
      // Upload the history straight away rather than on the next timer tick.
      await ref.read(syncCoordinatorProvider.notifier).syncNow(force: true);

      if (!mounted) return;
      FeedbackMessenger.success(context, 'Your store is now backed up.');
      context.pop();
    } on AppFailure catch (failure) {
      if (!mounted) return;
      setState(() => _working = false);
      FeedbackMessenger.error(context, failure.message);
    } on Object {
      if (!mounted) return;
      setState(() => _working = false);
      FeedbackMessenger.error(
        context,
        'Could not back up right now. Nothing was changed.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Back up to the cloud')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: PageBody(
            maxWidth: 480,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Everything you have recorded on this phone stays, and is '
                    'copied to your account. The app keeps working offline '
                    'exactly as before.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  AppSpacing.gapXl,
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: true, label: Text('New account')),
                      ButtonSegment(value: false, label: Text('I have one')),
                    ],
                    selected: {_createAccount},
                    showSelectedIcon: false,
                    onSelectionChanged: (selection) =>
                        setState(() => _createAccount = selection.first),
                  ),
                  AppSpacing.gapLg,
                  if (!_createAccount) ...[
                    Text(
                      'This phone\'s records will be added to the store on '
                      'that account.',
                      style: theme.textTheme.bodySmall,
                    ),
                    AppSpacing.gapLg,
                  ],
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (value) =>
                        (value == null || !value.contains('@'))
                        ? 'Enter your email'
                        : null,
                  ),
                  AppSpacing.gapLg,
                  TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    autofillHints: [
                      _createAccount
                          ? AutofillHints.newPassword
                          : AutofillHints.password,
                    ],
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      helperText: _createAccount
                          ? 'At least 8 characters'
                          : null,
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                        ),
                        tooltip: _obscure ? 'Show password' : 'Hide password',
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter a password';
                      }
                      if (_createAccount && value.length < 8) {
                        return 'Use at least 8 characters';
                      }
                      return null;
                    },
                  ),
                  AppSpacing.gapXl,
                  FilledButton(
                    onPressed: _working ? null : _submit,
                    child: _working
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _createAccount
                                ? 'Create account and back up'
                                : 'Sign in and back up',
                          ),
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
