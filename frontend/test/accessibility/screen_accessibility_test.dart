import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitaza_app/app/route_paths.dart';
import 'package:kitaza_app/data/models/access_grant.dart';
import 'package:kitaza_app/data/models/activity_event.dart';
import 'package:kitaza_app/data/models/auth_session.dart';
import 'package:kitaza_app/data/models/billing_overview.dart';
import 'package:kitaza_app/data/models/expense_category.dart';
import 'package:kitaza_app/data/models/guide_lesson.dart';
import 'package:kitaza_app/data/models/legal_document.dart';
import 'package:kitaza_app/data/models/payment_method.dart';
import 'package:kitaza_app/data/models/staff_member.dart';
import 'package:kitaza_app/data/models/subscription.dart';
import 'package:kitaza_app/data/remote/benchmarks_api.dart';
import 'package:kitaza_app/data/remote/billing_api.dart';
import 'package:kitaza_app/data/remote/team_api.dart';
import 'package:kitaza_app/data/repositories/expense_repository.dart';
import 'package:kitaza_app/data/repositories/product_repository.dart';
import 'package:kitaza_app/data/repositories/sale_repository.dart';
import 'package:kitaza_app/data/repositories/withdrawal_repository.dart';
import 'package:kitaza_app/features/authentication/auth_controller.dart';
import 'package:kitaza_app/features/authentication/join_store_screen.dart';
import 'package:kitaza_app/features/authentication/session_ended_screen.dart';
import 'package:kitaza_app/features/billing/plan_screen.dart';
import 'package:kitaza_app/features/dashboard/dashboard_screen.dart';
import 'package:kitaza_app/features/expenses/expense_history_screen.dart';
import 'package:kitaza_app/features/expenses/record_expense_screen.dart';
import 'package:kitaza_app/features/guide/guide_lesson_screen.dart';
import 'package:kitaza_app/features/guide/guide_screen.dart';
import 'package:kitaza_app/features/legal/legal_screen.dart';
import 'package:kitaza_app/features/privacy/close_account_screen.dart';
import 'package:kitaza_app/features/privacy/privacy_screen.dart';
import 'package:kitaza_app/features/products/product_editor_screen.dart';
import 'package:kitaza_app/features/products/product_list_screen.dart';
import 'package:kitaza_app/features/reports/reports_screen.dart';
import 'package:kitaza_app/features/sales/record_sale_screen.dart';
import 'package:kitaza_app/features/sales/sale_history_screen.dart';
import 'package:kitaza_app/features/settings/settings_screen.dart';
import 'package:kitaza_app/features/team/activity_screen.dart';
import 'package:kitaza_app/features/team/devices_screen.dart';
import 'package:kitaza_app/features/team/staff_screen.dart';
import 'package:kitaza_app/features/withdrawals/withdrawal_screen.dart';

import '../support/app_harness.dart';
import '../support/in_memory_database.dart';
import '../support/team_fakes.dart';

/// Every main screen, checked the way an older owner with large text on a
/// small phone - or someone using a screen reader - would meet it.
final Map<String, WidgetBuilder> _screens = {
  RoutePaths.dashboard: (_) => const DashboardScreen(),
  RoutePaths.recordSale: (_) => const RecordSaleScreen(),
  RoutePaths.saleHistory: (_) => const SaleHistoryScreen(),
  RoutePaths.recordExpense: (_) => const RecordExpenseScreen(),
  RoutePaths.expenseHistory: (_) => const ExpenseHistoryScreen(),
  RoutePaths.products: (_) => const ProductListScreen(),
  RoutePaths.productEditor: (_) => const ProductEditorScreen(),
  RoutePaths.withdrawals: (_) => const WithdrawalScreen(),
  RoutePaths.reports: (_) => const ReportsScreen(),
  RoutePaths.settings: (_) => const SettingsScreen(),
  RoutePaths.guide: (_) => const GuideScreen(),
  // The longest lesson, which is where the step cards run out of room first.
  GuideLesson.recordingSales.path: (_) =>
      const GuideLessonScreen(lesson: GuideLesson.recordingSales),
  RoutePaths.privacy: (_) => const PrivacyScreen(),
  // The longest document, which is where paragraphs run out of room first.
  RoutePaths.legalFor(LegalDocument.privacyNotice): (_) =>
      const LegalScreen(document: LegalDocument.privacyNotice),
};

