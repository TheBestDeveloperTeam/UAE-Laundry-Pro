import 'package:intl/intl.dart';

class Formatters {
  /// Formats double as UAE Dirham currency (e.g. AED 1,234.50)
  static String currency(double amount) {
    final formatter = NumberFormat.currency(symbol: 'AED ', decimalDigits: 2);
    return formatter.format(amount);
  }

  /// Formats Date as standard DD/MM/YYYY
  static String date(DateTime date) {
    final formatter = DateFormat('dd/MM/yyyy');
    return formatter.format(date);
  }
  
  /// Formats Date and Time as DD/MM/YYYY HH:mm
  static String dateTime(DateTime date) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    return formatter.format(date);
  }

  /// Formats double with commas and up to 2 decimal places.
  static String number(double value) {
    final formatter = NumberFormat('#,##0.00');
    return formatter.format(value);
  }
}
