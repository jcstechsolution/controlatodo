/// Excepción de aplicación con un mensaje amigable, seguro para mostrar
/// directamente al usuario (nunca se exponen stack traces ni mensajes
/// técnicos de Firebase).
class AppException implements Exception {
  final String message;

  const AppException(this.message);

  static const AppException generic = AppException(
    'Ha ocurrido un problema. Inténtalo nuevamente.',
  );

  @override
  String toString() => message;
}
