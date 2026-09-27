import 'package:intl/intl.dart';
import 'package:laundrypro_uae/services/global_config_service.dart';

class Formatters {
  /// Formats double as dynamically configured currency
  static String currency(double amount) {
    final symbol = GlobalConfigService().currencySymbol;
    final formatter = NumberFormat.currency(symbol: symbol, decimalDigits: 2);
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
