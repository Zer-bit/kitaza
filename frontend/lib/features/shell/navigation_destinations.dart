import 'package:flutter/material.dart';

import '../../app/route_paths.dart';
import '../../data/models/access_grant.dart';
import '../../l10n/l10n.dart';

class ShellDestination {
  const ShellDestination({
    required this.path,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String path;

  /// Resolved per build so the tab names follow the chosen language.
  final String Function(AppLocalizations l10n) label;
  final IconData icon;
  final IconData selectedIcon;
}

String _home(AppLocalizations l10n) => l10n.navHome;
String _sales(AppLocalizations l10n) => l10n.navSales;
String _expenses(AppLocalizations l10n) => l10n.navExpenses;
String _products(AppLocalizations l10n) => l10n.navProducts;
String _reports(AppLocalizations l10n) => l10n.navReports;

/// Five destinations at most. Every extra tab is one more decision for
/// someone who just wants to record a sale.
const List<ShellDestination> shellDestinations = [
  ShellDestination(
    path: RoutePaths.dashboard,
    label: _home,
    icon: Icons.home_outlined,
    selectedIcon: Icons.home_rounded,
  ),
  ShellDestination(
    path: RoutePaths.saleHistory,
    label: _sales,
    icon: Icons.point_of_sale_outlined,
    selectedIcon: Icons.point_of_sale_rounded,
  ),
  ShellDestination(
    path: RoutePaths.expenseHistory,
    label: _expenses,
    icon: Icons.receipt_long_outlined,
    selectedIcon: Icons.receipt_long_rounded,
  ),
  ShellDestination(
    path: RoutePaths.products,
    label: _products,
    icon: Icons.inventory_2_outlined,
    selectedIcon: Icons.inventory_2_rounded,
  ),
  ShellDestination(
    path: RoutePaths.reports,
    label: _reports,
    icon: Icons.insights_outlined,
    selectedIcon: Icons.insights_rounded,
  ),
];

/// The tabs this person gets. A cashier sees sales and products; the money
/// tabs appear with the permissions that go with them.
List<ShellDestination> destinationsFor(AccessGrant access) => [
  for (final destination in shellDestinations)
    if (switch (destination.path) {
      RoutePaths.expenseHistory =>
        access.can(Permission.recordExpenses) ||
            access.can(Permission.viewProfit),
      RoutePaths.reports => access.can(Permission.viewProfit),
      _ => true,
    })
      destination,
];
