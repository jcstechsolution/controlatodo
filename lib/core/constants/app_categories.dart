import 'package:flutter/material.dart';

/// Categorías disponibles para un pago.
enum PaymentCategory {
  vivienda,
  servicios,
  entretenimiento,
  transporte,
  salud,
  educacion,
  finanzas,
  suscripciones,
  mantenimiento,
  otros,
}

extension PaymentCategoryX on PaymentCategory {
  String get id => name;

  String get label {
    switch (this) {
      case PaymentCategory.vivienda:
        return 'Vivienda';
      case PaymentCategory.servicios:
        return 'Servicios';
      case PaymentCategory.entretenimiento:
        return 'Entretenimiento';
      case PaymentCategory.transporte:
        return 'Transporte';
      case PaymentCategory.salud:
        return 'Salud';
      case PaymentCategory.educacion:
        return 'Educación';
      case PaymentCategory.finanzas:
        return 'Finanzas';
      case PaymentCategory.suscripciones:
        return 'Suscripciones';
      case PaymentCategory.mantenimiento:
        return 'Mantenimiento';
      case PaymentCategory.otros:
        return 'Otros';
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentCategory.vivienda:
        return Icons.home_rounded;
      case PaymentCategory.servicios:
        return Icons.bolt_rounded;
      case PaymentCategory.entretenimiento:
        return Icons.movie_rounded;
      case PaymentCategory.transporte:
        return Icons.directions_car_rounded;
      case PaymentCategory.salud:
        return Icons.favorite_rounded;
      case PaymentCategory.educacion:
        return Icons.school_rounded;
      case PaymentCategory.finanzas:
        return Icons.account_balance_rounded;
      case PaymentCategory.suscripciones:
        return Icons.subscriptions_rounded;
      case PaymentCategory.mantenimiento:
        return Icons.build_rounded;
      case PaymentCategory.otros:
        return Icons.category_rounded;
    }
  }

  static PaymentCategory fromId(String? id) {
    return PaymentCategory.values.firstWhere(
      (c) => c.id == id,
      orElse: () => PaymentCategory.otros,
    );
  }
}