/// A believable day at the counter, with the long names and large amounts
/// that break layouts: several sales, a loss-making product, low stock,
/// expenses in several categories, and an owner withdrawal.
Future<void> _seedBusyDay(TestPhone phone) async {
  final db = phone.db;
  final products = ProductRepository(db: db, storeId: testStoreId);
  final sales = SaleRepository(db: db, storeId: testStoreId);

  final rice = await products.save(
    name: 'Premium Dinorado Rice, 25 kilogram sack (per kilo)',
    costPrice: 52,
    sellingPrice: 58.5,
    stockQuantity: 2.5,
    reorderLevel: 10,
  );
  final coke = await products.save(
    name: 'Coke 1.5L',
    costPrice: 68,
    sellingPrice: 75,
    stockQuantity: 24,
    reorderLevel: 6,
  );
  final loss = await products.save(
    name: 'Cooking oil 1L',
    costPrice: 95,
    sellingPrice: 90,
    stockQuantity: 12,
    reorderLevel: 3,
  );

  await sales.record(cart: [CartLine.fromProduct(rice, quantity: 2)]);
  await sales.record(
    cart: [CartLine.fromProduct(coke, quantity: 3), CartLine.fromProduct(loss)],
    paymentMethod: PaymentMethod.bankTransfer,
  );
  await sales.record(
    cart: [CartLine.quick(12345.67)],
    paymentMethod: PaymentMethod.utang,
  );

  final expenses = ExpenseRepository(db: db, storeId: testStoreId);
  await expenses.record(
    category: ExpenseCategory.taxesPermits,
    amount: 18500,
    description: 'Barangay business permit renewal and sanitary permit',
  );
  await expenses.record(category: ExpenseCategory.transportation, amount: 350);

  await WithdrawalRepository(
    db: db,
    storeId: testStoreId,
  ).record(amount: 25000, reason: 'Tuition for the eldest, second semester');
}

/// The owner's cloud-only screens, and screens as a cashier sees them. Each
/// runs with a fake server: empty on a quiet day, full on a busy one.
final Map<String, (String, WidgetBuilder, AuthSession)> _signedInScreens = {
  'staff': (RoutePaths.staff, (_) => const StaffScreen(), cloudOwner()),
  'devices': (RoutePaths.devices, (_) => const DevicesScreen(), cloudOwner()),
  'activity': (
    RoutePaths.activity,
    (_) => const ActivityScreen(),
    cloudOwner(),
  ),
  'settings, cloud owner': (
    RoutePaths.settings,
    (_) => const SettingsScreen(),
    cloudOwner(),
  ),
  'home, cashier': (
    RoutePaths.dashboard,
    (_) => const DashboardScreen(),
    staffMember({}),
  ),
  'settings, cashier': (
    RoutePaths.settings,
    (_) => const SettingsScreen(),
    staffMember({}),
  ),
  'signed out': (
    RoutePaths.sessionEnded,
    (_) => const SessionEndedScreen(),
    cloudOwner(ended: true),
  ),
  'join a store': (
    RoutePaths.joinStore,
    (_) => const JoinStoreScreen(),
    cloudOwner(),
  ),
  'reports, compared with other stores': (
    RoutePaths.reports,
    (_) => const ReportsScreen(),
    cloudOwner(),
  ),
  'plan, paused': (
    RoutePaths.plan,
    (_) => const PlanScreen(),
    cloudOwner(subscription: pausedPlan),
  ),
  'home, paused owner': (
    RoutePaths.dashboard,
    (_) => const DashboardScreen(),
    cloudOwner(subscription: pausedPlan),
  ),
  'closing an account': (
    RoutePaths.closeAccount,
    (_) => const CloseAccountScreen(),
    cloudOwner(),
  ),
  'privacy, cloud owner': (
    RoutePaths.privacy,
    (_) => const PrivacyScreen(),
    cloudOwner(),
  ),
  'guide, cashier': (
    RoutePaths.guide,
    (_) => const GuideScreen(),
    staffMember({}),
  ),
  'home, trial ending, cashier': (
    RoutePaths.dashboard,
    (_) => const DashboardScreen(),
    staffMember({}, subscription: trialWithDaysLeft(2)),
  ),
};

