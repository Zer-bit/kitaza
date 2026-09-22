/// What the activity log can say happened. Anything newer than this app is
/// shown as [other] rather than hidden.
enum ActivityAction {
  saleRecorded('sale_recorded'),
  saleVoided('sale_voided'),
  expenseRecorded('expense_recorded'),
  expenseDeleted('expense_deleted'),
  withdrawalRecorded('withdrawal_recorded'),
  withdrawalDeleted('withdrawal_deleted'),
  productAdded('product_added'),
  productChanged('product_changed'),
  productRemoved('product_removed'),
  stockReceived('stock_received'),
  stockRemoved('stock_removed'),
  stockCounted('stock_counted'),
  stockSpoiled('stock_spoiled'),
  staffAdded('staff_added'),
  staffChanged('staff_changed'),
  staffRemoved('staff_removed'),
  staffInvited('staff_invited'),
  staffJoined('staff_joined'),
  deviceSignedOut('device_signed_out'),
  storeAdded('store_added'),
  storeRenamed('store_renamed'),
  subscriptionPaid('subscription_paid'),
  other('');

  const ActivityAction(this.wireName);

  final String wireName;

  static ActivityAction parse(String raw) => values.firstWhere(
    (action) => action.wireName == raw,
    orElse: () => other,
  );

  /// Taking something away: what an owner looking for missing money checks.
  bool get isRemoval => const {
    saleVoided,
    expenseDeleted,
    withdrawalDeleted,
    productRemoved,
  }.contains(this);
}

/// One line of the activity log.
class ActivityEvent {
  const ActivityEvent({
    required this.id,
    required this.action,
    required this.actorName,
    required this.isStaff,
    required this.deviceName,
    required this.details,
    required this.occurredAt,
  });

  final int id;
  final ActivityAction action;
  final String actorName;
  final bool isStaff;
  final String deviceName;
  final Map<String, dynamic> details;

  /// When it happened on the phone, which for an offline sale can be well
  /// before the server heard about it.
  final DateTime occurredAt;

  String text(String key) => details[key]?.toString() ?? '';

  double amount(String key) => (details[key] as num?)?.toDouble() ?? 0;

  factory ActivityEvent.fromJson(Map<String, dynamic> json) => ActivityEvent(
    id: (json['id'] as num).toInt(),
    action: ActivityAction.parse(json['action'] as String? ?? ''),
    actorName: json['actor_name'] as String? ?? '',
    isStaff: json['is_staff'] as bool? ?? false,
    deviceName: json['device_name'] as String? ?? '',
    details: (json['details'] as Map?)?.cast<String, dynamic>() ?? const {},
    occurredAt: DateTime.parse(json['occurred_at'] as String).toLocal(),
  );
}

/// A page of the log, newest first.
class ActivityPage {
  const ActivityPage({required this.events, this.nextBefore});

  final List<ActivityEvent> events;

  /// Pass back to fetch older entries. Null on the last page.
  final int? nextBefore;
}
