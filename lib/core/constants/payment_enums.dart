/// Frecuencia de un pago recurrente.
enum PaymentFrequency {
  unaVez,
  semanal,
  mensual,
  trimestral,
  semestral,
  anual,
}

extension PaymentFrequencyX on PaymentFrequency {
  String get id => name;

  String get label {
    switch (this) {
      case PaymentFrequency.unaVez:
        return 'Una vez';
      case PaymentFrequency.semanal:
        return 'Semanal';
      case PaymentFrequency.mensual:
        return 'Mensual';
      case PaymentFrequency.trimestral:
        return 'Trimestral';
      case PaymentFrequency.semestral:
        return 'Semestral';
      case PaymentFrequency.anual:
        return 'Anual';
    }
  }

  static PaymentFrequency fromId(String? id) {
    return PaymentFrequency.values.firstWhere(
      (f) => f.id == id,
      orElse: () => PaymentFrequency.unaVez,
    );
  }
}

/// Estado actual de un pago.
enum PaymentStatus {
  pending,
  paid,
  overdue,
}

extension PaymentStatusX on PaymentStatus {
  String get id => name;

  String get label {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pendiente';
      case PaymentStatus.paid:
        return 'Pagado';
      case PaymentStatus.overdue:
        return 'Vencido';
    }
  }

  static PaymentStatus fromId(String? id) {
    return PaymentStatus.values.firstWhere(
      (s) => s.id == id,
      orElse: () => PaymentStatus.pending,
    );
  }
}

/// Días de anticipación para el recordatorio.
enum ReminderOption {
  sameDay,
  oneDayBefore,
  threeDaysBefore,
  sevenDaysBefore,
}

extension ReminderOptionX on ReminderOption {
  int get days {
    switch (this) {
      case ReminderOption.sameDay:
        return 0;
      case ReminderOption.oneDayBefore:
        return 1;
      case ReminderOption.threeDaysBefore:
        return 3;
      case ReminderOption.sevenDaysBefore:
        return 7;
    }
  }

  String get label {
    switch (this) {
      case ReminderOption.sameDay:
        return 'El mismo día';
      case ReminderOption.oneDayBefore:
        return '1 día antes';
      case ReminderOption.threeDaysBefore:
        return '3 días antes';
      case ReminderOption.sevenDaysBefore:
        return '7 días antes';
    }
  }

  static ReminderOption fromDays(int days) {
    return ReminderOption.values.firstWhere(
      (r) => r.days == days,
      orElse: () => ReminderOption.oneDayBefore,
    );
  }
}

/// Monedas soportadas.
enum AppCurrency {
  crc,
  usd,
}

extension AppCurrencyX on AppCurrency {
  String get code => name.toUpperCase();

  String get symbol {
    switch (this) {
      case AppCurrency.crc:
        return '₡';
      case AppCurrency.usd:
        return '\$';
    }
  }

  static AppCurrency fromCode(String? code) {
    return AppCurrency.values.firstWhere(
      (c) => c.code == (code ?? 'CRC').toUpperCase(),
      orElse: () => AppCurrency.crc,
    );
  }
}
