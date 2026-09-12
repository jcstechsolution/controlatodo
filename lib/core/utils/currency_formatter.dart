import 'package:intl/intl.dart';

import '../constants/payment_enums.dart';

/// Utilidad para formatear montos según la moneda seleccionada.
///
/// CRC -> ₡25.000  (sin decimales, separador de miles con punto)
/// USD -> $25.00   (con 2 decimales, separador de miles con coma)
class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _crcFormat = NumberFormat.currency(
    locale: 'es_CR',
    symbol: '₡',
    decimalDigits: 0,
  );

  static final NumberFormat _usdFormat = NumberFormat.currency(
    locale: 'en_US',
    symbol: '\$',
    decimalDigits: 2,
  );

  static String format(double amount, String currencyCode) {
    final currency = AppCurrencyX.fromCode(currencyCode);
    switch (currency) {
      case AppCurrency.crc:
        return _crcFormat.format(amount);
      case AppCurrency.usd:
        return _usdFormat.format(amount);
    }
  }

  /// Formatea usando el enum directamente.
  static String formatCurrency(double amount, AppCurrency currency) {
    return format(amount, currency.code);
  }

  static String symbolFor(String currencyCode) {
    return AppCurrencyX.fromCode(currencyCode).symbol;
  }
}
