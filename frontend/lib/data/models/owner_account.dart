class OwnerAccount {
  const OwnerAccount({required this.id, required this.fullName, this.email});

  final String id;
  final String fullName;

  /// Absent in local-only mode, where there is no account at all.
  final String? email;

  factory OwnerAccount.fromJson(Map<String, dynamic> json) => OwnerAccount(
    id: json['id'] as String,
    fullName: json['full_name'] as String? ?? 'Owner',
    email: json['email'] as String?,
  );

  Map<String, Object?> toRow() => {
    'id': id,
    'full_name': fullName,
    'email': email,
  };

  factory OwnerAccount.fromRow(Map<String, Object?> row) => OwnerAccount(
    id: row['id'] as String,
    fullName: row['full_name'] as String,
    email: row['email'] as String?,
  );
}
