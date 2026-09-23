import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _inrFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static String format(num amount) {
    return _inrFormat.format(amount);
  }

  static String formatWithPerNight(num amount) {
    return '${_inrFormat.format(amount)}/night';
  }
}
