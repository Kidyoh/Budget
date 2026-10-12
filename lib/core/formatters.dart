import 'package:intl/intl.dart';

final _dateFormat = DateFormat.yMMMd();
final _shortDateFormat = DateFormat.MMMd();
final _weekdayDateFormat = DateFormat('EEE, MMM d, y');

String formatDate(DateTime date) => _dateFormat.format(date);

String formatShortDate(DateTime date) => _shortDateFormat.format(date);

String formatLongDate(DateTime date) => _weekdayDateFormat.format(date);

String formatDateRange(DateTime start, DateTime? end) {
  if (end == null || _isSameDay(start, end)) return formatLongDate(start);
  if (start.year == end.year) {
    return '${_shortDateFormat.format(start)} – ${_dateFormat.format(end)}';
  }
  return '${formatDate(start)} – ${formatDate(end)}';
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Whole days from [now]'s date to [date]'s date.
int daysBetween(DateTime now, DateTime date) => DateTime.utc(
  date.year,
  date.month,
  date.day,
).difference(DateTime.utc(now.year, now.month, now.day)).inDays;

/// "Today", "Tomorrow", "In 5 days", "Yesterday", "3 days ago".
String relativeDay(DateTime date, {DateTime? now}) {
  final days = daysBetween(now ?? DateTime.now(), date);
  if (days == 0) return 'Today';
  if (days == 1) return 'Tomorrow';
  if (days == -1) return 'Yesterday';
  if (days > 0) return 'In $days days';
  return '${-days} days ago';
}

String initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.characters(1).toUpperCase();
  return (parts.first.characters(1) + parts.last.characters(1)).toUpperCase();
}

extension on String {
  /// The first [n] code points, so surrogate pairs aren't split.
  String characters(int n) => String.fromCharCodes(runes.take(n));
}
