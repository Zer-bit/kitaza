import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/route_paths.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/l10n.dart';
import '../../shared/widgets/feedback_messenger.dart';
import 'auth_controller.dart';
import 'widgets/auth_scaffold.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // Signing back in after this phone was signed out: it is almost always
    // the same owner, so save them typing their email again.
    final ended = ref.read(currentSessionProvider);
    if (ended != null && ended.ended) _email.text = ended.owner.email ?? '';
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    await ref
        .read(authControllerProvider.notifier)
        .signIn(email: _email.text, password: _password.text);

    if (!mounted) return;
    setState(() => _submitting = false);

    final error = ref.read(authControllerProvider).error;
    if (error != null) {
      FeedbackMessenger.error(
        context,
        context.l10n.failure(error, fallback: context.l10n.signInFailed),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AuthScaffold(
      title: l10n.signInTitle,
      subtitle: l10n.signInSubtitle,
      onBack: () => context.pop(),
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: InputDecoration(labelText: l10n.commonEmail),
                validator: (value) => (value == null || !value.contains('@'))
                    ? l10n.commonEnterEmail
                    : null,
              ),
              AppSpacing.gapLg,
              TextFormField(
                controller: _password,
                obscureText: _obscure,
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: l10n.commonPassword,
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
                validator: (value) => (value == null || value.isEmpty)
                    ? l10n.commonEnterPassword
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
              : Text(l10n.signInSubmit),
        ),
        AppSpacing.gapMd,
        TextButton(
          onPressed: () => context.push(RoutePaths.signUp),
          child: Text(l10n.signInCreateAccount),
        ),
      ],
    );
  }
}
