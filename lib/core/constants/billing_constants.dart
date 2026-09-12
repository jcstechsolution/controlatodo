/// IDs de los productos de suscripción Premium tal como quedan registrados
/// en cada tienda (Google Play / App Store). Son permanentes una vez
/// creados en Play Console — nunca cambiarlos sin crear productos nuevos.
class BillingConstants {
  BillingConstants._();

  static const String premiumMonthlyProductId = 'premium_monthly';
  static const String premiumAnnualProductId = 'premium_annual';

  static const Set<String> allProductIds = {
    premiumMonthlyProductId,
    premiumAnnualProductId,
  };

  /// Paquete real de la app en Google Play. El backend (Cloud Function)
  /// vuelve a fijar este mismo valor de forma independiente — nunca confía
  /// en lo que mande el cliente — pero se deja aquí documentado para que
  /// ambos lados coincidan siempre.
  static const String androidPackageName = 'com.jcs.controlatodo';
}
