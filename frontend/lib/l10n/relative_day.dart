import '../core/formatting/day_formatter.dart';
import 'generated/app_localizations.dart';

extension RelativeDay on AppLocalizations {
  /// Reads the way an owner would say it out loud: "Today, 9:40 AM",
  /// "Yesterday, 6:15 PM", then the weekday, then the full date.
  String relativeDay(DateTime value) {
    final local = value.toLocal();
    final now = DateTime.now();
    final daysAgo = DateTime(
      now.year,
      now.month,
      now.day,
    ).difference(DateTime(local.year, local.month, local.day)).inDays;
    final time = DayFormatter.timeOfDay(local);

    return switch (daysAgo) {
      0 => commonDayAtTime(commonToday, time),
      1 => commonDayAtTime(commonYesterday, time),
      < 7 => commonDayAtTime(DayFormatter.weekday(local), time),
      _ => DayFormatter.fullDate(local),
    };
  }
}
