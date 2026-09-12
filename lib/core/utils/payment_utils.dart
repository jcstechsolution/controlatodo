import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/payment_enums.dart';

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

  /// Determina si un pago pendiente debe considerarse vencido "hoy".
  static bool isOverdue(DateTime dueDate, PaymentStatus status) {
    if (status != PaymentStatus.pending) return false;
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final dueOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return dueOnly.isBefore(todayOnly);
  }

  /// Color asociado a la urgencia de un vencimiento.
  static Color urgencyColor(DateTime dueDate, PaymentStatus status) {
    if (status == PaymentStatus.paid) return AppColors.success;
    if (isOverdue(dueDate, status) || status == PaymentStatus.overdue) {
      return AppColors.overdue;
    }
    final diff = DateTime(dueDate.year, dueDate.month, dueDate.day)
        .difference(DateTime.now())
        .inDays;
    if (diff <= 1) return AppColors.dueSoon;
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
    final diff = DateTime(dueDate.year, dueDate.month, dueDate.day)
        .difference(DateTime.now())
        .inDays;
    if (diff <= 1) return '🟠';
    return '🟢';
  }
}
