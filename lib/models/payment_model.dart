import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_categories.dart';
import '../core/constants/payment_enums.dart';

/// Modelo de un pago / factura / suscripción / vencimiento.
class Payment {
  final String id;
  final String name;
  final String category;
  final double amount;
  final String currency;
  final DateTime dueDate;
  final bool isRecurring;
  final String frequency;
  final int reminderDays;
  final String status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDemo;

  const Payment({
    required this.id,
    required this.name,
    required this.category,
    required this.amount,
    required this.currency,
    required this.dueDate,
    required this.isRecurring,
    required this.frequency,
    required this.reminderDays,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.isDemo = false,
  });

  PaymentCategory get categoryEnum => PaymentCategoryX.fromId(category);
  PaymentFrequency get frequencyEnum => PaymentFrequencyX.fromId(frequency);
  PaymentStatus get statusEnum => PaymentStatusX.fromId(status);

  Payment copyWith({
    String? id,
    String? name,
    String? category,
    double? amount,
    String? currency,
    DateTime? dueDate,
    bool? isRecurring,
    String? frequency,
    int? reminderDays,
    String? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDemo,
  }) {
    return Payment(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      dueDate: dueDate ?? this.dueDate,
      isRecurring: isRecurring ?? this.isRecurring,
      frequency: frequency ?? this.frequency,
      reminderDays: reminderDays ?? this.reminderDays,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDemo: isDemo ?? this.isDemo,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'amount': amount,
      'currency': currency,
      'dueDate': Timestamp.fromDate(dueDate),
      'isRecurring': isRecurring,
      'frequency': frequency,
      'reminderDays': reminderDays,
      'status': status,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isDemo': isDemo,
    };
  }

  factory Payment.fromMap(String id, Map<String, dynamic> map) {
    return Payment(
      id: id,
      name: map['name'] as String? ?? '',
      category: map['category'] as String? ?? PaymentCategory.otros.id,
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      currency: map['currency'] as String? ?? 'CRC',
      dueDate: (map['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRecurring: map['isRecurring'] as bool? ?? false,
      frequency: map['frequency'] as String? ?? PaymentFrequency.unaVez.id,
      reminderDays: (map['reminderDays'] as num?)?.toInt() ?? 1,
      status: map['status'] as String? ?? PaymentStatus.pending.id,
      notes: map['notes'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isDemo: map['isDemo'] as bool? ?? false,
    );
  }

  factory Payment.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    return Payment.fromMap(doc.id, doc.data() ?? const {});
  }
}
