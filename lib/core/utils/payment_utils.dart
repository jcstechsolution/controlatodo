import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/payment_enums.dart';
import '../../models/payment_history_model.dart';
import '../../models/payment_model.dart';
import 'date_formatter.dart';

/// Cálculos y reglas de negocio compartidas relacionadas con pagos.
class PaymentUtils {
  PaymentUtils._();

  /// Calcula la siguiente fecha de vencimiento a partir de la actual,
  /// según la frecuencia de recurrencia.
  static DateTime nextDueDate(DateTime current, PaymentFrequency frequency) {
    switch (frequency) {
      case PaymentFrequency.unaVez:
        return current;
      case PaymentFrequency.semanal:
        return DateTime(current.year, current.month, current.day + 7);
      case PaymentFrequency.mensual:
        return _addMonths(current, 1);
      case PaymentFrequency.trimestral:
        return _addMonths(current, 3);
      case PaymentFrequency.semestral:
        return _addMonths(current, 6);
      case PaymentFrequency.anual:
        return _addMonths(current, 12);
    }
  }

  static DateTime _addMonths(DateTime date, int months) {
    final totalMonths = date.month - 1 + months;
    final year = date.year + (totalMonths ~/ 12);
    final month = (totalMonths % 12) + 1;
    final lastDayOfNewMonth = DateTime(year, month + 1, 0).day;
    final day = date.day > lastDayOfNewMonth ? lastDayOfNewMonth : date.day;
    return DateTime(year, month, day);
  }

  /// Cuántas veces al año ocurre un pago con esta frecuencia. Se usa para
  /// normalizar montos recurrentes a "por mes"/"por año" sin importar cada
  /// cuánto se cobran realmente.
  static int occurrencesPerYear(PaymentFrequency frequency) {
    switch (frequency) {
      case PaymentFrequency.unaVez:
        return 0;
      case PaymentFrequency.semanal:
        return 52;
      case PaymentFrequency.mensual:
        return 12;
      case PaymentFrequency.trimestral:
        return 4;
      case PaymentFrequency.semestral:
        return 2;
      case PaymentFrequency.anual:
        return 1;
    }
  }

  /// Costo anualizado de un pago recurrente (monto × veces al año). Para un
  /// pago no recurrente devuelve 0 (no aplica el concepto de "por año").
  static double annualEquivalent(Payment payment) {
    if (!payment.isRecurring) return 0;
    return payment.amount * occurrencesPerYear(payment.frequencyEnum);
  }

  /// Costo mensualizado de un pago recurrente (costo anualizado ÷ 12). Ej.:
  /// una obligación mensual de ₡5.500 -> 5500/mes, ≈ 66000/año.
  static double monthlyEquivalent(Payment payment) {
    return annualEquivalent(payment) / 12;
  }

  /// Suma el costo mensualizado de una lista de pagos recurrentes. Se asume
  /// que [payments] ya viene filtrada por una sola moneda (nunca se deben
  /// sumar montos de monedas distintas sin una tasa de cambio real).
  static double recurringMonthlyTotal(List<Payment> payments) {
    return payments
        .where((p) => p.isRecurring)
        .fold<double>(0, (sum, p) => sum + monthlyEquivalent(p));
  }

  /// Igual que [recurringMonthlyTotal] pero anualizado.
  static double recurringAnnualTotal(List<Payment> payments) {
    return payments
        .where((p) => p.isRecurring)
        .fold<double>(0, (sum, p) => sum + annualEquivalent(p));
  }

  /// Suma cuánto se pagó realmente (desde el historial, no desde el estado
  /// actual del Payment) en un período dado, filtrado por moneda. Si [month]
  /// es nulo, suma todo el año; si se indica, suma solo ese mes.
  ///
  /// Esto es lo que hace que las estadísticas de "pagado" sean correctas
  /// para pagos recurrentes: una vez que un pago se marca como pagado, su
  /// `dueDate` avanza y su `status` vuelve a pendiente, así que el único
  /// registro confiable de "esto se pagó, y cuándo" es el historial.
  static double paidTotal(
    List<PaymentHistoryEntry> history, {
    required String currency,
    required int year,
    int? month,
  }) {
    return history
        .where((h) =>
            h.currency == currency &&
            h.paidAt.year == year &&
            (month == null || h.paidAt.month == month))
        .fold<double>(0, (sum, h) => sum + h.amount);
  }

  /// Determina si un pago pendiente debe considerarse vencido "hoy".
  static bool isOverdue(DateTime dueDate, PaymentStatus status) {
    if (status != PaymentStatus.pending) return false;
    return DateFormatter.daysUntil(dueDate) < 0;
  }

  /// Color asociado a la urgencia de un vencimiento.
  static Color urgencyColor(DateTime dueDate, PaymentStatus status) {
    if (status == PaymentStatus.paid) return AppColors.success;
    if (isOverdue(dueDate, status) || status == PaymentStatus.overdue) {
      return AppColors.overdue;
    }
    if (DateFormatter.daysUntil(dueDate) <= 1) return AppColors.dueSoon;
    return AppColors.dueLater;
  }

  /// Estado "efectivo" de un pago: si está pendiente y ya pasó su fecha de
  /// vencimiento se considera vencido, aunque el campo almacenado siga
  /// siendo "pending" (no dependemos de un job de backend para esto).
  static PaymentStatus effectiveStatus(DateTime dueDate, PaymentStatus status) {
    if (status == PaymentStatus.pending && isOverdue(dueDate, status)) {
      return PaymentStatus.overdue;
    }
    return status;
  }

  /// Emoji indicador de urgencia, usado en tarjetas de "Próximos vencimientos".
  static String urgencyEmoji(DateTime dueDate, PaymentStatus status) {
    if (status == PaymentStatus.paid) return '🟢';
    if (isOverdue(dueDate, status) || status == PaymentStatus.overdue) {
      return '🔴';
    }
    if (DateFormatter.daysUntil(dueDate) <= 1) return '🟠';
    return '🟢';
  }
}
