import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_paths.dart';
import '../core/constants/payment_enums.dart';
import '../core/utils/app_exception.dart';
import '../core/utils/payment_utils.dart';
import '../models/payment_history_model.dart';
import '../models/payment_model.dart';

/// Encapsula todo el acceso a users/{userId}/payments y su subcolección
/// history dentro de Cloud Firestore.
class PaymentRepository {
  final FirebaseFirestore _firestore;

  PaymentRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _paymentsCollection(String uid) {
    return _firestore
        .collection(FirestorePaths.users)
        .doc(uid)
        .collection(FirestorePaths.payments);
  }

  CollectionReference<Map<String, dynamic>> _historyCollection(
    String uid,
    String paymentId,
  ) {
    return _paymentsCollection(uid).doc(paymentId).collection(
          FirestorePaths.history,
        );
  }

  /// Escucha en tiempo real todos los pagos del usuario, ordenados por
  /// fecha de vencimiento ascendente.
  Stream<List<Payment>> watchPayments(String uid) {
    return _paymentsCollection(uid)
        .orderBy('dueDate', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map(Payment.fromSnapshot).toList());
  }

  Stream<List<PaymentHistoryEntry>> watchHistory(String uid, String paymentId) {
    return _historyCollection(uid, paymentId)
        .orderBy('paidAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(PaymentHistoryEntry.fromSnapshot).toList());
  }

  /// Escucha, en una sola consulta, el historial de TODOS los pagos del
  /// usuario (usando una consulta `collectionGroup` sobre la subcolección
  /// `history` de cada pago). Necesario para que las estadísticas de
  /// "pagado" reflejen la realidad histórica y no solo el estado actual de
  /// cada `Payment` (que cambia en cuanto un pago recurrente se paga de
  /// nuevo). Requiere un índice de Firestore para el campo `userId` con
  /// alcance "Collection group" (ver firestore.indexes.json).
  Stream<List<PaymentHistoryEntry>> watchAllHistory(String uid) {
    return _firestore
        .collectionGroup(FirestorePaths.history)
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snap) => snap.docs.map(PaymentHistoryEntry.fromSnapshot).toList());
  }

  Future<Payment> createPayment({
    required String uid,
    required String name,
    String? provider,
    required String category,
    required double amount,
    required String currency,
    required DateTime dueDate,
    required bool isRecurring,
    required String frequency,
    required int reminderDays,
    String? notes,
    String? invoiceNumber,
    String? documentUrl,
  }) async {
    try {
      final docRef = _paymentsCollection(uid).doc();
      final now = DateTime.now();
      final payment = Payment(
        id: docRef.id,
        userId: uid,
        name: name.trim(),
        provider: (provider == null || provider.trim().isEmpty)
            ? null
            : provider.trim(),
        category: category,
        amount: amount,
        currency: currency,
        dueDate: dueDate,
        isRecurring: isRecurring,
        frequency: frequency,
        reminderDays: reminderDays,
        status: PaymentStatus.pending.id,
        notes: (notes == null || notes.trim().isEmpty) ? null : notes.trim(),
        invoiceNumber: (invoiceNumber == null || invoiceNumber.trim().isEmpty)
            ? null
            : invoiceNumber.trim(),
        documentUrl: documentUrl,
        createdAt: now,
        updatedAt: now,
      );
      await docRef.set(payment.toMap());
      return payment;
    } catch (_) {
      throw AppException.generic;
    }
  }

  Future<void> updatePayment(String uid, Payment payment) async {
    try {
      final updated = payment.copyWith(updatedAt: DateTime.now());
      await _paymentsCollection(uid).doc(payment.id).update(updated.toMap());
    } catch (_) {
      throw AppException.generic;
    }
  }

  Future<void> deletePayment(String uid, String paymentId) async {
    try {
      final historyDocs = await _historyCollection(uid, paymentId).get();
      final batch = _firestore.batch();
      for (final doc in historyDocs.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(_paymentsCollection(uid).doc(paymentId));
      await batch.commit();
    } catch (_) {
      throw AppException.generic;
    }
  }

  /// Marca un pago como pagado: registra el historial y, si el pago es
  /// recurrente, calcula automáticamente la siguiente fecha de vencimiento
  /// y regresa el estado a "pendiente"; si no es recurrente, lo deja como
  /// "pagado".
  Future<void> markAsPaid(String uid, Payment payment) async {
    try {
      final now = DateTime.now();
      final historyRef = _historyCollection(uid, payment.id).doc();
      final historyEntry = PaymentHistoryEntry(
        id: historyRef.id,
        paymentId: payment.id,
        userId: uid,
        name: payment.name,
        category: payment.category,
        provider: payment.provider,
        amount: payment.amount,
        currency: payment.currency,
        // Fecha de vencimiento del ciclo que se está pagando, ANTES de
        // avanzarla (si el pago es recurrente) — así el historial siempre
        // refleja qué ciclo se pagó, no el próximo.
        dueDate: payment.dueDate,
        paidAt: now,
        status: PaymentStatus.paid.id,
      );

      final batch = _firestore.batch();
      batch.set(historyRef, historyEntry.toMap());

      final isOneTime = payment.frequencyEnum == PaymentFrequency.unaVez;
      if (payment.isRecurring && !isOneTime) {
        final nextDue = PaymentUtils.nextDueDate(
          payment.dueDate,
          payment.frequencyEnum,
        );
        final updated = payment.copyWith(
          dueDate: nextDue,
          status: PaymentStatus.pending.id,
          updatedAt: now,
        );
        batch.update(_paymentsCollection(uid).doc(payment.id), updated.toMap());
      } else {
        final updated = payment.copyWith(
          status: PaymentStatus.paid.id,
          updatedAt: now,
        );
        batch.update(_paymentsCollection(uid).doc(payment.id), updated.toMap());
      }

      await batch.commit();
    } catch (_) {
      throw AppException.generic;
    }
  }

  Future<void> markAsPending(String uid, Payment payment) async {
    try {
      final updated = payment.copyWith(
        status: PaymentStatus.pending.id,
        updatedAt: DateTime.now(),
      );
      await _paymentsCollection(uid).doc(payment.id).update(updated.toMap());
    } catch (_) {
      throw AppException.generic;
    }
  }

  /// Carga datos de demostración, útiles durante el desarrollo/pruebas.
  /// Cada documento queda marcado con `isDemo: true` para poder
  /// identificarlo y eliminarlo fácilmente después.
  Future<void> seedDemoData(String uid) async {
    try {
      final now = DateTime.now();
      final batch = _firestore.batch();

      final demoPayments = <Map<String, dynamic>>[
        {
          'name': 'Internet',
          'category': 'servicios',
          'amount': 25000.0,
          'currency': 'CRC',
          'dueDays': 0,
          'frequency': 'mensual',
        },
        {
          'name': 'Electricidad',
          'category': 'servicios',
          'amount': 18500.0,
          'currency': 'CRC',
          'dueDays': 5,
          'frequency': 'mensual',
        },
        {
          'name': 'Netflix',
          'category': 'suscripciones',
          'amount': 12.0,
          'currency': 'USD',
          'dueDays': 1,
          'frequency': 'mensual',
        },
        {
          'name': 'Spotify',
          'category': 'suscripciones',
          'amount': 10.0,
          'currency': 'USD',
          'dueDays': 3,
          'frequency': 'mensual',
        },
        {
          'name': 'Seguro del vehículo',
          'category': 'transporte',
          'amount': 35000.0,
          'currency': 'CRC',
          'dueDays': 10,
          'frequency': 'mensual',
        },
        {
          'name': 'Cambio de aceite',
          'category': 'mantenimiento',
          'amount': 25000.0,
          'currency': 'CRC',
          'dueDays': 20,
          'frequency': 'trimestral',
        },
      ];

      for (final demo in demoPayments) {
        final docRef = _paymentsCollection(uid).doc();
        final dueDate = DateTime.now().add(Duration(days: demo['dueDays'] as int));
        final payment = Payment(
          id: docRef.id,
          userId: uid,
          name: demo['name'] as String,
          category: demo['category'] as String,
          amount: demo['amount'] as double,
          currency: demo['currency'] as String,
          dueDate: DateTime(dueDate.year, dueDate.month, dueDate.day),
          isRecurring: true,
          frequency: demo['frequency'] as String,
          reminderDays: 1,
          status: PaymentStatus.pending.id,
          notes: 'Dato de demostración',
          createdAt: now,
          updatedAt: now,
          isDemo: true,
        );
        batch.set(docRef, payment.toMap());
      }

      await batch.commit();
    } catch (_) {
      throw AppException.generic;
    }
  }

  Future<void> removeDemoData(String uid) async {
    try {
      final demoDocs =
          await _paymentsCollection(uid).where('isDemo', isEqualTo: true).get();
      final batch = _firestore.batch();
      for (final doc in demoDocs.docs) {
        final historyDocs = await doc.reference.collection(FirestorePaths.history).get();
        for (final h in historyDocs.docs) {
          batch.delete(h.reference);
        }
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (_) {
      throw AppException.generic;
    }
  }
}
