import 'package:flutter/material.dart';

/// Configuración del usuario, almacenada en users/{userId}/settings/config.
class AppSettingsModel {
  final String currency;
  final bool notificationsEnabled;
  final String themeMode; // system | light | dark

  const AppSettingsModel({
    this.currency = 'CRC',
    this.notificationsEnabled = true,
    this.themeMode = 'system',
  });

  /// Traduce el string guardado (`system|light|dark`) al `ThemeMode` que
  /// espera `MaterialApp`. Cualquier valor desconocido cae en `system`,
  /// igual que hace el resto de los `fromId`/`fromCode` de la app.
  ThemeMode get themeModeEnum {
    switch (themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  AppSettingsModel copyWith({
    String? currency,
    bool? notificationsEnabled,
    String? themeMode,
  }) {
    return AppSettingsModel(
      currency: currency ?? this.currency,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'currency': currency,
      'notificationsEnabled': notificationsEnabled,
      'themeMode': themeMode,
    };
  }

  factory AppSettingsModel.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const AppSettingsModel();
    return AppSettingsModel(
      currency: map['currency'] as String? ?? 'CRC',
      notificationsEnabled: map['notificationsEnabled'] as bool? ?? true,
      themeMode: map['themeMode'] as String? ?? 'system',
    );
  }
}
