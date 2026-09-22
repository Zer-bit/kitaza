import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitaza_app/app/route_guard.dart';
import 'package:kitaza_app/app/route_paths.dart';
import 'package:kitaza_app/core/config/storage_mode.dart';
import 'package:kitaza_app/data/models/access_grant.dart';
import 'package:kitaza_app/data/models/auth_session.dart';
import 'package:kitaza_app/data/models/owner_account.dart';
import 'package:kitaza_app/data/models/store_profile.dart';

void main() {
  final session = AuthSession(
    owner: OwnerAccount(id: 'o', fullName: 'Nena'),
    store: StoreProfile(id: 's', name: 'Store'),
    mode: StorageMode.local,
  );

  const restoring = AsyncValue<AuthSession?>.loading();
  final signedIn = AsyncValue<AuthSession?>.data(session);
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

  group('a phone the server signed out', () {
    final ended = AsyncValue<AuthSession?>.data(
      AuthSession(
        owner: const OwnerAccount(id: 'o', fullName: 'Nena'),
        store: const StoreProfile(id: 's', name: 'Store'),
        mode: StorageMode.cloud,
        ended: true,
      ),
    );

    test('is told so instead of opening the store', () {
      expect(resolveRoute(ended, RoutePaths.splash), RoutePaths.sessionEnded);
      expect(
        resolveRoute(ended, RoutePaths.dashboard),
        RoutePaths.sessionEnded,
      );
      expect(resolveRoute(ended, RoutePaths.welcome), RoutePaths.sessionEnded);
    });

    test('can go back in, as the owner or with a new join code', () {
      expect(resolveRoute(ended, RoutePaths.sessionEnded), isNull);
      expect(resolveRoute(ended, RoutePaths.signIn), isNull);
      expect(resolveRoute(ended, RoutePaths.joinStore), isNull);
    });

    test('once back in, never shows the signed-out screen', () {
      expect(
        resolveRoute(signedIn, RoutePaths.sessionEnded),
        RoutePaths.dashboard,
      );
    });
  });

  group('staff', () {
    AsyncValue<AuthSession?> staffWith(Set<Permission> permissions) =>
        AsyncValue.data(
          AuthSession(
            owner: const OwnerAccount(id: 'o', fullName: 'Nena'),
            store: const StoreProfile(id: 's', name: 'Store'),
            mode: StorageMode.cloud,
            access: AccessGrant(
              role: MemberRole.staff,
              displayName: 'Liza',
              staffId: 'liza',
              permissions: permissions,
            ),
          ),
        );

    test('a cashier sells but is kept out of the money and settings', () {
      final cashier = staffWith({});

      expect(resolveRoute(cashier, RoutePaths.recordSale), isNull);
      expect(resolveRoute(cashier, RoutePaths.saleHistory), isNull);
      for (final closed in [
        RoutePaths.reports,
        RoutePaths.withdrawals,
        RoutePaths.recordExpense,
        RoutePaths.expenseHistory,
        RoutePaths.productEditor,
        RoutePaths.staff,
        RoutePaths.devices,
        RoutePaths.activity,
      ]) {
        expect(
          resolveRoute(cashier, closed),
          RoutePaths.dashboard,
          reason: closed,
        );
      }
    });

    test('each permission opens its own screens and no others', () {
      final bookkeeper = staffWith({
        Permission.viewProfit,
        Permission.recordExpenses,
      });

      expect(resolveRoute(bookkeeper, RoutePaths.reports), isNull);
      expect(resolveRoute(bookkeeper, RoutePaths.recordExpense), isNull);
      expect(
        resolveRoute(bookkeeper, RoutePaths.productEditor),
        RoutePaths.dashboard,
      );
      expect(
        resolveRoute(bookkeeper, RoutePaths.withdrawals),
        RoutePaths.dashboard,
        reason: "withdrawals are the owner's own money",
      );
    });
  });
}
