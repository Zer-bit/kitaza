import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/access_grant.dart';
import '../models/activity_event.dart';
import '../models/signed_in_device.dart';
import '../models/staff_member.dart';
import '../models/store_profile.dart';
import 'api_client.dart';
import 'api_endpoints.dart';

/// The owner's tools for running more than one phone: stores, staff, signed-in
/// devices and the activity log. All of it needs a connection; none of it is
/// kept on the phone.
class TeamApi {
  const TeamApi(this._client);

  final ApiClient _client;

  Future<StoreProfile> addStore({
    required String name,
    required String businessType,
  }) async {
    final body = await _client.post(
      ApiEndpoints.stores,
      body: {'name': name, 'business_type': businessType},
    );
    return StoreProfile.fromJson(body);
  }

  Future<StoreProfile> renameStore(String storeId, String name) async {
    final body = await _client.patch(
      ApiEndpoints.store(storeId),
      body: {'name': name},
    );
    return StoreProfile.fromJson(body);
  }

  Future<List<StaffMember>> staff(String storeId) async {
    final rows = await _client.getList(ApiEndpoints.staff(storeId));
    return [
      for (final row in rows) StaffMember.fromJson(row as Map<String, dynamic>),
    ];
  }

  Future<({StaffMember staff, JoinInvite invite})> addStaff(
    String storeId, {
    required String name,
    required Set<Permission> permissions,
  }) async {
    final body = await _client.post(
      ApiEndpoints.staff(storeId),
      body: _staffBody(name, permissions),
    );
    return (
      staff: StaffMember.fromJson(body['staff'] as Map<String, dynamic>),
      invite: JoinInvite.fromJson(body['invite'] as Map<String, dynamic>),
    );
  }

  Future<StaffMember> updateStaff(
    String storeId,
    String staffId, {
    required String name,
    required Set<Permission> permissions,
  }) async {
    final body = await _client.patch(
      ApiEndpoints.staffMember(storeId, staffId),
      body: _staffBody(name, permissions),
    );
    return StaffMember.fromJson(body);
  }

  Future<void> removeStaff(String storeId, String staffId) =>
      _client.delete(ApiEndpoints.staffMember(storeId, staffId));

  Future<JoinInvite> newJoinCode(String storeId, String staffId) async {
    final body = await _client.post(ApiEndpoints.staffInvite(storeId, staffId));
    return JoinInvite.fromJson(body);
  }

  Future<List<SignedInDevice>> devices() async {
    final rows = await _client.getList(ApiEndpoints.devices);
    return [
      for (final row in rows)
        SignedInDevice.fromJson(row as Map<String, dynamic>),
    ];
  }

  Future<void> signOutDevice(String sessionId) =>
      _client.delete(ApiEndpoints.device(sessionId));

  Future<ActivityPage> activity(
    String storeId, {
    int? before,
    bool onlyRemovals = false,
  }) async {
    final body = await _client.get(
      ApiEndpoints.activity(storeId),
      query: {'before': ?before, if (onlyRemovals) 'filter': 'removals'},
    );
    return ActivityPage(
      events: [
        for (final row in (body['events'] as List?) ?? const [])
          ActivityEvent.fromJson(row as Map<String, dynamic>),
      ],
      nextBefore: (body['next_before'] as num?)?.toInt(),
    );
  }

  static Map<String, Object?> _staffBody(
    String name,
    Set<Permission> permissions,
  ) => {
    'display_name': name,
    'permissions': [for (final permission in permissions) permission.wireName],
  };
}

final teamApiProvider = Provider<TeamApi>(
  (ref) => TeamApi(ref.watch(apiClientProvider)),
);
