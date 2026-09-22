/// A phone or tablet signed in to the owner's account or one of their
/// stores.
class SignedInDevice {
  const SignedInDevice({
    required this.id,
    required this.deviceName,
    required this.memberName,
    required this.isStaff,
    required this.signedInAt,
    required this.lastSeenAt,
    this.isCurrent = false,
  });

  final String id;
  final String deviceName;
  final String memberName;
  final bool isStaff;
  final DateTime signedInAt;
  final DateTime lastSeenAt;

  /// The phone this list is being read on.
  final bool isCurrent;

  factory SignedInDevice.fromJson(Map<String, dynamic> json) => SignedInDevice(
    id: json['id'] as String,
    deviceName: json['device_name'] as String,
    memberName: json['member_name'] as String,
    isStaff: json['is_staff'] as bool? ?? false,
    signedInAt: DateTime.parse(json['signed_in_at'] as String).toLocal(),
    lastSeenAt: DateTime.parse(json['last_seen_at'] as String).toLocal(),
    isCurrent: json['is_current'] as bool? ?? false,
  );
}
