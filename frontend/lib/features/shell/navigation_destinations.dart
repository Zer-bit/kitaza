import 'package:flutter/material.dart';

import '../../app/route_paths.dart';

class ShellDestination {
  const ShellDestination({
    required this.path,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// Five destinations at most. Every extra tab is one more decision for
/// someone who just wants to record a sale.
const List<ShellDestination> shellDestinations = [
  ShellDestination(
    path: RoutePaths.dashboard,
    label: 'Home',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home_rounded,
  ),
  ShellDestination(
    path: RoutePaths.saleHistory,
    label: 'Sales',
    icon: Icons.point_of_sale_outlined,
    selectedIcon: Icons.point_of_sale_rounded,
  ),
  ShellDestination(
    path: RoutePaths.expenseHistory,
    label: 'Expenses',
    icon: Icons.receipt_long_outlined,
    selectedIcon: Icons.receipt_long_rounded,
  ),
  ShellDestination(
    path: RoutePaths.products,
    label: 'Products',
    icon: Icons.inventory_2_outlined,
    selectedIcon: Icons.inventory_2_rounded,
  ),
  ShellDestination(
    path: RoutePaths.reports,
    label: 'Reports',
    icon: Icons.insights_outlined,
    selectedIcon: Icons.insights_rounded,
  ),
];
