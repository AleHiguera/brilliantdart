import 'package:test/test.dart';
import '../lib/tipoo.dart';

void main() {
  group('Pruebas de Tipo Azul', () {
    final azul = Tipo(
      tipo: TipoZona.azul,
      color: 'Azul',
      regla: 'Todos los numeros deben ser iguales',
      puntuacion: 7,
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
      puntuacion: 6,
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
      puntuacion: 4,
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
      puntuacion: 8,
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
      puntuacion: 8,
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

  group('Pruebas de puntuacion por posicion', () {
    test('Azul en primer lugar puntua 7', () {
      final azul = Tipo(
        tipo: TipoZona.azul,
        color: 'Azul',
        regla: 'Todos iguales',
        puntuacion: 7,
      );

      expect(azul.calcularPuntuacion(1), equals(7));
    });

    test('Azul en segundo lugar puntua 5', () {
      final azul = Tipo(
        tipo: TipoZona.azul,
        color: 'Azul',
        regla: 'Todos iguales',
        puntuacion: 7,
      );

      expect(azul.calcularPuntuacion(2), equals(5));
    });

    test('Azul en tercer lugar puntua 3', () {
      final azul = Tipo(
        tipo: TipoZona.azul,
        color: 'Azul',
        regla: 'Todos iguales',
        puntuacion: 7,
      );

      expect(azul.calcularPuntuacion(3), equals(3));
    });

    test('Rojo en primer lugar puntua 6', () {
      final rojo = Tipo(
        tipo: TipoZona.rojo,
        color: 'Rojo',
        regla: 'Todos diferentes',
        puntuacion: 6,
      );

      expect(rojo.calcularPuntuacion(1), equals(6));
    });

    test('Rojo en segundo lugar puntua 4', () {
      final rojo = Tipo(
        tipo: TipoZona.rojo,
        color: 'Rojo',
        regla: 'Todos diferentes',
        puntuacion: 6,
      );

      expect(rojo.calcularPuntuacion(2), equals(4));
    });

    test('Verde en segundo lugar puntua 3', () {
      final verde = Tipo(
        tipo: TipoZona.verde,
        color: 'Verde',
        regla: 'Puede repetirse',
        puntuacion: 4,
      );

      expect(verde.calcularPuntuacion(2), equals(3));
    });

    test('Morado en primer lugar puntua 8', () {
      final morado = Tipo(
        tipo: TipoZona.morado,
        color: 'Morado',
        regla: 'Dos numeros distintos',
        puntuacion: 8,
      );

      expect(morado.calcularPuntuacion(1), equals(8));
    });

    test('Amarillo en segundo lugar puntua 6', () {
      final amarillo = Tipo(
        tipo: TipoZona.amarillo,
        color: 'Amarillo',
        regla: 'Sin repetidos',
        puntuacion: 8,
      );

      expect(amarillo.calcularPuntuacion(2), equals(6));
    });
  });
}