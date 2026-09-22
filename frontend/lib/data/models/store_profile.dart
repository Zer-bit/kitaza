class StoreProfile {
  const StoreProfile({
    required this.id,
    required this.name,
    this.businessType = 'sari_sari',
    this.currencyCode = 'PHP',
  });

  final String id;
  final String name;
  final String businessType;
  final String currencyCode;

  factory StoreProfile.fromJson(Map<String, dynamic> json) => StoreProfile(
    id: json['id'] as String,
    name: json['name'] as String? ?? 'My store',
    businessType: json['business_type'] as String? ?? 'sari_sari',
    currencyCode: json['currency_code'] as String? ?? 'PHP',
  );

  Map<String, Object?> toRow() => {
    'id': id,
    'name': name,
    'business_type': businessType,
    'currency_code': currencyCode,
  };

  factory StoreProfile.fromRow(Map<String, Object?> row) => StoreProfile(
    id: row['id'] as String,
    name: row['name'] as String,
    businessType: row['business_type'] as String? ?? 'sari_sari',
    currencyCode: row['currency_code'] as String? ?? 'PHP',
  );
}
