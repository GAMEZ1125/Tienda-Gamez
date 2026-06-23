import 'package:intl/intl.dart';

class Formatters {
  static final currencyFormat = NumberFormat.currency(
    symbol: r'$',
    decimalDigits: 2,
    locale: 'en_US',
  );

  static final dateFormat = DateFormat('dd/MM/yyyy');
  static final dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
  static final timeFormat = DateFormat('HH:mm');

  static String formatCurrency(double value) => currencyFormat.format(value);

  static String formatDate(DateTime? date) {
    if (date == null) return '-';
    return dateFormat.format(date);
  }

  static String formatDateTime(DateTime? date) {
    if (date == null) return '-';
    return dateTimeFormat.format(date);
  }

  static String formatTime(DateTime? date) {
    if (date == null) return '-';
    return timeFormat.format(date);
  }

  static String formatPhone(String? phone) {
    if (phone == null || phone.isEmpty) return '-';
    return phone;
  }
}
