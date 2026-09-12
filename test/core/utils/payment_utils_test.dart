import 'package:controlatodo/core/constants/payment_enums.dart';
import 'package:controlatodo/core/utils/payment_utils.dart';
import 'package:controlatodo/models/payment_history_model.dart';
import 'package:controlatodo/models/payment_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// Crea un [Payment] de prueba con valores por defecto razonables; solo hay
/// que sobreescribir lo que le importa a cada test.
Payment _payment({
  String id = 'p1',
  double amount = 1000,
  String currency = 'CRC',
  DateTime? dueDate,
  bool isRecurring = false,
  PaymentFrequency frequency = PaymentFrequency.unaVez,
  PaymentStatus status = PaymentStatus.pending,
}) {
  final now = DateTime(2026, 1, 15);
  return Payment(
    id: id,
    name: 'Pago de prueba',
    category: 'servicios',
    amount: amount,
    currency: currency,
    dueDate: dueDate ?? now,
    isRecurring: isRecurring,
    frequency: frequency.id,
    reminderDays: 1,
    status: status.id,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('nextDueDate', () {
    test('unaVez no avanza la fecha', () {
      final date = DateTime(2026, 3, 10);
      expect(PaymentUtils.nextDueDate(date, PaymentFrequency.unaVez), date);
    });

    test('semanal avanza 7 días', () {
      final date = DateTime(2026, 3, 10);
      expect(
        PaymentUtils.nextDueDate(date, PaymentFrequency.semanal),
        DateTime(2026, 3, 17),
      );
    });

    test('mensual avanza 1 mes', () {
      final date = DateTime(2026, 3, 10);
      expect(
        PaymentUtils.nextDueDate(date, PaymentFrequency.mensual),
        DateTime(2026, 4, 10),
      );
    });

    test('trimestral avanza 3 meses', () {
      final date = DateTime(2026, 1, 5);
      expect(
        PaymentUtils.nextDueDate(date, PaymentFrequency.trimestral),
        DateTime(2026, 4, 5),
      );
    });

    test('semestral avanza 6 meses', () {
      final date = DateTime(2026, 1, 5);
      expect(
        PaymentUtils.nextDueDate(date, PaymentFrequency.semestral),
        DateTime(2026, 7, 5),
      );
    });

    test('anual avanza 12 meses', () {
      final date = DateTime(2026, 1, 5);
      expect(
        PaymentUtils.nextDueDate(date, PaymentFrequency.anual),
        DateTime(2027, 1, 5),
      );
    });

    test('mensual hace clamp al último día del mes destino', () {
      // 31 de enero + 1 mes -> 2026 no es bisiesto, así que febrero llega
      // solo hasta el 28.
      final date = DateTime(2026, 1, 31);
      expect(
        PaymentUtils.nextDueDate(date, PaymentFrequency.mensual),
        DateTime(2026, 2, 28),
      );
    });

    test('mensual hace clamp en año bisiesto', () {
      final date = DateTime(2028, 1, 31);
      expect(
        PaymentUtils.nextDueDate(date, PaymentFrequency.mensual),
        DateTime(2028, 2, 29),
      );
    });
  });

  group('isOverdue / effectiveStatus', () {
    test('un pago pendiente con fecha pasada está vencido', () {
      final past = DateTime.now().subtract(const Duration(days: 3));
      expect(PaymentUtils.isOverdue(past, PaymentStatus.pending), isTrue);
      expect(
        PaymentUtils.effectiveStatus(past, PaymentStatus.pending),
        PaymentStatus.overdue,
      );
    });

    test('un pago pendiente con fecha futura no está vencido', () {
      final future = DateTime.now().add(const Duration(days: 3));
      expect(PaymentUtils.isOverdue(future, PaymentStatus.pending), isFalse);
      expect(
        PaymentUtils.effectiveStatus(future, PaymentStatus.pending),
        PaymentStatus.pending,
      );
    });

    test('un pago ya pagado nunca se considera vencido', () {
      final past = DateTime.now().subtract(const Duration(days: 30));
      expect(PaymentUtils.isOverdue(past, PaymentStatus.paid), isFalse);
      expect(
        PaymentUtils.effectiveStatus(past, PaymentStatus.paid),
        PaymentStatus.paid,
      );
    });
  });

  group('costo mensualizado / anualizado', () {
    test('mensual: monto se mantiene igual por mes, ×12 al año', () {
      final payment = _payment(
        amount: 5500,
        isRecurring: true,
        frequency: PaymentFrequency.mensual,
      );
      expect(PaymentUtils.monthlyEquivalent(payment), 5500);
      expect(PaymentUtils.annualEquivalent(payment), 66000);
    });

    test('anual: se muestra completo por año, mensualizado ÷12', () {
      final payment = _payment(
        amount: 60000,
        isRecurring: true,
        frequency: PaymentFrequency.anual,
      );
      expect(PaymentUtils.annualEquivalent(payment), 60000);
      expect(PaymentUtils.monthlyEquivalent(payment), 5000);
    });

    test('semanal: se anualiza ×52', () {
      final payment = _payment(
        amount: 1000,
        isRecurring: true,
        frequency: PaymentFrequency.semanal,
      );
      expect(PaymentUtils.annualEquivalent(payment), 52000);
    });

    test('trimestral: se anualiza ×4', () {
      final payment = _payment(
        amount: 25000,
        isRecurring: true,
        frequency: PaymentFrequency.trimestral,
      );
      expect(PaymentUtils.annualEquivalent(payment), 100000);
    });

    test('un pago no recurrente no aporta costo anualizado', () {
      final payment = _payment(amount: 10000, isRecurring: false);
      expect(PaymentUtils.annualEquivalent(payment), 0);
      expect(PaymentUtils.monthlyEquivalent(payment), 0);
    });

    test('recurringMonthlyTotal/AnnualTotal suman solo los recurrentes', () {
      final payments = [
        _payment(
          id: 'a',
          amount: 5500,
          isRecurring: true,
          frequency: PaymentFrequency.mensual,
        ),
        _payment(
          id: 'b',
          amount: 60000,
          isRecurring: true,
          frequency: PaymentFrequency.anual,
        ),
        // No recurrente: no debe contar.
        _payment(id: 'c', amount: 999999, isRecurring: false),
      ];
      // 5500/mes + (60000/12)/mes = 5500 + 5000 = 10500/mes
      expect(PaymentUtils.recurringMonthlyTotal(payments), 10500);
      // 66000/año + 60000/año = 126000/año
      expect(PaymentUtils.recurringAnnualTotal(payments), 126000);
    });
  });

  group('paidTotal', () {
    PaymentHistoryEntry entry({
      required double amount,
      required String currency,
      required DateTime paidAt,
    }) {
      return PaymentHistoryEntry(
        id: 'h',
        amount: amount,
        currency: currency,
        dueDate: paidAt,
        paidAt: paidAt,
        status: PaymentStatus.paid.id,
      );
    }

    test('suma solo la moneda pedida, nunca mezcla CRC y USD', () {
      final history = [
        entry(amount: 25000, currency: 'CRC', paidAt: DateTime(2026, 3, 5)),
        entry(amount: 12, currency: 'USD', paidAt: DateTime(2026, 3, 6)),
        entry(amount: 18500, currency: 'CRC', paidAt: DateTime(2026, 3, 10)),
      ];

      final totalCrc = PaymentUtils.paidTotal(
        history,
        currency: 'CRC',
        year: 2026,
        month: 3,
      );
      final totalUsd = PaymentUtils.paidTotal(
        history,
        currency: 'USD',
        year: 2026,
        month: 3,
      );

      expect(totalCrc, 43500);
      expect(totalUsd, 12);
    });

    test('respeta el filtro de mes cuando se indica', () {
      final history = [
        entry(amount: 100, currency: 'CRC', paidAt: DateTime(2026, 1, 5)),
        entry(amount: 200, currency: 'CRC', paidAt: DateTime(2026, 2, 5)),
      ];

      expect(
        PaymentUtils.paidTotal(history, currency: 'CRC', year: 2026, month: 1),
        100,
      );
      expect(
        PaymentUtils.paidTotal(history, currency: 'CRC', year: 2026),
        300,
      );
    });
  });
}
