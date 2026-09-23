import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/route_paths.dart';
import '../../../l10n/l10n.dart';

/// The way in to everything about the owner's own data: what is held, a copy
/// of it, and closing the account.
class PrivacyCard extends StatelessWidget {
  const PrivacyCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Card(
      child: ListTile(
        leading: const Icon(Icons.privacy_tip_outlined),
        title: Text(l10n.privacyCardTitle),
        subtitle: Text(l10n.privacyCardSubtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(RoutePaths.privacy),
      ),
    );
  }
}
