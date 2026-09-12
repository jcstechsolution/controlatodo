import 'package:cloud_firestore/cloud_firestore.dart';

/// Registro histórico generado cada vez que un pago se marca como pagado.
class PaymentHistoryEntry {
  final String id;
  final double amount;
  final String currency;
  final DateTime paidAt;
  final String status;

  const PaymentHistoryEntry({
    required this.id,
    required this.amount,
    required this.currency,
    required this.paidAt,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'currency': currency,
      'paidAt': Timestamp.fromDate(paidAt),
      'status': status,
    };
  }

  factory PaymentHistoryEntry.fromMap(String id, Map<String, dynamic> map) {
    return PaymentHistoryEntry(
      id: id,
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      currency: map['currency'] as String? ?? 'CRC',
      paidAt: (map['paidAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] as String? ?? 'paid',
    );
  }

  factory PaymentHistoryEntry.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return PaymentHistoryEntry.fromMap(doc.id, doc.data() ?? const {});
  }
}
