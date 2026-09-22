import 'package:kitaza_app/core/config/storage_mode.dart';
import 'package:kitaza_app/core/errors/app_failure.dart';
import 'package:kitaza_app/data/models/access_grant.dart';
import 'package:kitaza_app/data/models/activity_event.dart';
import 'package:kitaza_app/data/models/auth_session.dart';
import 'package:kitaza_app/data/models/owner_account.dart';
import 'package:kitaza_app/data/models/signed_in_device.dart';
import 'package:kitaza_app/data/models/staff_member.dart';
import 'package:kitaza_app/data/models/store_profile.dart';
import 'package:kitaza_app/data/remote/team_api.dart';

import 'in_memory_database.dart';

const _owner = OwnerAccount(
  id: 'owner',
  fullName: 'Nena Reyes',
  email: 'nena@example.com',
);
const _home = StoreProfile(id: testStoreId, name: 'Test Store');
const _branch = StoreProfile(id: 'branch', name: "Nena's Carinderia sa Kanto");

/// An owner signed in to the cloud with two stores.
AuthSession cloudOwner({bool ended = false}) => AuthSession(
  owner: _owner,
  store: _home,
  stores: const [_home, _branch],
  mode: StorageMode.cloud,
  ended: ended,
);

/// A staff member of the test store with [permissions].
AuthSession staffMember(Set<Permission> permissions, {bool ended = false}) =>
    AuthSession(
      owner: const OwnerAccount(id: 'owner', fullName: 'Nena Reyes'),
      store: _home,
      mode: StorageMode.cloud,
      ended: ended,
      access: AccessGrant(
        role: MemberRole.staff,
        displayName: 'Liza',
        staffId: 'liza',
        permissions: permissions,
      ),
    );

/// Stands in for the server's staff, devices and activity endpoints.
class FakeTeamApi implements TeamApi {
  final List<StaffMember> staffList = [];
  final List<({String name, Set<Permission> permissions})> added = [];
  final List<String> removed = [];
  final List<String> signedOut = [];
  final List<({int? before, bool onlyRemovals})> activityRequests = [];
  List<SignedInDevice> deviceList = [];
  List<ActivityPage> activityPages = [];
  Object? failWith;

  JoinInvite invite = JoinInvite(
    code: 'ABCDE-FGHJK',
    expiresAt: DateTime.now().add(const Duration(hours: 24)),
  );

  void _maybeFail() {
    if (failWith case final error?) throw error;
  }

  @override
  Future<List<StaffMember>> staff(String storeId) async {
    _maybeFail();
    return List.of(staffList);
  }

  @override
  Future<({StaffMember staff, JoinInvite invite})> addStaff(
    String storeId, {
    required String name,
    required Set<Permission> permissions,
  }) async {
    _maybeFail();
    added.add((name: name, permissions: Set.of(permissions)));
    final member = StaffMember(
      id: 'staff-${added.length}',
      displayName: name,
      permissions: permissions,
    );
    staffList.add(member);
    return (staff: member, invite: invite);
  }

  @override
  Future<StaffMember> updateStaff(
    String storeId,
    String staffId, {
    required String name,
    required Set<Permission> permissions,
  }) async {
    _maybeFail();
    return StaffMember(
      id: staffId,
      displayName: name,
      permissions: permissions,
    );
  }

  @override
  Future<void> removeStaff(String storeId, String staffId) async {
    _maybeFail();
    removed.add(staffId);
    staffList.removeWhere((member) => member.id == staffId);
  }

  @override
  Future<JoinInvite> newJoinCode(String storeId, String staffId) async {
    _maybeFail();
    return invite;
  }

  @override
  Future<List<SignedInDevice>> devices() async {
    _maybeFail();
    return List.of(deviceList);
  }

  @override
  Future<void> signOutDevice(String sessionId) async {
    _maybeFail();
    signedOut.add(sessionId);
    deviceList = [
      for (final device in deviceList)
        if (device.id != sessionId) device,
    ];
  }

  @override
  Future<ActivityPage> activity(
    String storeId, {
    int? before,
    bool onlyRemovals = false,
  }) async {
    _maybeFail();
    activityRequests.add((before: before, onlyRemovals: onlyRemovals));
    if (activityPages.isEmpty) return const ActivityPage(events: []);
    return activityPages.removeAt(0);
  }

  @override
  Future<StoreProfile> addStore({
    required String name,
    required String businessType,
  }) async {
    _maybeFail();
    return StoreProfile(id: 'new-store', name: name);
  }

  @override
  Future<StoreProfile> renameStore(String storeId, String name) async {
    _maybeFail();
    return StoreProfile(id: storeId, name: name);
  }
}

/// No signal.
const offline = AppFailure.offline();

/// Devices as an owner with a staff member would see them.
List<SignedInDevice> sampleDevices() {
  final now = DateTime.now();
  return [
    SignedInDevice(
      id: 'mine',
      deviceName: 'Samsung SM-A125F',
      memberName: 'Nena Reyes',
      isStaff: false,
      signedInAt: now.subtract(const Duration(days: 30)),
      lastSeenAt: now,
      isCurrent: true,
    ),
    SignedInDevice(
      id: 'counter',
      deviceName: 'Vivo Y12s counter phone with a long name',
      memberName: 'Liza Dela Cruz-Santos',
      isStaff: true,
      signedInAt: now.subtract(const Duration(days: 3)),
      lastSeenAt: now.subtract(const Duration(hours: 5)),
    ),
  ];
}

/// A day of activity covering the kinds of line the log shows.
List<ActivityEvent> sampleActivity() {
  final now = DateTime.now();
  ActivityEvent event(
    int id,
    ActivityAction action,
    Map<String, dynamic> details, {
    String actor = 'Liza Dela Cruz-Santos',
    bool staff = true,
    Duration ago = Duration.zero,
  }) => ActivityEvent(
    id: id,
    action: action,
    actorName: actor,
    isStaff: staff,
    deviceName: staff ? 'Vivo Y12s' : 'Samsung SM-A125F',
    details: details,
    occurredAt: now.subtract(ago),
  );

  return [
    event(
      6,
      ActivityAction.saleVoided,
      {'total': 1250.5},
      actor: 'Nena Reyes',
      staff: false,
    ),
    event(5, ActivityAction.saleRecorded, {'total': 75, 'items': 1}),
    event(
      4,
      ActivityAction.productChanged,
      {
        'name': 'Coke 1.5L',
        'changes': {
          'selling_price': [70, 75],
          'cost_price': [60, 68],
        },
      },
      actor: 'Nena Reyes',
      staff: false,
    ),
    event(3, ActivityAction.stockCounted, {
      'name': 'Rice',
      'counted': 17,
      'change': -3,
    }, ago: const Duration(days: 1)),
    event(
      2,
      ActivityAction.staffAdded,
      {
        'name': 'Liza Dela Cruz-Santos',
        'permissions': ['manage_products'],
      },
      actor: 'Nena Reyes',
      staff: false,
      ago: const Duration(days: 1),
    ),
    event(1, ActivityAction.expenseDeleted, {
      'amount': 350,
      'category': 'transportation',
    }, ago: const Duration(days: 2)),
  ];
}
