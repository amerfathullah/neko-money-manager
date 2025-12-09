import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(double amount, {String symbol = '\$'}) {
    final formatter = NumberFormat.currency(symbol: symbol, decimalDigits: 2);
    // Add space between symbol and number if symbol is present
    if (symbol.isEmpty) {
      return formatter.format(amount);
    }
    // NumberFormat doesn't easily support custom spacing, so we format without symbol and add it manually
    final formatterNoSymbol = NumberFormat.currency(
      symbol: '',
      decimalDigits: 2,
    );
    return '$symbol ${formatterNoSymbol.format(amount)}';
  }
}
