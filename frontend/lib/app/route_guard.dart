import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  final signedIn = auth.value != null;

  if (location == RoutePaths.splash) {
    return signedIn ? RoutePaths.dashboard : RoutePaths.welcome;
  }

  final atPublicRoute = RoutePaths.publicRoutes.contains(location);
  if (!signedIn && !atPublicRoute) return RoutePaths.welcome;
  if (signedIn && atPublicRoute) return RoutePaths.dashboard;
  return null;
}
