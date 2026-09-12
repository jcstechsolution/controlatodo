import 'package:cloud_firestore/cloud_firestore.dart';

/// Registro histórico generado cada vez que un pago se marca como pagado.
///
/// Guarda una "foto" del pago en el momento de pagarlo (nombre, categoría,
/// proveedor, fecha de vencimiento de ese ciclo) para que las estadísticas
/// históricas no dependan de cómo esté el `Payment` activo hoy: un pago
/// recurrente cambia de `dueDate`/`status` en cuanto se paga, pero su
/// historial no debe cambiar nunca.
class PaymentHistoryEntry {
  final String id;

  /// id del `Payment` al que pertenece este registro. Redundante con la
  /// ruta (`.../payments/{paymentId}/history/{id}`), pero se guarda
  /// explícito para poder usarlo en una consulta `collectionGroup`.
  final String paymentId;

  /// uid del dueño, también redundante con la ruta pero necesario para
  /// filtrar con `collectionGroup(...).where('userId', isEqualTo: uid)` y
  /// así sumar el historial de todos los pagos de un usuario en una sola
  /// consulta.
  final String userId;

  /// Nombre del pago en el momento de pagarlo.
  final String? name;

  /// Categoría del pago en el momento de pagarlo.
  final String? category;

  /// Proveedor del pago en el momento de pagarlo.
  final String? provider;
  final double amount;
  final String currency;

  /// Fecha de vencimiento del ciclo que se pagó (antes de avanzar al
  /// siguiente, si el pago es recurrente).
  final DateTime dueDate;
  final DateTime paidAt;
  final String status;

  const PaymentHistoryEntry({
    required this.id,
    this.paymentId = '',
    this.userId = '',
    this.name,
    this.category,
    this.provider,
    required this.amount,
    required this.currency,
    required this.dueDate,
    required this.paidAt,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'paymentId': paymentId,
      'userId': userId,
      'name': name,
      'category': category,
      'provider': provider,
      'amount': amount,
      'currency': currency,
      'dueDate': Timestamp.fromDate(dueDate),
      'paidAt': Timestamp.fromDate(paidAt),
      'status': status,
    };
  }

  /// [fallbackPaymentId]/[fallbackUserId] cubren registros guardados antes
  /// de que estos campos existieran (ver [PaymentHistoryEntry.fromSnapshot]).
  factory PaymentHistoryEntry.fromMap(
    String id,
    Map<String, dynamic> map, {
    String? fallbackPaymentId,
    String? fallbackUserId,
  }) {
    final paidAt = (map['paidAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    return PaymentHistoryEntry(
      id: id,
      paymentId: map['paymentId'] as String? ?? fallbackPaymentId ?? '',
      userId: map['userId'] as String? ?? fallbackUserId ?? '',
      name: map['name'] as String?,
      category: map['category'] as String?,
      provider: map['provider'] as String?,
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      currency: map['currency'] as String? ?? 'CRC',
      // Si el registro es viejo y no tiene `dueDate` propia, se usa `paidAt`
      // como mejor estimación (más útil que dejarla en `DateTime.now()`).
      dueDate: (map['dueDate'] as Timestamp?)?.toDate() ?? paidAt,
      paidAt: paidAt,
      status: map['status'] as String? ?? 'paid',
    );
  }

  factory PaymentHistoryEntry.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    // users/{userId}/payments/{paymentId}/history/{id}
    // -> el padre es el payment, el abuelo del padre es users/{userId}.
    final paymentRef = doc.reference.parent.parent;
    return PaymentHistoryEntry.fromMap(
      doc.id,
      doc.data() ?? const {},
      fallbackPaymentId: paymentRef?.id,
      fallbackUserId: paymentRef?.parent.parent?.id,
    );
  }
}
