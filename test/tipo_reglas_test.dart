import 'package:test/test.dart';

import 'package:brilliantdart/tipoo.dart';

void main() {
  Tipo crear(TipoZona tipo, {int puntuacion = 0}) => Tipo(
        tipo: tipo,
        color: tipo.name,
        regla: 'Regla ${tipo.name}',
        puntuacion: puntuacion,
      );

  group('Fábrica de tipos', () {
    test('Crea la subclase correcta para cada color', () {
      expect(crear(TipoZona.azul), isA<TipoAzul>());
      expect(crear(TipoZona.rojo), isA<TipoRojo>());
      expect(crear(TipoZona.verde), isA<TipoVerde>());
      expect(crear(TipoZona.morado), isA<TipoMorado>());
      expect(crear(TipoZona.amarillo), isA<TipoAmarillo>());
    });

    test('Conserva color, regla y puntuación', () {
      final tipo = crear(TipoZona.rojo, puntuacion: 6);

      expect(tipo.tipo, TipoZona.rojo);
      expect(tipo.color, 'rojo');
      expect(tipo.regla, 'Regla rojo');
      expect(tipo.puntuacion, 6);
      expect(tipo.obtenerInformacion(), contains('Tipo: rojo'));
      expect(tipo.obtenerInformacion(), contains('Regla: Regla rojo'));
      expect(tipo.obtenerInformacion(), contains('Puntuación: 6'));
    });
  });

  group('Reglas al ir colocando números', () {
    test('Azul: solo acepta el mismo número que ya tiene', () {
      final azul = crear(TipoZona.azul);

      expect(azul.esPosibleAgregar([], 4), isTrue);
      expect(azul.esPosibleAgregar([4, 4], 4), isTrue);
      expect(azul.esPosibleAgregar([4, 4], 5), isFalse);
    });

    test('Rojo: no acepta un número que ya está en la zona', () {
      final rojo = crear(TipoZona.rojo);

      expect(rojo.esPosibleAgregar([], 1), isTrue);
      expect(rojo.esPosibleAgregar([1, 2], 3), isTrue);
      expect(rojo.esPosibleAgregar([1, 2], 2), isFalse);
    });

    test('Verde: acepta cualquier número', () {
      final verde = crear(TipoZona.verde);

      for (var numero = 1; numero <= 6; numero++) {
        expect(verde.esPosibleAgregar([1, 1, 6], numero), isTrue);
      }
    });

    test('Morado: acepta hasta dos números distintos', () {
      final morado = crear(TipoZona.morado);

      expect(morado.esPosibleAgregar([], 1), isTrue);
      expect(morado.esPosibleAgregar([2], 5), isTrue);
      expect(morado.esPosibleAgregar([2, 5], 2), isTrue);
      expect(morado.esPosibleAgregar([2, 5], 6), isFalse);
    });

    test('Amarillo: no acepta un número repetido', () {
      final amarillo = crear(TipoZona.amarillo);

      expect(amarillo.esPosibleAgregar([], 1), isTrue);
      expect(amarillo.esPosibleAgregar([1, 2], 3), isTrue);
      expect(amarillo.esPosibleAgregar([1, 2], 1), isFalse);
    });
  });

  group('Reglas al completar una zona', () {
    test('Azul vacío o con un solo número es válido', () {
      final azul = crear(TipoZona.azul);

      expect(azul.validarMovimiento([]), isTrue);
      expect(azul.validarMovimiento([5]), isTrue);
    });

    test('Rojo con los seis números distintos es válido', () {
      expect(crear(TipoZona.rojo).validarMovimiento([1, 2, 3, 4, 5, 6]), isTrue);
    });

    test('Morado necesita exactamente dos números distintos', () {
      final morado = crear(TipoZona.morado);

      expect(morado.validarMovimiento([3, 5, 5, 3]), isTrue);
      expect(morado.validarMovimiento([3, 3, 3]), isFalse);
      expect(morado.validarMovimiento([1, 2, 3]), isFalse);
    });

    test('validarAmarillo detecta repetidos solo en zonas amarillas', () {
      final amarillo = crear(TipoZona.amarillo);

      expect(amarillo.validarAmarillo([1, 2, 3, 4, 5]), isTrue);
      expect(amarillo.validarAmarillo([1, 2, 1]), isFalse);
      expect(crear(TipoZona.verde).validarAmarillo([1, 2, 3]), isFalse);
    });
  });

  group('Puntuación por posición', () {
    const esperadas = {
      TipoZona.azul: [7, 5, 3],
      TipoZona.rojo: [6, 4, 2],
      TipoZona.verde: [4, 3, 2],
      TipoZona.morado: [6, 4, 2],
      TipoZona.amarillo: [8, 6, 4],
    };

    for (final MapEntry(key: tipo, value: puntos) in esperadas.entries) {
      test('${tipo.name} puntúa ${puntos.join(', ')} en 1º, 2º y 3º', () {
        final zona = crear(tipo);

        expect(zona.calcularPuntuacion(1), puntos[0]);
        expect(zona.calcularPuntuacion(2), puntos[1]);
        expect(zona.calcularPuntuacion(3), puntos[2]);
        expect(zona.calcularPuntuacion(), puntos[0]);
      });
    }

    test('Rechaza posiciones distintas de 1, 2 o 3', () {
      final azul = crear(TipoZona.azul);

      expect(() => azul.calcularPuntuacion(0), throwsArgumentError);
      expect(() => azul.calcularPuntuacion(4), throwsArgumentError);
    });
  });
}
