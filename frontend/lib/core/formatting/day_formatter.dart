import 'package:intl/intl.dart';

abstract final class DayFormatter {
  static final DateFormat _dayMonth = DateFormat('d MMM');
  static final DateFormat _weekday = DateFormat('EEE');
  static final DateFormat _fullDate = DateFormat('d MMMM y');
  static final DateFormat _timeOfDay = DateFormat('h:mm a');

  static String dayMonth(DateTime value) => _dayMonth.format(value.toLocal());
  static String weekday(DateTime value) => _weekday.format(value.toLocal());
  static String fullDate(DateTime value) => _fullDate.format(value.toLocal());
  static String timeOfDay(DateTime value) => _timeOfDay.format(value.toLocal());

  /// Reads the way an owner would say it out loud.
  static String relative(DateTime value) {
    final local = value.toLocal();
    final now = DateTime.now();
    final difference = DateTime(
      now.year,
      now.month,
      now.day,
    ).difference(DateTime(local.year, local.month, local.day)).inDays;

    return switch (difference) {
      0 => 'Today, ${timeOfDay(local)}',
      1 => 'Yesterday, ${timeOfDay(local)}',
      < 7 => '${weekday(local)}, ${timeOfDay(local)}',
      _ => fullDate(local),
    };
  }
}
