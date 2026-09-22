import 'package:flutter/material.dart';

enum ExpenseCategory {
  inventory('inventory', 'Stock / Puhunan', Icons.inventory_2_outlined),
  utilities('utilities', 'Utilities', Icons.bolt_outlined),
  salary('salary', 'Salary', Icons.badge_outlined),
  transportation('transportation', 'Transport', Icons.local_shipping_outlined),
  rent('rent', 'Rent', Icons.storefront_outlined),
  supplies('supplies', 'Supplies', Icons.shopping_basket_outlined),
  repairs('repairs', 'Repairs', Icons.build_outlined),
  taxesPermits('taxes_permits', 'Taxes & permits', Icons.receipt_long_outlined),
  other('other', 'Other', Icons.more_horiz_rounded);

  const ExpenseCategory(this.wireName, this.label, this.icon);

  final String wireName;
  final String label;
  final IconData icon;

  static ExpenseCategory parse(String? raw) => values.firstWhere(
    (category) => category.wireName == raw,
    orElse: () => ExpenseCategory.other,
  );
}
