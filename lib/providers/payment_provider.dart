import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/constants/payment_enums.dart';
import '../core/constants/plan_limits.dart';
import '../core/services/notification_service.dart';
import '../core/utils/app_exception.dart';
import '../core/utils/payment_utils.dart';
import '../models/monthly_summary.dart';
import '../models/payment_history_model.dart';
import '../models/payment_model.dart';
import '../repositories/payment_repository.dart';

enum PaymentFilter { all, pending, paid, overdue }

enum PaymentSort { dueDateAsc, amountDesc, amountAsc, name }

/// Mantiene en memoria la lista de pagos del usuario (sincronizada en
/// tiempo real con Firestore) y expone filtros, orden, búsqueda y
/// resúmenes ya calculados para las pantallas.
class PaymentProvider extends ChangeNotifier {
  final PaymentRepository _repository;
  StreamSubscription<List<Payment>>? _subscription;
  StreamSubscription<List<PaymentHistoryEntry>>? _historySubscription;
  String? _uid;

  PaymentProvider({PaymentRepository? repository})
      : _repository = repository ?? PaymentRepository();

  List<Payment> _allPayments = [];

  /// Historial de TODOS los pagos del usuario (de todas las subcolecciones
  /// `history`), usado para que las estadísticas de "pagado" sean
  /// históricamente correctas en vez de depender del estado actual de cada
  /// `Payment`. Ver `PaymentRepository.watchAllHistory`.
  List<PaymentHistoryEntry> _allHistory = [];
  bool isLoading = true;
  String? errorMessage;

  PaymentFilter filter = PaymentFilter.all;
  PaymentSort sort = PaymentSort.dueDateAsc;
  String searchQuery = '';

  List<Payment> get allPayments => List.unmodifiable(_allPayments);

  List<PaymentHistoryEntry> get allHistory => List.unmodifiable(_allHistory);

  int get totalCount => _allPayments.length;

  bool canAddMore(bool isPremium) {
    if (isPremium) return true;
    return _allPayments.length < PlanLimits.freeMaxPayments;
  }

  void bind(String? uid) {
    if (_uid == uid) return;
    _uid = uid;
    _subscription?.cancel();
    _historySubscription?.cancel();
    if (uid == null) {
      _allPayments = [];
      _allHistory = [];
      isLoading = false;
      notifyListeners();
      return;
    }
    isLoading = true;
    notifyListeners();
    _subscription = _repository.watchPayments(uid).listen((payments) {
      _allPayments = payments;
      isLoading = false;
      notifyListeners();
      _syncNotifications();
    }, onError: (_) {
      errorMessage = AppException.generic.message;
      isLoading = false;
      notifyListeners();
    });
    _historySubscription = _repository.watchAllHistory(uid).listen((history) {
      _allHistory = history;
      if (kDebugMode) {
        // ignore: avoid_print
        print('[HISTORY] ${history.length} registro(s) recibido(s) para uid=$uid: '
            '${history.map((h) => '${h.name ?? h.paymentId}:${h.amount}${h.currency}@${h.paidAt}').toList()}');
      }
      notifyListeners();
    }, onError: (Object e) {
      // Si la consulta de historial completo falla (por ejemplo, porque
      // falta crear el índice de Firestore la primera vez), no se rompe el
      // resto de la app: solo quedan sin datos las estadísticas históricas.
      if (kDebugMode) {
        // ignore: avoid_print
        print('[HISTORY] error en watchAllHistory: $e');
      }
    });
  }

  Stream<List<PaymentHistoryEntry>> watchHistory(String uid, String paymentId) {
    return _repository.watchHistory(uid, paymentId);
  }

  void _syncNotifications() {
    final pending = _allPayments
        .where((p) => p.statusEnum == PaymentStatus.pending)
        .toList();
    NotificationService.instance.syncReminders(pending);
  }

  List<Payment> get filteredPayments {
    Iterable<Payment> result = _allPayments;

    if (searchQuery.trim().isNotEmpty) {
      final query = searchQuery.trim().toLowerCase();
      result = result.where((p) => p.name.toLowerCase().contains(query));
    }

    switch (filter) {
      case PaymentFilter.all:
        break;
      case PaymentFilter.pending:
        result = result.where(
          (p) => PaymentUtils.effectiveStatus(p.dueDate, p.statusEnum) ==
              PaymentStatus.pending,
        );
        break;
      case PaymentFilter.paid:
        result = result.where((p) => p.statusEnum == PaymentStatus.paid);
        break;
      case PaymentFilter.overdue:
        result = result.where(
          (p) => PaymentUtils.effectiveStatus(p.dueDate, p.statusEnum) ==
              PaymentStatus.overdue,
        );
        break;
    }

    final list = result.toList();

    switch (sort) {
      case PaymentSort.dueDateAsc:
        list.sort((a, b) => a.dueDate.compareTo(b.dueDate));
        break;
      case PaymentSort.amountDesc:
        list.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case PaymentSort.amountAsc:
        list.sort((a, b) => a.amount.compareTo(b.amount));
        break;
      case PaymentSort.name:
        list.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
    }

    return list;
  }

