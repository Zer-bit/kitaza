import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/responsive.dart';
import 'navigation_destinations.dart';

/// Holds the persistent navigation around every signed-in screen. A bottom bar
/// on a phone, a rail once there is room for one, so the same code serves a
/// counter tablet and a laptop without a second layout.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final index = _indexFor(GoRouterState.of(context).matchedLocation);

    if (context.isCompact) {
      return Scaffold(
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (target) => _navigate(context, target),
          destinations: [
            for (final destination in shellDestinations)
              NavigationDestination(
                icon: Icon(destination.icon),
                selectedIcon: Icon(destination.selectedIcon),
                label: destination.label,
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
            onDestinationSelected: (target) => _navigate(context, target),
            labelType: NavigationRailLabelType.all,
            extended: context.isExpanded,
            minExtendedWidth: 180,
            destinations: [
              for (final destination in shellDestinations)
                NavigationRailDestination(
                  icon: Icon(destination.icon),
                  selectedIcon: Icon(destination.selectedIcon),
                  label: Text(destination.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }

  void _navigate(BuildContext context, int target) {
    final path = shellDestinations[target].path;
    if (GoRouterState.of(context).matchedLocation != path) {
      context.go(path);
    }
  }

  int _indexFor(String location) {
    final index = shellDestinations.indexWhere(
      (destination) => destination.path == location,
    );
    return index < 0 ? 0 : index;
  }
}
