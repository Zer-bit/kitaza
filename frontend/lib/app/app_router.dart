import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/models/guide_lesson.dart';
import '../data/models/legal_document.dart';
import '../features/authentication/auth_controller.dart';
import '../features/authentication/join_store_screen.dart';
import '../features/authentication/local_setup_screen.dart';
import '../features/authentication/session_ended_screen.dart';
import '../features/authentication/sign_in_screen.dart';
import '../features/authentication/sign_up_screen.dart';
import '../features/authentication/welcome_screen.dart';
import '../features/billing/plan_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/expenses/expense_history_screen.dart';
import '../features/expenses/record_expense_screen.dart';
import '../features/guide/guide_lesson_screen.dart';
import '../features/guide/guide_screen.dart';
import '../features/legal/legal_screen.dart';
import '../features/privacy/close_account_screen.dart';
import '../features/privacy/privacy_screen.dart';
import '../features/products/product_editor_screen.dart';
import '../features/products/product_list_screen.dart';
import '../features/reports/reports_screen.dart';
import '../features/sales/record_sale_screen.dart';
import '../features/sales/sale_history_screen.dart';
import '../features/settings/cloud_upgrade_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/settings/sync_problems_screen.dart';
import '../features/shell/home_shell.dart';
import '../features/splash/splash_screen.dart';
import '../features/team/activity_screen.dart';
import '../features/team/devices_screen.dart';
import '../features/team/staff_screen.dart';
import '../features/withdrawals/withdrawal_screen.dart';
import 'route_guard.dart';
import 'route_paths.dart';

final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Bridges Riverpod's auth state to go_router's `refreshListenable`, so the
/// redirect re-runs on sign-in and sign-out without the router itself being
/// rebuilt.
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(Ref ref) {
    ref.listen(authControllerProvider, (_, _) => notifyListeners());
  }
}

/// Routing is derived from the session: there is no imperative "go to login"
/// anywhere in the app, only a redirect that reacts to auth state.
///
/// The router is created once. Recreating it on every auth change would reset
/// the navigation stack and replay the initial route, which shows up as a
/// flicker between the splash and the first real screen.
final appRouterProvider = Provider<GoRouter>((ref) {
  final authChanges = _AuthChangeNotifier(ref);
  ref.onDispose(authChanges.dispose);

  return GoRouter(
    initialLocation: RoutePaths.splash,
    debugLogDiagnostics: false,
    refreshListenable: authChanges,
    redirect: (context, state) =>
        resolveRoute(ref.read(authControllerProvider), state.matchedLocation),
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: SplashScreen()),
      ),
      GoRoute(
        path: RoutePaths.welcome,
        builder: (context, state) => const WelcomeScreen(),
        routes: [
          GoRoute(
            path: 'offline',
            builder: (context, state) => const LocalSetupScreen(),
          ),
        ],
      ),
      GoRoute(
        path: RoutePaths.signIn,
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: RoutePaths.signUp,
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: RoutePaths.joinStore,
        builder: (context, state) => const JoinStoreScreen(),
      ),
      GoRoute(
        path: RoutePaths.sessionEnded,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: SessionEndedScreen()),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(
            path: RoutePaths.dashboard,
            pageBuilder: (context, state) =>
                _fadeThrough(state, const DashboardScreen()),
          ),
          GoRoute(
            path: RoutePaths.saleHistory,
            pageBuilder: (context, state) =>
                _fadeThrough(state, const SaleHistoryScreen()),
          ),
          GoRoute(
            path: RoutePaths.expenseHistory,
            pageBuilder: (context, state) =>
                _fadeThrough(state, const ExpenseHistoryScreen()),
          ),
          GoRoute(
            path: RoutePaths.reports,
            pageBuilder: (context, state) =>
                _fadeThrough(state, const ReportsScreen()),
          ),
          GoRoute(
            path: RoutePaths.products,
            pageBuilder: (context, state) =>
                _fadeThrough(state, const ProductListScreen()),
          ),
        ],
      ),
      GoRoute(
        path: RoutePaths.recordSale,
        builder: (context, state) => const RecordSaleScreen(),
      ),
      GoRoute(
        path: RoutePaths.recordExpense,
        builder: (context, state) => const RecordExpenseScreen(),
      ),
      GoRoute(
        path: RoutePaths.productEditor,
        builder: (context, state) => ProductEditorScreen(
          productId: state.uri.queryParameters['id'],
          initialBarcode: state.uri.queryParameters['barcode'],
        ),
      ),
      GoRoute(
        path: RoutePaths.withdrawals,
        builder: (context, state) => const WithdrawalScreen(),
      ),
      // Readable without signing in: someone deciding whether to make an
      // account has to be able to read what they would be agreeing to.
      GoRoute(
        path: '${RoutePaths.legal}/:document',
        builder: (context, state) {
          final document = LegalDocument.parse(
            state.pathParameters['document'] ?? '',
          );
          return LegalScreen(document: document ?? LegalDocument.privacyNotice);
        },
      ),
      GoRoute(
        path: RoutePaths.guide,
        builder: (context, state) => const GuideScreen(),
        routes: [
          GoRoute(
            path: ':lesson',
            builder: (context, state) {
              final lesson = GuideLesson.named(state.pathParameters['lesson']);
              return lesson == null
                  ? const GuideScreen()
                  : GuideLessonScreen(lesson: lesson);
            },
          ),
        ],
      ),
      GoRoute(
        path: RoutePaths.settings,
        builder: (context, state) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'cloud',
            builder: (context, state) => const CloudUpgradeScreen(),
          ),
          GoRoute(
            path: 'sync-problems',
            builder: (context, state) => const SyncProblemsScreen(),
          ),
          GoRoute(
            path: 'staff',
            builder: (context, state) => const StaffScreen(),
          ),
          GoRoute(
            path: 'devices',
            builder: (context, state) => const DevicesScreen(),
          ),
          GoRoute(
            path: 'activity',
            builder: (context, state) => const ActivityScreen(),
          ),
          GoRoute(
            path: 'plan',
            builder: (context, state) => const PlanScreen(),
          ),
          GoRoute(
            path: 'privacy',
            builder: (context, state) => const PrivacyScreen(),
            routes: [
              GoRoute(
                path: 'close',
                builder: (context, state) => const CloseAccountScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

/// Tabs cross-fade instead of sliding: a horizontal slide implies a hierarchy
/// that the bottom bar does not have.
CustomTransitionPage<void> _fadeThrough(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeOut).animate(animation),
        child: child,
      );
    },
  );
}
