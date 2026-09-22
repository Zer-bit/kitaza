import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../data/repositories/sync_coordinator.dart';
import '../../l10n/l10n.dart';
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
      FeedbackMessenger.success(context, context.l10n.upgradeDone);
      context.pop();
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _working = false);
      FeedbackMessenger.error(
        context,
        context.l10n.failure(error, fallback: context.l10n.upgradeFailed),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.upgradeTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          child: PageBody(
            maxWidth: 480,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.upgradeIntro, style: theme.textTheme.bodyMedium),
                  AppSpacing.gapXl,
                  SegmentedButton<bool>(
                    segments: [
                      ButtonSegment(
                        value: true,
                        label: Text(l10n.upgradeNewAccount),
                      ),
                      ButtonSegment(
                        value: false,
                        label: Text(l10n.upgradeExistingAccount),
                      ),
                    ],
                    selected: {_createAccount},
                    showSelectedIcon: false,
                    onSelectionChanged: (selection) =>
                        setState(() => _createAccount = selection.first),
                  ),
                  AppSpacing.gapLg,
                  if (!_createAccount) ...[
                    Text(
                      l10n.upgradeExistingNote,
                      style: theme.textTheme.bodySmall,
                    ),
                    AppSpacing.gapLg,
                  ],
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: InputDecoration(labelText: l10n.commonEmail),
                    validator: (value) =>
                        (value == null || !value.contains('@'))
                        ? l10n.commonEnterEmail
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
                      labelText: l10n.commonPassword,
                      helperText: _createAccount
                          ? l10n.commonPasswordHint
                          : null,
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                        ),
                        tooltip: _obscure
                            ? l10n.commonShowPassword
                            : l10n.commonHidePassword,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.commonEnterPassword;
                      }
                      if (_createAccount && value.length < 8) {
                        return l10n.commonPasswordTooShort;
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
                                ? l10n.upgradeCreateSubmit
                                : l10n.upgradeSignInSubmit,
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
