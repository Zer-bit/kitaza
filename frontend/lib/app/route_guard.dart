import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/access_grant.dart';
import '../data/models/auth_session.dart';
import 'route_paths.dart';

/// Where the app should be, given who is signed in and where it is now.
/// Returns null to stay put.
///
/// A pure function so every routing rule can be tested without building a
/// widget tree.
String? resolveRoute(AsyncValue<AuthSession?> auth, String location) {
  // While auth is working, hold position. On first launch that position is
  // the splash, so the first real screen is the right one rather than a
  // guess; during sign-in it is the form, which must not be torn down with
  // the owner's typing in it.
  if (auth.isLoading && !auth.hasValue) return null;

  final session = auth.value;

  if (session != null && session.ended) {
    return RoutePaths.endedRoutes.contains(location)
        ? null
        : RoutePaths.sessionEnded;
  }

  final signedIn = session != null;

  if (location == RoutePaths.splash) {
    return signedIn ? RoutePaths.dashboard : RoutePaths.welcome;
  }

  // The privacy notice and the terms are readable by anyone, signed in or
  // not: agreeing to something you cannot read is not agreeing.
  if (location.startsWith('${RoutePaths.legal}/')) return null;

  final atPublicRoute = RoutePaths.publicRoutes.contains(location);
  if (!signedIn && !atPublicRoute) return RoutePaths.welcome;
  if (signedIn && atPublicRoute) return RoutePaths.dashboard;
  if (location == RoutePaths.sessionEnded) {
    return signedIn ? RoutePaths.dashboard : RoutePaths.welcome;
  }
  if (signedIn && !mayOpen(session, location)) return RoutePaths.dashboard;
  return null;
}

/// Whether this person may open [location]. Buttons for screens they cannot
/// use are hidden; this catches a stale link or a permission taken away
/// while the screen was open.
bool mayOpen(AuthSession session, String location) {
  final access = session.access;
  return switch (location) {
    RoutePaths.reports => access.can(Permission.viewProfit),
    RoutePaths.withdrawals => access.isOwner,
    RoutePaths.recordExpense => access.can(Permission.recordExpenses),
    RoutePaths.expenseHistory =>
      access.can(Permission.recordExpenses) ||
          access.can(Permission.viewProfit),
    RoutePaths.productEditor => access.can(Permission.manageProducts),
    RoutePaths.cloudUpgrade => !session.isCloud,
    RoutePaths.staff ||
    RoutePaths.devices ||
    RoutePaths.activity ||
    RoutePaths.plan => session.isCloud && access.isOwner,
    _ => true,
  };
}
