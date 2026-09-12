/// Rutas de colecciones/documentos usadas en Cloud Firestore.
///
/// Estructura:
/// users/{userId}
/// users/{userId}/payments/{paymentId}
/// users/{userId}/payments/{paymentId}/history/{historyId}
/// users/{userId}/settings/config
class FirestorePaths {
  FirestorePaths._();

  static const String users = 'users';
  static const String payments = 'payments';
  static const String history = 'history';
  static const String settings = 'settings';
  static const String configDoc = 'config';
}
