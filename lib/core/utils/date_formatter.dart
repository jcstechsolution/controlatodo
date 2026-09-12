import 'package:intl/intl.dart';

/// Utilidades para formatear fechas y calcular urgencia de vencimientos.
class DateFormatter {
  DateFormatter._();

  static final DateFormat _shortDate = DateFormat('dd/MM/yyyy');
  static final DateFormat _longDate = DateFormat("d 'de' MMMM 'de' yyyy", 'es');
  static final DateFormat _dayMonth = DateFormat('dd/MM');

  static String toShort(DateTime date) => _shortDate.format(date);

  static String toLong(DateTime date) {
    try {
      return _longDate.format(date);
    } catch (_) {
      return _shortDate.format(date);
    }
  }

  static String toDayMonth(DateTime date) => _dayMonth.format(date);

  static DateTime stripTime(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Días de diferencia entre hoy y [date] (positivo = futuro, negativo = pasado).
  static int daysUntil(DateTime date) {
    final today = stripTime(DateTime.now());
    final target = stripTime(date);
    return target.difference(today).inDays;
  }

  /// Etiqueta relativa: HOY, MAÑANA, EN X DÍAS, VENCIDO HACE X DÍAS.
  static String relativeLabel(DateTime date) {
    final diff = daysUntil(date);
    if (diff == 0) return 'HOY';
    if (diff == 1) return 'MAÑANA';
    if (diff > 1) return 'EN $diff DÍAS';
    if (diff == -1) return 'VENCIDO HACE 1 DÍA';
    return 'VENCIDO HACE ${diff.abs()} DÍAS';
  }
}
