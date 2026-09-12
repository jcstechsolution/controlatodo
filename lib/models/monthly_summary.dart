import 'payment_model.dart';

/// Resumen de "Este mes" mostrado en el Dashboard, calculado únicamente
/// sobre los pagos que están en la moneda principal del usuario (sumar
/// montos de monedas distintas sin una tasa de cambio real produciría
/// totales incorrectos).
class MonthlySummary {
  final double total;
  final double paid;
  final double pending;
  final Payment? nextDue;
  final String currency;

  const MonthlySummary({
    required this.total,
    required this.paid,
    required this.pending,
    required this.nextDue,
    required this.currency,
  });

  static const empty = MonthlySummary(
    total: 0,
    paid: 0,
    pending: 0,
    nextDue: null,
    currency: 'CRC',
  );
}
