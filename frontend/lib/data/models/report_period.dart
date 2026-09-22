enum ReportPeriod {
  today('today', 'Today'),
  week('week', 'This week'),
  month('month', 'This month');

  const ReportPeriod(this.wireName, this.label);

  final String wireName;
  final String label;

  /// Start of the period in the device's local time, which is what an owner
  /// means by "today".
  DateTime startOf(DateTime now) => switch (this) {
    ReportPeriod.today => DateTime(now.year, now.month, now.day),
    ReportPeriod.week => DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1)),
    ReportPeriod.month => DateTime(now.year, now.month),
  };
}
