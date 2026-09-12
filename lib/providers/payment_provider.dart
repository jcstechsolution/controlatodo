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
  String? _uid;

  PaymentProvider({PaymentRepository? repository})
      : _repository = repository ?? PaymentRepository();

  List<Payment> _allPayments = [];
  bool isLoading = true;
  String? errorMessage;

  PaymentFilter filter = PaymentFilter.all;
  PaymentSort sort = PaymentSort.dueDateAsc;
  String searchQuery = '';

  List<Payment> get allPayments => List.unmodifiable(_allPayments);

  int get totalCount => _allPayments.length;

  bool canAddMore(bool isPremium) {
    if (isPremium) return true;
    return _allPayments.length < PlanLimits.freeMaxPayments;
  }

  void bind(String? uid) {
    if (_uid == uid) return;
    _uid = uid;
    _subscription?.cancel();
    if (uid == null) {
      _allPayments = [];
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

    double paid = 0;
    double pending = 0;
    for (final p in inMonth) {
      if (p.statusEnum == PaymentStatus.paid) {
        paid += p.amount;
      } else {
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

  Future<bool> addPayment({
    required String uid,
    required bool isPremium,
    required String name,
    required String category,
    required double amount,
    required String currency,
    required DateTime dueDate,
    required bool isRecurring,
    required String frequency,
    required int reminderDays,
    String? notes,
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
        category: category,
        amount: amount,
        currency: currency,
        dueDate: dueDate,
        isRecurring: isRecurring,
        frequency: frequency,
        reminderDays: reminderDays,
        notes: notes,
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
    super.dispose();
  }
}
