import 'package:intl/intl.dart';

abstract final class DayFormatter {
  // Built per call rather than cached: the pattern's month and weekday names
  // follow `Intl.defaultLocale`, which changes when the owner switches
  // language.
  static String dayMonth(DateTime value) =>
      DateFormat('d MMM').format(value.toLocal());
  static String weekday(DateTime value) =>
      DateFormat('EEE').format(value.toLocal());
  static String fullDate(DateTime value) =>
      DateFormat('d MMMM y').format(value.toLocal());
  static String timeOfDay(DateTime value) =>
      DateFormat('h:mm a').format(value.toLocal());
}
