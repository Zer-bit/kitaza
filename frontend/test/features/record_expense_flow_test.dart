import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitaza_app/app/route_paths.dart';
import 'package:kitaza_app/features/expenses/record_expense_screen.dart';

import '../support/app_harness.dart';

void main() {
  Future<TestPhone> openExpenseScreen(WidgetTester tester) async {
    final phone = await TestPhone.open(
      tester,
      screens: {RoutePaths.recordExpense: (_) => const RecordExpenseScreen()},
    );
    await phone.goTo(tester, RoutePaths.recordExpense);
    return phone;
  }

  testWidgets('an expense is saved with its category and note', (tester) async {
    final phone = await openExpenseScreen(tester);

    await tester.enterText(find.byType(TextFormField).first, '1850.75');
    await tester.tap(find.text('Utilities'));
    await tester.pump();
    await tester.enterText(
      find.byType(TextFormField).last,
      'Meralco, September',
    );
    await tester.ensureVisible(find.text('Save expense'));
    await tester.tap(find.text('Save expense'));
    await phone.settle(tester);

    expect(phone.isHome, isTrue);
    final expense = (await phone.db.query('expenses')).single;
    expect(expense['amount'], 185075);
    expect(expense['category'], 'utilities');
    expect(expense['description'], 'Meralco, September');
  });

  testWidgets('stock purchases are the default category', (tester) async {
    final phone = await openExpenseScreen(tester);

    await tester.enterText(find.byType(TextFormField).first, '500');
    await tester.ensureVisible(find.text('Save expense'));
    await tester.tap(find.text('Save expense'));
    await phone.settle(tester);

    expect((await phone.db.query('expenses')).single['category'], 'inventory');
  });

  testWidgets('an expense without an amount is not saved', (tester) async {
    final phone = await openExpenseScreen(tester);

    await tester.ensureVisible(find.text('Save expense'));
    await tester.tap(find.text('Save expense'));
    await tester.pump();

    expect(find.text('Enter an amount'), findsOneWidget);
    expect(phone.isHome, isFalse);
    expect(await phone.db.query('expenses'), isEmpty);
  });

  testWidgets('the amount field refuses more than two decimal places', (
    tester,
  ) async {
    await openExpenseScreen(tester);

    await tester.enterText(find.byType(TextFormField).first, '12.345');
    await tester.pump();

    expect(find.text('12.34'), findsOneWidget);
  });
}
