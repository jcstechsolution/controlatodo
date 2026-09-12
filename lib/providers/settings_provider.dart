import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_settings_model.dart';
import '../repositories/settings_repository.dart';

/// Expone la configuración del usuario (moneda principal, notificaciones,
/// tema) y permite actualizarla.
class SettingsProvider extends ChangeNotifier {
  final SettingsRepository _repository;
  StreamSubscription<AppSettingsModel>? _subscription;
  String? _uid;

  SettingsProvider({SettingsRepository? repository})
      : _repository = repository ?? SettingsRepository();

  AppSettingsModel settings = const AppSettingsModel();
  bool isLoading = false;

  void bind(String? uid) {
    if (_uid == uid) return;
    _uid = uid;
    _subscription?.cancel();
    if (uid == null) {
      settings = const AppSettingsModel();
      notifyListeners();
      return;
    }
    isLoading = true;
    notifyListeners();
    _subscription = _repository.watchSettings(uid).listen((value) {
      settings = value;
      isLoading = false;
      notifyListeners();
    });
  }

  Future<void> updateCurrency(String currencyCode) async {
    if (_uid == null) return;
    settings = settings.copyWith(currency: currencyCode);
    notifyListeners();
    await _repository.updateSettings(_uid!, settings);
  }

  Future<void> updateNotificationsEnabled(bool enabled) async {
    if (_uid == null) return;
    settings = settings.copyWith(notificationsEnabled: enabled);
    notifyListeners();
    await _repository.updateSettings(_uid!, settings);
  }

  Future<void> updateThemeMode(String mode) async {
    if (_uid == null) return;
    settings = settings.copyWith(themeMode: mode);
    notifyListeners();
    await _repository.updateSettings(_uid!, settings);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
