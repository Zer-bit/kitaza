import 'access_grant.dart';

/// Someone the owner has let use the store, as the owner's staff list shows
/// them.
class StaffMember {
  const StaffMember({
    required this.id,
    required this.displayName,
    required this.permissions,
    this.signedInDevices = 0,
    this.inviteExpiresAt,
  });

  final String id;
  final String displayName;
  final Set<Permission> permissions;
  final int signedInDevices;

  /// When their unused join code stops working, if they have one.
  final DateTime? inviteExpiresAt;

  bool get hasPendingInvite =>
      inviteExpiresAt != null && inviteExpiresAt!.isAfter(DateTime.now());

  factory StaffMember.fromJson(Map<String, dynamic> json) => StaffMember(
    id: json['id'] as String,
    displayName: json['display_name'] as String,
    permissions: {
      for (final raw in (json['permissions'] as List?) ?? const [])
        ?Permission.parse(raw as String),
    },
    signedInDevices: (json['signed_in_devices'] as num?)?.toInt() ?? 0,
    inviteExpiresAt: DateTime.tryParse(
      json['invite_expires_at'] as String? ?? '',
    )?.toLocal(),
  );
}

/// A one-time join code, shown once when it is made.
class JoinInvite {
  const JoinInvite({required this.code, required this.expiresAt});

  final String code;
  final DateTime expiresAt;

  factory JoinInvite.fromJson(Map<String, dynamic> json) => JoinInvite(
    code: json['code'] as String,
    expiresAt: DateTime.parse(json['expires_at'] as String).toLocal(),
  );
}
