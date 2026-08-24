import 'package:intl/intl.dart';

class AppFormatters {
  /// Formats integer money into Algerian Dinar format: "2 500 DA"
  static String formatCurrency(num? amount) {
    if (amount == null) return '0 DA';
    final formatter = NumberFormat('#,###', 'fr_FR');
    final formatted = formatter.format(amount).replaceAll('\u00A0', ' ');
    return '$formatted DA';
  }

  /// Formats quantities (e.g. 2.5 kg or 20 pcs)
  static String formatQuantity(num? quantity, String? unit) {
    if (quantity == null) return '';
    final qtyStr = quantity % 1 == 0 ? quantity.toInt().toString() : quantity.toString();
    if (unit == null || unit.isEmpty) return qtyStr;
    return '$qtyStr $unit';
  }

  /// Formats a DateTime to a friendly readable date (e.g. "24 Aug 2026")
  static String formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('dd MMM yyyy').format(date);
  }

  /// Formats a DateTime to a date & time (e.g. "24 Aug 2026, 14:30")
  static String formatDateTime(DateTime? date) {
    if (date == null) return '';
    return DateFormat('dd MMM yyyy, HH:mm').format(date);
  }
}
