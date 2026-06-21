import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  static String format(int amount) => _formatter.format(amount);

  static int parse(String text) {
    final cleaned = text
        .replaceAll('Rp', '')
        .replaceAll('.', '')
        .replaceAll(',', '')
        .trim();
    return int.tryParse(cleaned) ?? 0;
  }
}
