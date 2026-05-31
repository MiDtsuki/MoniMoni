import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String compact(num value, String symbol) {
    return NumberFormat.currency(symbol: symbol).format(value);
  }

  static String withSymbol(num value, String symbol) {
    return NumberFormat.currency(symbol: symbol).format(value);
  }
}
