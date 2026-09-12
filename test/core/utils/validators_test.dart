import 'package:controlatodo/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.amount', () {
    test('rechaza vacío', () {
      expect(Validators.amount(''), isNotNull);
      expect(Validators.amount(null), isNotNull);
    });

    test('rechaza texto no numérico', () {
      expect(Validators.amount('abc'), isNotNull);
    });

    test('rechaza cero y negativos', () {
      expect(Validators.amount('0'), isNotNull);
      expect(Validators.amount('-5'), isNotNull);
    });

    test('acepta un monto positivo válido', () {
      expect(Validators.amount('25000'), isNull);
    });

    test('acepta coma como separador decimal', () {
      expect(Validators.amount('25,50'), isNull);
    });
  });

  group('Validators.paymentName', () {
    test('rechaza vacío o solo espacios', () {
      expect(Validators.paymentName(''), isNotNull);
      expect(Validators.paymentName('   '), isNotNull);
      expect(Validators.paymentName(null), isNotNull);
    });

    test('acepta un nombre válido', () {
      expect(Validators.paymentName('Internet'), isNull);
    });
  });

  group('Validators.email', () {
    test('rechaza vacío', () {
      expect(Validators.email(''), isNotNull);
    });

    test('rechaza un correo mal formado', () {
      expect(Validators.email('no-es-un-correo'), isNotNull);
    });

    test('acepta un correo válido', () {
      expect(Validators.email('persona@ejemplo.com'), isNull);
    });
  });

  group('Validators.password', () {
    test('rechaza vacío', () {
      expect(Validators.password(''), isNotNull);
    });

    test('rechaza menos de 6 caracteres', () {
      expect(Validators.password('123'), isNotNull);
    });

    test('acepta 6 caracteres o más', () {
      expect(Validators.password('123456'), isNull);
    });
  });

  group('Validators.confirmPassword', () {
    test('rechaza si no coincide', () {
      expect(Validators.confirmPassword('abc123', 'abc124'), isNotNull);
    });

    test('acepta si coincide', () {
      expect(Validators.confirmPassword('abc123', 'abc123'), isNull);
    });
  });
}
