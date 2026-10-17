import 'package:intl/intl.dart';

class DateFormatters {
  DateFormatters._();

  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _dateTimeFormat = DateFormat('dd MMM yyyy, HH:mm');
  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy');

  static String formatTime(DateTime dateTime) => _timeFormat.format(dateTime);

  static String formatDateTime(DateTime dateTime) =>
      _dateTimeFormat.format(dateTime);

  static String formatDate(DateTime dateTime) => _dateFormat.format(dateTime);

  /// Return readable freshness relative to now
  static String timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.isNegative || difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
