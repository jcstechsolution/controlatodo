import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:controlatodo/models/payment_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Payment.toMap / fromMap', () {
    test('ida y vuelta conserva todos los campos, incluidos los nuevos', () {
      final original = Payment(
        id: 'p1',
        userId: 'u1',
        name: 'Internet',
        provider: 'Kölbi',
        category: 'servicios',
        amount: 25000,
        currency: 'CRC',
        dueDate: DateTime(2026, 4, 10),
        isRecurring: true,
        frequency: 'mensual',
        reminderDays: 1,
        status: 'pending',
        notes: 'Plan 100 Mbps',
        invoiceNumber: 'F-00123',
        documentUrl: 'https://example.com/factura.pdf',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 2),
        isDemo: false,
      );

      final map = original.toMap();
      final restored = Payment.fromMap('p1', map);

      expect(restored.id, 'p1');
      expect(restored.userId, 'u1');
      expect(restored.name, 'Internet');
      expect(restored.provider, 'Kölbi');
      expect(restored.category, 'servicios');
      expect(restored.amount, 25000);
      expect(restored.currency, 'CRC');
      expect(restored.dueDate, DateTime(2026, 4, 10));
      expect(restored.isRecurring, isTrue);
      expect(restored.frequency, 'mensual');
      expect(restored.reminderDays, 1);
      expect(restored.status, 'pending');
      expect(restored.notes, 'Plan 100 Mbps');
      expect(restored.invoiceNumber, 'F-00123');
      expect(restored.documentUrl, 'https://example.com/factura.pdf');
      expect(restored.isDemo, isFalse);
    });

    test('fromMap con un documento "viejo" (sin campos nuevos) no truena y usa defaults seguros', () {
      // Simula un documento guardado ANTES de que existieran userId,
      // provider, invoiceNumber y documentUrl.
      final oldMap = {
        'name': 'Netflix',
        'category': 'suscripciones',
        'amount': 12.0,
        'currency': 'USD',
        'dueDate': Timestamp.fromDate(DateTime(2026, 3, 1)),
        'isRecurring': true,
        'frequency': 'mensual',
        'reminderDays': 1,
        'status': 'pending',
        'createdAt': Timestamp.fromDate(DateTime(2025, 1, 1)),
        'updatedAt': Timestamp.fromDate(DateTime(2025, 1, 1)),
      };

      final restored = Payment.fromMap('old1', oldMap);

      expect(restored.userId, ''); // sin fallback, cae en '' (no truena)
      expect(restored.provider, isNull);
      expect(restored.invoiceNumber, isNull);
      expect(restored.documentUrl, isNull);
      expect(restored.name, 'Netflix');
      expect(restored.amount, 12.0);
    });

    test('fromMap usa fallbackUserId cuando el documento no trae userId', () {
      final oldMap = {
        'name': 'Spotify',
        'category': 'suscripciones',
        'amount': 10.0,
        'currency': 'USD',
        'frequency': 'mensual',
        'status': 'pending',
      };

      final restored = Payment.fromMap(
        'old2',
        oldMap,
        fallbackUserId: 'uid-derivado-de-la-ruta',
      );

      expect(restored.userId, 'uid-derivado-de-la-ruta');
    });

    test('fromMap con un mapa completamente vacío no truena', () {
      final restored = Payment.fromMap('empty', const {});
      expect(restored.name, '');
      expect(restored.amount, 0);
      expect(restored.currency, 'CRC');
      expect(restored.isRecurring, isFalse);
      expect(restored.isDemo, isFalse);
    });
  });
}
