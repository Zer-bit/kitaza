/// Where a store's data lives. Chosen once during onboarding and changeable
/// later in settings.
enum StorageMode {
  /// Everything stays in SQLite on this device. No account, no network, no
  /// monthly cost.
  local,

  /// Still written to SQLite first, then synced to the Kitaza cloud so the
  /// owner can use a second device and survive a lost phone.
  cloud;

  static StorageMode parse(String? raw) =>
      raw == cloud.name ? StorageMode.cloud : StorageMode.local;

  bool get isCloud => this == StorageMode.cloud;
}
