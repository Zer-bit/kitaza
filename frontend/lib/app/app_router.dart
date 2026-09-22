import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/authentication/auth_controller.dart';
import '../features/authentication/local_setup_screen.dart';
import '../features/authentication/sign_in_screen.dart';
import '../features/authentication/sign_up_screen.dart';
import '../features/authentication/welcome_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/expenses/expense_history_screen.dart';
import '../features/expenses/record_expense_screen.dart';
import '../features/products/product_editor_screen.dart';
import '../features/products/product_list_screen.dart';
import '../features/reports/reports_screen.dart';
import '../features/sales/record_sale_screen.dart';
import '../features/sales/sale_history_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/shell/home_shell.dart';
import '../features/withdrawals/withdrawal_screen.dart';
import 'route_paths.dart';

final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Routing is derived from the session: there is no imperative "go to login"
/// anywhere in the app, only a redirect that reacts to auth state.
final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: RoutePaths.dashboard,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      // While the stored session is still being read, hold position rather
      // than bouncing the user to a screen we may immediately leave.
      if (auth.isLoading) return null;

      final signedIn = auth.value != null;
      final atPublicRoute = RoutePaths.publicRoutes.contains(
        state.matchedLocation,
      );

      if (!signedIn && !atPublicRoute) return RoutePaths.welcome;
      if (signedIn && atPublicRoute) return RoutePaths.dashboard;
      return null;
    },
    routes: [
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
        builder: (context, state) =>
            ProductEditorScreen(productId: state.uri.queryParameters['id']),
      ),
      GoRoute(
        path: RoutePaths.withdrawals,
        builder: (context, state) => const WithdrawalScreen(),
      ),
      GoRoute(
        path: RoutePaths.settings,
        builder: (context, state) => const SettingsScreen(),
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
