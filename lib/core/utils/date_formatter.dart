import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy hh:mm a');
  static final DateFormat _timeFormat = DateFormat('hh:mm a');

  static final DateFormat _shortDateFormat = DateFormat('dd MMM');

  static String formatDate(DateTime date) => _dateFormat.format(date);
  static String formatShort(DateTime date) => _shortDateFormat.format(date);
  static String formatDateTime(DateTime dateTime) => _dateTimeFormat.format(dateTime);
  static String formatTime(DateTime time) => _timeFormat.format(time);

  static DateTime? tryParse(String formattedString) {
    try {
      return _dateFormat.parse(formattedString);
    } catch (_) {
      return null;
    }
  }
}
