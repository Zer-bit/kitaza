import 'package:flutter/material.dart';

enum ExpenseCategory {
  inventory('inventory', Icons.inventory_2_outlined),
  utilities('utilities', Icons.bolt_outlined),
  salary('salary', Icons.badge_outlined),
  transportation('transportation', Icons.local_shipping_outlined),
  rent('rent', Icons.storefront_outlined),
  supplies('supplies', Icons.shopping_basket_outlined),
  repairs('repairs', Icons.build_outlined),
  taxesPermits('taxes_permits', Icons.receipt_long_outlined),
  other('other', Icons.more_horiz_rounded);

  const ExpenseCategory(this.wireName, this.icon);

  final String wireName;
  final IconData icon;

  static ExpenseCategory parse(String? raw) => values.firstWhere(
    (category) => category.wireName == raw,
    orElse: () => ExpenseCategory.other,
  );
}
