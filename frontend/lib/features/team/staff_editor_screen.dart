import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../data/models/access_grant.dart';
import '../../data/models/staff_member.dart';
import '../../data/remote/team_api.dart';
import '../../data/repositories/store_scope.dart';
import '../../l10n/l10n.dart';
import '../../shared/widgets/feedback_messenger.dart';
import '../../shared/widgets/page_body.dart';

/// What happened in the editor, for the staff list to follow up on.
sealed class StaffEditorOutcome {
  const StaffEditorOutcome(this.name);
  final String name;
}

/// Someone new, or a new code for someone existing: show the code.
class InviteMade extends StaffEditorOutcome {
  const InviteMade(super.name, this.invite);
  final JoinInvite invite;
}

class StaffSaved extends StaffEditorOutcome {
  const StaffSaved(super.name);
}

class StaffRemoved extends StaffEditorOutcome {
  const StaffRemoved(super.name);
}

/// Adds a staff member, or changes what one may do.
class StaffEditorScreen extends ConsumerStatefulWidget {
  const StaffEditorScreen({super.key, this.existing});

  final StaffMember? existing;

  static Future<StaffEditorOutcome?> open(
    BuildContext context, {
    StaffMember? existing,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => StaffEditorScreen(existing: existing),
      ),
    );
  }

  @override
  ConsumerState<StaffEditorScreen> createState() => _StaffEditorScreenState();
}

class _StaffEditorScreenState extends ConsumerState<StaffEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.displayName);
  late final Set<Permission> _permissions = {...?widget.existing?.permissions};
  bool _busy = false;

  bool get _isNew => widget.existing == null;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _run(Future<StaffEditorOutcome> Function() action) async {
    setState(() => _busy = true);
    try {
      final outcome = await action();
      if (mounted) Navigator.pop(context, outcome);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      FeedbackMessenger.error(context, context.l10n.failure(error));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final api = ref.read(teamApiProvider);
    final storeId = ref.read(activeStoreIdProvider);
    final name = _name.text.trim();

    await _run(() async {
      if (_isNew) {
        final added = await api.addStaff(
          storeId,
          name: name,
          permissions: _permissions,
        );
        return InviteMade(name, added.invite);
      }
      await api.updateStaff(
        storeId,
        widget.existing!.id,
        name: name,
        permissions: _permissions,
      );
      return StaffSaved(name);
    });
  }

  Future<void> _newCode() async {
    final staff = widget.existing!;
    await _run(() async {
      final invite = await ref
          .read(teamApiProvider)
          .newJoinCode(ref.read(activeStoreIdProvider), staff.id);
      return InviteMade(staff.displayName, invite);
    });
  }

  Future<void> _remove() async {
    final l10n = context.l10n;
    final staff = widget.existing!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.staffRemoveTitle(staff.displayName)),
        content: Text(l10n.staffRemoveMessage(staff.displayName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.staffRemove),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _run(() async {
      await ref
          .read(teamApiProvider)
          .removeStaff(ref.read(activeStoreIdProvider), staff.id);
      return StaffRemoved(staff.displayName);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? l10n.staffAdd : widget.existing!.displayName),
      ),
      body: ListView(
        children: [
          PageBody(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _name,
                    autofocus: _isNew,
                    textCapitalization: TextCapitalization.words,
                    maxLength: 40,
                    decoration: InputDecoration(labelText: l10n.staffNameLabel),
                    validator: (value) => (value ?? '').trim().isEmpty
                        ? l10n.commonEnterName
                        : null,
                  ),
                  AppSpacing.gapMd,
                  Text(
                    l10n.staffAlwaysSells,
                    style: theme.textTheme.bodyMedium,
                  ),
                  AppSpacing.gapSm,
                  Card(
                    child: Column(
                      children: [
                        for (final permission in Permission.values)
                          SwitchListTile(
                            value: _permissions.contains(permission),
                            onChanged: _busy
                                ? null
                                : (on) => setState(
                                    () => on
                                        ? _permissions.add(permission)
                                        : _permissions.remove(permission),
                                  ),
                            title: Text(l10n.permissionTitle(permission)),
                            subtitle: Text(l10n.permissionHint(permission)),
                          ),
                      ],
                    ),
                  ),
                  AppSpacing.gapXl,
                  FilledButton(
                    onPressed: _busy ? null : _save,
                    child: _busy
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isNew ? l10n.staffAdd : l10n.commonSave),
                  ),
                  if (!_isNew) ...[
                    AppSpacing.gapXl,
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.key_rounded),
                            title: Text(l10n.staffNewCode),
                            subtitle: Text(l10n.staffNewCodeHint),
                            onTap: _busy ? null : _newCode,
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: Icon(
                              Icons.person_remove_outlined,
                              color: theme.colorScheme.error,
                            ),
                            title: Text(
                              l10n.staffRemove,
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                            onTap: _busy ? null : _remove,
                          ),
                        ],
                      ),
                    ),
                  ],
                  AppSpacing.gapXl,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
