import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final _formatter = NumberFormat.currency(symbol: r'$');

  static String compact(num value) => _formatter.format(value);
}
