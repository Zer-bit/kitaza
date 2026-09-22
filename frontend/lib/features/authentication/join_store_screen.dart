import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_failure.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/l10n.dart';
import '../../shared/widgets/feedback_messenger.dart';
import 'auth_controller.dart';
import 'widgets/auth_scaffold.dart';

/// A staff member's way in: the code the owner made for them, and nothing
/// else. No email, no password to forget.
class JoinStoreScreen extends ConsumerStatefulWidget {
  const JoinStoreScreen({super.key});

  @override
  ConsumerState<JoinStoreScreen> createState() => _JoinStoreScreenState();
}

class _JoinStoreScreenState extends ConsumerState<JoinStoreScreen> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    await ref.read(authControllerProvider.notifier).joinStore(_code.text);

    if (!mounted) return;
    setState(() => _submitting = false);

    final error = ref.read(authControllerProvider).error;
    if (error == null) return;

    final l10n = context.l10n;
    // A refused code is by far the likeliest failure, and "wrong password"
    // would make no sense to someone who never had one.
    final refusedCode =
        error is AppFailure &&
        error.kind == FailureKind.rejected &&
        error.code == 'unauthorized';
    FeedbackMessenger.error(
      context,
      refusedCode ? l10n.joinCodeRefused : l10n.failure(error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AuthScaffold(
      title: l10n.joinTitle,
      subtitle: l10n.joinSubtitle,
      onBack: () => context.pop(),
      children: [
        Form(
          key: _formKey,
          child: TextFormField(
            controller: _code,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: TextInputType.visiblePassword,
            textInputAction: TextInputAction.done,
            inputFormatters: [JoinCodeFormatter()],
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(letterSpacing: 2),
            decoration: InputDecoration(
              labelText: l10n.joinCodeLabel,
              hintText: 'ABCDE-FGHJK',
            ),
            onFieldSubmitted: (_) => _submit(),
            validator: (value) => JoinCodeFormatter.isComplete(value ?? '')
                ? null
                : l10n.joinCodeInvalid,
          ),
        ),
        AppSpacing.gapMd,
        Text(
          l10n.joinSharedPhoneNote,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        AppSpacing.gapXl,
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.joinAction),
        ),
      ],
    );
  }
}

/// Shows a code the way the owner's screen does, `ABCDE-FGHJK`, however it
/// is typed or pasted.
class JoinCodeFormatter extends TextInputFormatter {
  static const int length = 10;

  static String normalise(String typed) =>
      typed.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');

  static bool isComplete(String typed) => normalise(typed).length == length;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = normalise(newValue.text);
    final kept = raw.length > length ? raw.substring(0, length) : raw;
    final shown = kept.length > length ~/ 2
        ? '${kept.substring(0, length ~/ 2)}-${kept.substring(length ~/ 2)}'
        : kept;
    return TextEditingValue(
      text: shown,
      selection: TextSelection.collapsed(offset: shown.length),
    );
  }
}
