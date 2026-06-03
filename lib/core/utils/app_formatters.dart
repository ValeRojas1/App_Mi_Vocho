import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

class AppFormatters {
  static bool _ready = false;

  static Future<void> ensureInitialized() async {
    if (_ready) return;
    await initializeDateFormatting('es', null);
    await initializeDateFormatting('es_PE', null);
    _ready = true;
  }

  static String currency(double amount) {
    _ensureReady();
    return NumberFormat.currency(
      locale: 'es_PE',
      symbol: 'S/. ',
      decimalDigits: 2,
    ).format(amount);
  }

  static String date(DateTime dt) {
    _ensureReady();
    return DateFormat('d/M/yyyy', 'es').format(dt.toLocal());
  }

  static String dateTime(DateTime dt) {
    _ensureReady();
    return DateFormat('d/M/yyyy HH:mm', 'es').format(dt.toLocal());
  }

  static void _ensureReady() {
    assert(
      _ready,
      'Llama AppFormatters.ensureInitialized() en main() antes de runApp',
    );
  }

  static String orderShortId(String id) =>
      id.length >= 8 ? id.substring(0, 8).toUpperCase() : id.toUpperCase();
}