FakeBillingApi _billing({required bool busy}) => FakeBillingApi(
  overviewToShow: billingOverview(
    payments: busy
        ? [
            for (final (index, months) in [1, 12, 1].indexed)
              PaymentRecord(
                id: 'p$index',
                plan: index.isEven ? PlanTier.pro : PlanTier.basic,
                months: months,
                amount: months == 12 ? 1990 : 199,
                paidAt: DateTime(2026, 9 - index, 3),
                method: 'gcash',
              ),
          ]
        : const [],
  ),
);

FakeTeamApi _busyTeam() => FakeTeamApi()
  ..staffList.addAll([
    const StaffMember(
      id: 'liza',
      displayName: 'Liza Dela Cruz-Santos',
      permissions: {Permission.manageProducts, Permission.recordExpenses},
      signedInDevices: 2,
    ),
    StaffMember(
      id: 'ben',
      displayName: 'Ben',
      permissions: const {},
      inviteExpiresAt: DateTime.now().add(const Duration(hours: 20)),
    ),
  ])
  ..deviceList = sampleDevices()
  ..activityPages = [ActivityPage(events: sampleActivity(), nextBefore: 1)];

const _configurations = [
  ('normal text, light', 1.0, Brightness.light, Locale('en'), false),
  ('large text, light', 1.4, Brightness.light, Locale('en'), false),
  ('large text, dark', 1.4, Brightness.dark, Locale('en'), false),
  // Filipino strings run longer than English; they must fit too.
  ('large text, Filipino', 1.4, Brightness.light, Locale('fil'), false),
  (
    'busy day, large text, Filipino',
    1.4,
    Brightness.light,
    Locale('fil'),
    true,
  ),
  ('busy day, large text, dark', 1.4, Brightness.dark, Locale('en'), true),
];

Future<void> _meetsGuidelines(WidgetTester tester) async {
  // A layout overflow is reported as an exception and fails the test by
  // itself; these add the platform accessibility guidelines.
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(tester, meetsGuideline(textContrastGuideline));
}

void main() {
  for (final entry in _screens.entries) {
    group(entry.key, () {
      for (final (label, scale, brightness, locale, busy) in _configurations) {
        testWidgets(label, (tester) async {
          final phone = await TestPhone.open(
            tester,
            screens: {entry.key: entry.value},
            textScale: scale,
            brightness: brightness,
            locale: locale,
          );
          if (busy) await _seedBusyDay(phone);
          await phone.goTo(tester, entry.key);

          await _meetsGuidelines(tester);
        });
      }
    });
  }

  for (final MapEntry(key: name, value: (path, screen, session))
      in _signedInScreens.entries) {
    group(name, () {
      for (final (label, scale, brightness, locale, busy) in _configurations) {
        testWidgets(label, (tester) async {
          final phone = await TestPhone.open(
            tester,
            screens: {path: screen},
            textScale: scale,
            brightness: brightness,
            locale: locale,
            overrides: (_, _) => [
              currentSessionProvider.overrideWithValue(session),
              teamApiProvider.overrideWithValue(
                busy ? _busyTeam() : FakeTeamApi(),
              ),
              billingApiProvider.overrideWithValue(_billing(busy: busy)),
              benchmarksApiProvider.overrideWithValue(FakeBenchmarksApi()),
            ],
          );
          if (busy) await _seedBusyDay(phone);
          await phone.goTo(tester, path);

          await _meetsGuidelines(tester);
        });
      }
    });
  }
}
