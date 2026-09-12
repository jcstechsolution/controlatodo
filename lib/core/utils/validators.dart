/// Validaciones reutilizables para formularios.
class Validators {
  Validators._();

  static final RegExp _emailRegex =
      RegExp(r'^[\w\.\-\+]+@[\w\-]+\.[a-zA-Z]{2,}$');

  static String? required(String? value, {String field = 'Este campo'}) {
    if (value == null || value.trim().isEmpty) {
      return '$field es obligatorio.';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El correo es obligatorio.';
    }
    if (!_emailRegex.hasMatch(value.trim())) {
      return 'Ingresa un correo electrónico válido.';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es obligatoria.';
    }
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres.';
    }
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) {
      return 'Confirma tu contraseña.';
    }
    if (value != original) {
      return 'Las contraseñas no coinciden.';
    }
    return null;
  }

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre es obligatorio.';
    }
    if (value.trim().length < 2) {
      return 'Ingresa un nombre válido.';
    }
    return null;
  }

  static String? amount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El monto es obligatorio.';
    }
    final normalized = value.replaceAll(',', '.');
    final parsed = double.tryParse(normalized);
    if (parsed == null) {
      return 'Ingresa un monto numérico válido.';
    }
    if (parsed <= 0) {
      return 'El monto debe ser mayor que 0.';
    }
    return null;
  }

  static String? paymentName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre del pago es obligatorio.';
    }
    return null;
  }
}
