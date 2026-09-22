import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitaza_app/app/route_guard.dart';
import 'package:kitaza_app/app/route_paths.dart';
import 'package:kitaza_app/core/config/storage_mode.dart';
import 'package:kitaza_app/data/models/auth_session.dart';
import 'package:kitaza_app/data/models/owner_account.dart';
import 'package:kitaza_app/data/models/store_profile.dart';

void main() {
  const session = AuthSession(
    owner: OwnerAccount(id: 'o', fullName: 'Nena'),
    store: StoreProfile(id: 's', name: 'Store'),
    mode: StorageMode.local,
  );

  const restoring = AsyncValue<AuthSession?>.loading();
  const signedIn = AsyncValue<AuthSession?>.data(session);
  const signedOut = AsyncValue<AuthSession?>.data(null);

  group('on launch', () {
    test('the splash stays up while the stored session is read', () {
      expect(resolveRoute(restoring, RoutePaths.splash), isNull);
    });

    test('a returning device goes straight to the dashboard', () {
      expect(resolveRoute(signedIn, RoutePaths.splash), RoutePaths.dashboard);
    });

    test('a new device is welcomed', () {
      expect(resolveRoute(signedOut, RoutePaths.splash), RoutePaths.welcome);
    });
  });

  group('while signing in', () {
    test('the form is not torn down while the request is in flight', () {
      expect(resolveRoute(restoring, RoutePaths.signIn), isNull);
    });

    test('a failed attempt leaves the owner on the form to try again', () {
      final failed = AsyncValue<AuthSession?>.error(
        'wrong password',
        StackTrace.empty,
      );
      expect(resolveRoute(failed, RoutePaths.signIn), isNull);
    });

    test('success moves on to the dashboard', () {
      expect(resolveRoute(signedIn, RoutePaths.signIn), RoutePaths.dashboard);
    });
  });

  group('guarding screens', () {
    test('store screens need a session', () {
      expect(
        resolveRoute(signedOut, RoutePaths.saleHistory),
        RoutePaths.welcome,
      );
      expect(resolveRoute(signedOut, RoutePaths.settings), RoutePaths.welcome);
    });

    test('signing out from settings returns to the welcome screen', () {
      expect(
        resolveRoute(signedOut, RoutePaths.syncProblems),
        RoutePaths.welcome,
      );
    });

    test('a signed-in owner can go anywhere in the store', () {
      expect(resolveRoute(signedIn, RoutePaths.recordSale), isNull);
      expect(resolveRoute(signedIn, RoutePaths.cloudUpgrade), isNull);
    });
  });
}