  List<Payment> get upcomingPayments {
    final list = _allPayments
        .where((p) => p.statusEnum != PaymentStatus.paid)
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return list.take(5).toList();
  }

  MonthlySummary monthlySummaryFor(String primaryCurrency) {
    final now = DateTime.now();
    final inMonth = _allPayments.where(
      (p) =>
          p.currency == primaryCurrency &&
          p.dueDate.year == now.year &&
          p.dueDate.month == now.month,
    );

    // "Pagado" se calcula desde el historial real (no desde el Payment
    // activo): un pago recurrente vuelve a "pendiente" y avanza su
    // `dueDate` en cuanto se paga, así que el único registro confiable de
    // "esto se pagó este mes" es `PaymentHistoryEntry`.
    final paid = PaymentUtils.paidTotal(
      _allHistory,
      currency: primaryCurrency,
      year: now.year,
      month: now.month,
    );

    double pending = 0;
    for (final p in inMonth) {
      if (p.statusEnum != PaymentStatus.paid) {
        pending += p.amount;
      }
    }

    final upcomingInCurrency = _allPayments.where(
      (p) => p.currency == primaryCurrency && p.statusEnum != PaymentStatus.paid,
    ).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    return MonthlySummary(
      total: paid + pending,
      paid: paid,
      pending: pending,
      nextDue: upcomingInCurrency.isEmpty ? null : upcomingInCurrency.first,
      currency: primaryCurrency,
    );
  }

  /// Suma mensualizada de las obligaciones recurrentes activas en [currency]
  /// (ej. ₡98.400/mes). Ver `PaymentUtils.recurringMonthlyTotal`.
  double recurringMonthlyTotalFor(String currency) {
    final inCurrency = _allPayments.where((p) => p.currency == currency).toList();
    return PaymentUtils.recurringMonthlyTotal(inCurrency);
  }

  /// Igual que [recurringMonthlyTotalFor] pero anualizado (ej. ≈ ₡1.180.800/año).
  double recurringAnnualTotalFor(String currency) {
    final inCurrency = _allPayments.where((p) => p.currency == currency).toList();
    return PaymentUtils.recurringAnnualTotal(inCurrency);
  }

  Future<bool> addPayment({
    required String uid,
    required bool isPremium,
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
    if (!canAddMore(isPremium)) {
      errorMessage =
          'Alcanzaste el límite de ${PlanLimits.freeMaxPayments} pagos del plan gratuito. Actualiza a Premium para agregar pagos ilimitados.';
      notifyListeners();
      return false;
    }
    return _runGuarded(() async {
      await _repository.createPayment(
        uid: uid,
        name: name,
        provider: provider,
        category: category,
        amount: amount,
        currency: currency,
        dueDate: dueDate,
        isRecurring: isRecurring,
        frequency: frequency,
        reminderDays: reminderDays,
        notes: notes,
        invoiceNumber: invoiceNumber,
        documentUrl: documentUrl,
      );
    });
  }

  Future<bool> updatePayment(String uid, Payment payment) async {
    return _runGuarded(() => _repository.updatePayment(uid, payment));
  }

  Future<bool> deletePayment(String uid, String paymentId) async {
    return _runGuarded(() async {
      await _repository.deletePayment(uid, paymentId);
      await NotificationService.instance.cancelForPayment(paymentId);
    });
  }

  Future<bool> markAsPaid(String uid, Payment payment) async {
    return _runGuarded(() => _repository.markAsPaid(uid, payment));
  }

  Future<bool> seedDemoData(String uid) async {
    return _runGuarded(() => _repository.seedDemoData(uid));
  }

  Future<bool> removeDemoData(String uid) async {
    return _runGuarded(() => _repository.removeDemoData(uid));
  }

  void setFilter(PaymentFilter value) {
    filter = value;
    notifyListeners();
  }

  void setSort(PaymentSort value) {
    sort = value;
    notifyListeners();
  }

  void setSearchQuery(String value) {
    searchQuery = value;
    notifyListeners();
  }

  Future<bool> _runGuarded(Future<void> Function() action) async {
    errorMessage = null;
    try {
      await action();
      return true;
    } on AppException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      errorMessage = AppException.generic.message;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _historySubscription?.cancel();
    super.dispose();
  }
}
