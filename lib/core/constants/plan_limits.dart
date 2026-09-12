/// Límites y precios de los planes de ControlaTodo.
///
/// Los precios de aquí son solo el *fallback* que se muestra en la pantalla
/// Premium mientras la tienda no respondió (o no está disponible, ej. un
/// emulador sin Play Store) — el precio real y ya localizado siempre viene
/// de `ProductDetails.price` (ver `BillingProvider`/`premium_screen.dart`).
/// Cambiar estos números NO cambia lo que de verdad se cobra: eso se define
/// en Play Console / App Store Connect.
class PlanLimits {
  PlanLimits._();

  static const int freeMaxPayments = 10;

  static const double premiumMonthlyPriceUsd = 3.99;
  static const double premiumYearlyPriceUsd = 38.99;
}

enum UserPlan { free, premium }

extension UserPlanX on UserPlan {
  String get id => name;

  String get label {
    switch (this) {
      case UserPlan.free:
        return 'Gratis';
      case UserPlan.premium:
        return 'Premium';
    }
  }

  static UserPlan fromId(String? id) {
    return UserPlan.values.firstWhere(
      (p) => p.id == id,
      orElse: () => UserPlan.free,
    );
  }
}
