import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_categories.dart';
import '../core/constants/payment_enums.dart';

/// Modelo de un pago / factura / suscripción / vencimiento.
class Payment {
  final String id;

  /// uid del dueño del pago. Los documentos ya viven bajo
  /// `users/{userId}/payments/{id}`, así que este campo es redundante con la
  /// ruta, pero se guarda explícito para futuras consultas (por ejemplo,
  /// `collectionGroup`) sin depender de reconstruir la ruta cada vez.
  final String userId;
  final String name;

  /// Nombre del proveedor/comercio (ej. "Kölbi", "Netflix"), distinto del
  /// nombre que el usuario le puso al pago. Opcional.
  final String? provider;
  final String category;
  final double amount;
  final String currency;
  final DateTime dueDate;
  final bool isRecurring;
  final String frequency;
  final int reminderDays;
  final String status;
  final String? notes;

  /// Número de factura, si el usuario lo ingresó o lo detectó el escáner.
  final String? invoiceNumber;

  /// URL de un documento/factura adjunto (uso futuro: subir el comprobante).
  final String? documentUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDemo;

  const Payment({
    required this.id,
    this.userId = '',
    required this.name,
    this.provider,
    required this.category,
    required this.amount,
    required this.currency,
    required this.dueDate,
    required this.isRecurring,
    required this.frequency,
    required this.reminderDays,
    required this.status,
    this.notes,
    this.invoiceNumber,
    this.documentUrl,
    required this.createdAt,
    required this.updatedAt,
    this.isDemo = false,
  });

  PaymentCategory get categoryEnum => PaymentCategoryX.fromId(category);
  PaymentFrequency get frequencyEnum => PaymentFrequencyX.fromId(frequency);
  PaymentStatus get statusEnum => PaymentStatusX.fromId(status);

  Payment copyWith({
    String? id,
    String? userId,
    String? name,
    String? provider,
    String? category,
    double? amount,
    String? currency,
    DateTime? dueDate,
    bool? isRecurring,
    String? frequency,
    int? reminderDays,
    String? status,
    String? notes,
    String? invoiceNumber,
    String? documentUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDemo,
  }) {
    return Payment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      provider: provider ?? this.provider,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      dueDate: dueDate ?? this.dueDate,
      isRecurring: isRecurring ?? this.isRecurring,
      frequency: frequency ?? this.frequency,
      reminderDays: reminderDays ?? this.reminderDays,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      documentUrl: documentUrl ?? this.documentUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDemo: isDemo ?? this.isDemo,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'provider': provider,
      'category': category,
      'amount': amount,
      'currency': currency,
      'dueDate': Timestamp.fromDate(dueDate),
      'isRecurring': isRecurring,
      'frequency': frequency,
      'reminderDays': reminderDays,
      'status': status,
      'notes': notes,
      'invoiceNumber': invoiceNumber,
      'documentUrl': documentUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isDemo': isDemo,
    };
  }

  /// [fallbackUserId] se usa cuando el documento (uno viejo, guardado antes
  /// de que este campo existiera) no trae `userId` guardado — normalmente se
  /// le pasa el uid derivado de la propia ruta de Firestore (ver
  /// [Payment.fromSnapshot]), así los pagos existentes de usuarios reales
  /// quedan con el uid correcto sin necesitar ninguna migración.
  factory Payment.fromMap(
    String id,
    Map<String, dynamic> map, {
    String? fallbackUserId,
  }) {
    return Payment(
      id: id,
      userId: map['userId'] as String? ?? fallbackUserId ?? '',
      name: map['name'] as String? ?? '',
      provider: map['provider'] as String?,
      category: map['category'] as String? ?? PaymentCategory.otros.id,
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      currency: map['currency'] as String? ?? 'CRC',
      dueDate: (map['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRecurring: map['isRecurring'] as bool? ?? false,
      frequency: map['frequency'] as String? ?? PaymentFrequency.unaVez.id,
      reminderDays: (map['reminderDays'] as num?)?.toInt() ?? 1,
      status: map['status'] as String? ?? PaymentStatus.pending.id,
      notes: map['notes'] as String?,
      invoiceNumber: map['invoiceNumber'] as String?,
      documentUrl: map['documentUrl'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isDemo: map['isDemo'] as bool? ?? false,
    );
  }

  factory Payment.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    // users/{userId}/payments/{paymentId} -> el abuelo del doc es users/{userId}.
    final fallbackUserId = doc.reference.parent.parent?.id;
    return Payment.fromMap(
      doc.id,
      doc.data() ?? const {},
      fallbackUserId: fallbackUserId,
    );
  }
}
