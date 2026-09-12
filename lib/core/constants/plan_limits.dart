/// Límites y precios de los planes de ControlaTodo.
///
/// Por ahora solo se define la estructura de planes y límites.
/// La integración real de cobros (Google Play Billing / App Store)
/// se realizará en una fase posterior.
class PlanLimits {
  PlanLimits._();

  static const int freeMaxPayments = 10;

  static const double premiumMonthlyPriceUsd = 2.99;
  static const double premiumYearlyPriceUsd = 29.99;
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
