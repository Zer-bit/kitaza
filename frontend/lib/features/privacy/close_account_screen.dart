import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatting/day_formatter.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/remote/privacy_api.dart';
import '../../l10n/l10n.dart';
import '../../shared/widgets/feedback_messenger.dart';
import '../../shared/widgets/page_body.dart';
import '../authentication/auth_controller.dart';
import 'privacy_controller.dart';

/// Asking for everything held about this account to be deleted.
///
/// The right to erasure is a right, so this screen does not argue. It does
/// say plainly what goes, what stays, and that there are thirty days in which
/// a mis-tap can be undone.
class CloseAccountScreen extends ConsumerStatefulWidget {
  const CloseAccountScreen({super.key});

  @override
  ConsumerState<CloseAccountScreen> createState() => _CloseAccountScreenState();
}

class _CloseAccountScreenState extends ConsumerState<CloseAccountScreen> {
  final _confirmation = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _working = false;

  @override
  void dispose() {
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _working = true);
    try {
      await ref.read(privacyApiProvider).requestDeletion();
      ref.invalidate(privacyStateProvider);
    } on Object {
      if (mounted) {
        FeedbackMessenger.error(context, context.l10n.privacyCloseFailed);
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _keep() async {
    setState(() => _working = true);
    try {
      await ref.read(privacyApiProvider).cancelDeletion();
      ref.invalidate(privacyStateProvider);
      if (mounted) {
        FeedbackMessenger.success(context, context.l10n.privacyCloseCancelled);
      }
    } on Object {
      if (mounted) {
        FeedbackMessenger.error(context, context.l10n.privacyCloseFailed);
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final storeName = ref.watch(currentSessionProvider)?.store.name ?? '';
    final deletion = ref.watch(privacyStateProvider).value?.deletion;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.privacyCloseScreenTitle)),
      body: ListView(
        children: [
          PageBody(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (deletion != null) ...[
                  Card(
                    color: theme.colorScheme.errorContainer,
                    child: Padding(
                      padding: AppSpacing.cardPadding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.privacyCloseScheduled(
                              DayFormatter.fullDate(deletion.deletesAt),
                            ),
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                          AppSpacing.gapMd,
                          FilledButton(
                            onPressed: _working ? null : _keep,
                            child: Text(l10n.privacyCloseCancel),
                          ),
                        ],
                      ),
                    ),
                  ),
                  AppSpacing.gapXl,
                ],
                Text(
                  l10n.privacyCloseExplain,
                  style: theme.textTheme.bodyLarge,
                ),
                AppSpacing.gapMd,
                _Point(text: l10n.privacyCloseGrace(deletionGraceDays)),
                _Point(text: l10n.privacyCloseKeeps),
                _Point(text: l10n.privacyClosePhone),
                AppSpacing.gapXl,
                if (deletion == null)
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _confirmation,
                          decoration: InputDecoration(
                            labelText: l10n.privacyCloseConfirmLabel,
                            helperText: storeName,
                          ),
                          validator: (value) =>
                              value?.trim() == storeName.trim()
                              ? null
                              : l10n.privacyCloseConfirmWrong,
                        ),
                        AppSpacing.gapLg,
                        FilledButton(
                          onPressed: _working ? null : _close,
                          style: FilledButton.styleFrom(
                            backgroundColor: theme.colorScheme.error,
                            foregroundColor: theme.colorScheme.onError,
                          ),
                          child: _working
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(l10n.privacyCloseSubmit),
                        ),
                      ],
                    ),
                  ),
                AppSpacing.gapXl,
                TextButton(
                  onPressed: () => context.pop(),
                  child: Text(l10n.commonCancel),
                ),
                AppSpacing.gapXl,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// How long a deletion can still be called off. Matches the server's
/// KITAZA_DELETION_GRACE_DAYS; the server is what actually decides.
const int deletionGraceDays = 30;

class _Point extends StatelessWidget {
  const _Point({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6, right: AppSpacing.sm),
            child: Icon(Icons.circle, size: 6),
          ),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
