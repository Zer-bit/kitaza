import 'dart:convert';

/// Something an owner can let a staff member do. Selling is not on the list:
/// every staff member can sell.
enum Permission {
  manageProducts('manage_products'),
  recordExpenses('record_expenses'),
  viewProfit('view_profit'),
  deleteRecords('delete_records');

  const Permission(this.wireName);

  final String wireName;

  static Permission? parse(String raw) {
    for (final permission in values) {
      if (permission.wireName == raw) return permission;
    }
    return null;
  }
}

enum MemberRole { owner, staff }

/// Who is using this phone and what they may do, as the server last said.
///
/// Screens hide what a staff member cannot do, but the server enforces it
/// either way: this only decides what is offered, never what is allowed.
class AccessGrant {
  const AccessGrant({
    required this.role,
    required this.displayName,
    this.staffId,
    this.permissions = const {},
  });

  /// The owner can do everything. Also what every offline phone is, and what
  /// a phone set up before staff accounts existed is taken to be.
  const AccessGrant.owner(this.displayName)
    : role = MemberRole.owner,
      staffId = null,
      permissions = const {
        Permission.manageProducts,
        Permission.recordExpenses,
        Permission.viewProfit,
        Permission.deleteRecords,
      };

  final MemberRole role;
  final String displayName;
  final String? staffId;
  final Set<Permission> permissions;

  bool get isOwner => role == MemberRole.owner;
  bool get isStaff => role == MemberRole.staff;

  bool can(Permission permission) =>
      isOwner || permissions.contains(permission);

  /// Whether the same person is signed in, whatever their permissions now.
  bool isSamePersonAs(AccessGrant other) =>
      role == other.role && staffId == other.staffId;

  factory AccessGrant.fromJson(Map<String, dynamic> json) {
    final isStaff = json['role'] == 'staff';
    final name = json['display_name'] as String? ?? '';
    if (!isStaff) return AccessGrant.owner(name);

    return AccessGrant(
      role: MemberRole.staff,
      displayName: name,
      staffId: json['staff_id'] as String?,
      permissions: {
        for (final raw in (json['permissions'] as List?) ?? const [])
          ?Permission.parse(raw as String),
      },
    );
  }

  Map<String, Object?> toJson() => {
    'role': role.name,
    'display_name': displayName,
    'staff_id': ?staffId,
    'permissions': [for (final permission in permissions) permission.wireName],
  };

  String encode() => jsonEncode(toJson());

  static AccessGrant? decode(String? stored) {
    if (stored == null || stored.isEmpty) return null;
    try {
      return AccessGrant.fromJson(jsonDecode(stored) as Map<String, dynamic>);
    } on FormatException {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is AccessGrant &&
      other.role == role &&
      other.staffId == staffId &&
      other.displayName == displayName &&
      other.permissions.length == permissions.length &&
      other.permissions.containsAll(permissions);

  @override
  int get hashCode => Object.hash(
    role,
    staffId,
    displayName,
    Object.hashAllUnordered(permissions),
  );
}
