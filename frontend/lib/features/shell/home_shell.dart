import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/responsive.dart';
import '../../data/local/backup/automatic_backup.dart';
import '../../data/repositories/realtime_connection.dart';
import '../../data/repositories/sync_coordinator.dart';
import '../../l10n/l10n.dart';
import '../authentication/account_watcher.dart';
import '../authentication/auth_controller.dart';
import 'navigation_destinations.dart';

/// Holds the persistent navigation around every signed-in screen. A bottom bar
/// on a phone, a rail once there is room for one, so the same code serves a
/// counter tablet and a laptop without a second layout.
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The shell exists exactly while someone is signed in, which makes it
    // the right owner for the background sync and the live connection.
    // Listened to, not watched: it must stay alive, but its progress is no
    // reason to rebuild the navigation.
    ref.listen(syncCoordinatorProvider, (_, _) {});
    ref.watch(realtimeConnectionProvider);
    ref.watch(accountWatcherProvider);
    ref.listen(automaticBackupProvider, (_, _) {});

    final destinations = destinationsFor(ref.watch(currentAccessProvider));
    final index = _indexFor(
      destinations,
      GoRouterState.of(context).matchedLocation,
    );

    if (context.isCompact) {
      return Scaffold(
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (target) =>
              _navigate(context, destinations[target]),
          destinations: [
            for (final destination in destinations)
              NavigationDestination(
                icon: Icon(destination.icon),
                selectedIcon: Icon(destination.selectedIcon),
                label: destination.label(context.l10n),
              ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: index,
            onDestinationSelected: (target) =>
                _navigate(context, destinations[target]),
            labelType: NavigationRailLabelType.all,
            extended: context.isExpanded,
            minExtendedWidth: 180,
            destinations: [
              for (final destination in destinations)
                NavigationRailDestination(
                  icon: Icon(destination.icon),
                  selectedIcon: Icon(destination.selectedIcon),
                  label: Text(destination.label(context.l10n)),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }

  void _navigate(BuildContext context, ShellDestination destination) {
    if (GoRouterState.of(context).matchedLocation != destination.path) {
      context.go(destination.path);
    }
  }

  int _indexFor(List<ShellDestination> destinations, String location) {
    final index = destinations.indexWhere(
      (destination) => destination.path == location,
    );
    return index < 0 ? 0 : index;
  }
}
