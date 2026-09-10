import 'package:test/test.dart';
import '../lib/tipo.dart';

void main() {
  group('Pruebas de Tipo Azul', () {
    final azul = Tipo(
      tipo: TipoZona.azul,
      color: 'Azul',
      regla: 'Todos los numeros deben ser iguales',
      puntuacion: 10,
    );

    test('Azul permite numeros iguales', () {
      expect(
        azul.validarMovimiento([3, 3, 3, 3]),
        isTrue,
      );
    });

    test('Azul no permite numeros diferentes', () {
      expect(
        azul.validarMovimiento([3, 3, 4, 3]),
        isFalse,
      );
    });
  });

  group('Pruebas de Tipo Rojo', () {
    final rojo = Tipo(
      tipo: TipoZona.rojo,
      color: 'Rojo',
      regla: 'Todos los numeros deben ser diferentes',
      puntuacion: 10,
    );

    test('Rojo permite numeros diferentes', () {
      expect(
        rojo.validarMovimiento([1, 2, 3, 4]),
        isTrue,
      );
    });

    test('Rojo no permite numeros repetidos', () {
      expect(
        rojo.validarMovimiento([1, 2, 3, 2]),
        isFalse,
      );
    });
  });

  group('Pruebas de Tipo Verde', () {
    final verde = Tipo(
      tipo: TipoZona.verde,
      color: 'Verde',
      regla: 'Los numeros pueden repetirse',
      puntuacion: 10,
    );

    test('Verde permite numeros repetidos', () {
      expect(
        verde.validarMovimiento([2, 2, 5, 5]),
        isTrue,
      );
    });

    test('Verde permite numeros diferentes', () {
      expect(
        verde.validarMovimiento([1, 3, 5, 7]),
        isTrue,
      );
    });
  });

  group('Pruebas de Tipo Morado', () {
    final morado = Tipo(
      tipo: TipoZona.morado,
      color: 'Morado',
      regla: 'Debe contener exactamente dos numeros',
      puntuacion: 10,
    );

    test('Morado permite exactamente dos numeros', () {
      expect(
        morado.validarMovimiento([3, 7]),
        isTrue,
      );
    });
 test('Morado permite dos numeros repetidos', () {
      expect(
        morado.validarMovimiento([3, 3, 7, 7]),
        isTrue,
      );
    });
    test('Morado no permite mas de dos numeros', () {
      expect(
        morado.validarMovimiento([3, 7, 5]),
        isFalse,
      );
    });

    test('Morado no permite solamente un numero', () {
      expect(
        morado.validarMovimiento([3]),
        isFalse,
      );
    });
  });

  group('Pruebas de Tipo Amarillo', () {
    final amarillo = Tipo(
      tipo: TipoZona.amarillo,
      color: 'Amarillo',
      regla: 'Ningún numero puede repetirse entre las zonas amarillas',
      puntuacion: 10,
    );

    test('Amarillo permite numeros diferentes', () {
      expect(
        amarillo.validarAmarillo([1, 3, 5, 7]),
        isTrue,
      );
    });

    test('Amarillo no permite numeros repetidos', () {
      expect(
        amarillo.validarAmarillo([1, 3, 5, 3]),
        isFalse,
      );
    });
  });

  group('Pruebas de puntuacion', () {
    test('El tipo devuelve su puntuacion', () {
      final azul = Tipo(
        tipo: TipoZona.azul,
        color: 'Azul',
        regla: 'Todos iguales',
        puntuacion: 15,
      );

      expect(
        azul.calcularPuntuacion(),
        equals(15),
      );
    });
  });
}