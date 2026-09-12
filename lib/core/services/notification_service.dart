import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../utils/currency_formatter.dart';
import '../../models/payment_model.dart';

/// Envuelve `flutter_local_notifications` para programar recordatorios de
/// pago y avisos de vencimiento de forma completamente local (sin backend).
///
/// La arquitectura queda preparada para que, en una fase posterior, un
/// disparador de Firebase Cloud Messaging pueda invocar los mismos métodos
/// de "mostrar notificación" desde un mensaje push entrante.
class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const String _reminderChannelId = 'controlatodo_reminders';
  static const String _overdueChannelId = 'controlatodo_overdue';

  Future<void> init() async {
    if (_initialized) return;
    try {
      tz_data.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('America/Costa_Rica'));
    } catch (_) {
      // Si la zona horaria no está disponible, se usa la configuración
      // por defecto del dispositivo sin interrumpir el arranque de la app.
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(initSettings);

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(const AndroidNotificationChannel(
      _reminderChannelId,
      'Recordatorios de pago',
      description: 'Avisos antes de que un pago venza.',
      importance: Importance.high,
    ));
    await androidImpl?.createNotificationChannel(const AndroidNotificationChannel(
      _overdueChannelId,
      'Pagos vencidos',
      description: 'Avisos de pagos que ya vencieron.',
      importance: Importance.high,
    ));
    await androidImpl?.requestNotificationsPermission();

    // En iOS/macOS los permisos ya se solicitan arriba, en
    // `DarwinInitializationSettings` (requestAlertPermission/Badge/Sound),
    // así que no hace falta resolverlos de nuevo aquí.

    _initialized = true;
  }

  int _notificationIdFor(String paymentId) => paymentId.hashCode & 0x7fffffff;

  /// Programa (o reprograma) el recordatorio local de un pago según su
  /// `reminderDays` y `dueDate`. Si la fecha calculada ya pasó, no programa
  /// nada (para eso está el aviso de vencido, mostrado desde el dashboard).
  Future<void> scheduleReminderForPayment(Payment payment) async {
    if (!_initialized) return;
    final id = _notificationIdFor(payment.id);
    await _plugin.cancel(id);

    final reminderDate = DateTime(
      payment.dueDate.year,
      payment.dueDate.month,
      payment.dueDate.day,
    ).subtract(Duration(days: payment.reminderDays));

    final scheduledDateTime = DateTime(
      reminderDate.year,
      reminderDate.month,
      reminderDate.day,
      9,
      0,
    );

    if (scheduledDateTime.isBefore(DateTime.now())) return;

    final amountLabel = CurrencyFormatter.format(payment.amount, payment.currency);
    final whenLabel = payment.reminderDays == 0 ? 'hoy' : 'pronto';

    try {
      await _plugin.zonedSchedule(
        id,
        '🔔 Recordatorio',
        'Tu pago de ${payment.name} por $amountLabel vence $whenLabel.',
        tz.TZDateTime.from(scheduledDateTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _reminderChannelId,
            'Recordatorios de pago',
            channelDescription: 'Avisos antes de que un pago venza.',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: null,
      );
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('No se pudo programar la notificación: $e');
      }
    }
  }

  Future<void> cancelForPayment(String paymentId) async {
    if (!_initialized) return;
    await _plugin.cancel(_notificationIdFor(paymentId));
  }

  Future<void> showOverdueNotification(Payment payment) async {
    if (!_initialized) return;
    final amountLabel = CurrencyFormatter.format(payment.amount, payment.currency);
    await _plugin.show(
      _notificationIdFor('${payment.id}_overdue'),
      '⚠️ Pago vencido',
      'El pago de ${payment.name} por $amountLabel está vencido.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _overdueChannelId,
          'Pagos vencidos',
          channelDescription: 'Avisos de pagos que ya vencieron.',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  /// Reprograma los recordatorios de una lista completa de pagos pendientes.
  /// Se invoca cada vez que cambia la lista de pagos del usuario.
  Future<void> syncReminders(List<Payment> pendingPayments) async {
    if (!_initialized) return;
    for (final payment in pendingPayments) {
      await scheduleReminderForPayment(payment);
    }
  }
}
