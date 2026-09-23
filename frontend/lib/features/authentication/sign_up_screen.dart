import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../l10n/l10n.dart';
import '../../shared/widgets/feedback_messenger.dart';
import '../legal/widgets/consent_checkbox.dart';
import 'auth_controller.dart';
import 'widgets/auth_scaffold.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storeName = TextEditingController();
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _submitting = false;
  bool _agreed = false;
  bool _showConsentError = false;

  @override
  void dispose() {
    _storeName.dispose();
    _fullName.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final formOk = _formKey.currentState!.validate();
    // Checked even when the rest of the form is wrong, so someone who fixes
    // their password is not surprised by a second objection.
    setState(() => _showConsentError = !_agreed);
    if (!formOk || !_agreed) return;

    setState(() => _submitting = true);
    await ref
        .read(authControllerProvider.notifier)
        .register(
          email: _email.text,
          password: _password.text,
          fullName: _fullName.text,
          storeName: _storeName.text,
        );

    if (!mounted) return;
    setState(() => _submitting = false);

    final error = ref.read(authControllerProvider).error;
    if (error != null) {
      FeedbackMessenger.error(
        context,
        context.l10n.failure(error, fallback: context.l10n.signUpFailed),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AuthScaffold(
      title: l10n.signUpTitle,
      subtitle: l10n.signUpSubtitle,
      onBack: () => context.pop(),
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _storeName,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(labelText: l10n.commonStoreName),
                validator: (value) => (value == null || value.trim().length < 2)
                    ? l10n.commonEnterStoreName
                    : null,
              ),
              AppSpacing.gapLg,
              TextFormField(
                controller: _fullName,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(labelText: l10n.commonYourName),
                validator: (value) => (value == null || value.trim().length < 2)
                    ? l10n.commonEnterYourName
                    : null,
              ),
              AppSpacing.gapLg,
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
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: l10n.commonPassword,
                  helperText: l10n.commonPasswordHint,
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
                validator: (value) => (value == null || value.length < 8)
                    ? l10n.commonPasswordTooShort
                    : null,
              ),
            ],
          ),
        ),
        AppSpacing.gapLg,
        ConsentCheckbox(
          agreed: _agreed,
          showError: _showConsentError,
          onChanged: (value) => setState(() {
            _agreed = value;
            _showConsentError = false;
          }),
        ),
        AppSpacing.gapLg,
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.signUpSubmit),
        ),
      ],
    );
  }
}
