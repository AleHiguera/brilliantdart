import 'package:test/test.dart';

import 'package:brilliantdart/tipoo.dart';

void main() {
  Tipo crear(TipoZona tipo) =>
      Tipo(tipo: tipo, color: tipo.name, regla: 'regla', puntuacion: 1);

  group('Tipos de zona', () {
    test('Hay exactamente 7 colores', () {
      expect(TipoZona.values, hasLength(7));
    });

    test(
      'Los colores son azul, rojo, verde, amarillo, morado, gris y naranja',
      () {
        expect(TipoZona.values.map((tipo) => tipo.name).toSet(), {
          'azul',
          'rojo',
          'verde',
          'amarillo',
          'morado',
          'gris',
          'naranja',
        });
      },
    );

    for (final tipo in TipoZona.values) {
      group(tipo.name, () {
        test('recuerda qué color es', () {
          expect(crear(tipo).tipo, tipo);
        });

        test('tiene puntos para los lugares 1, 2 y 3', () {
          expect(crear(tipo).puntuaciones.keys.toSet(), {1, 2, 3});
        });

        test('el primer lugar vale más que el segundo y el tercero', () {
          final puntos = crear(tipo).puntuaciones;

          expect(puntos[1]!, greaterThan(puntos[2]!));
          expect(puntos[2]!, greaterThan(puntos[3]!));
        });

        test('todos los puntos son positivos', () {
          for (final puntos in crear(tipo).puntuaciones.values) {
            expect(puntos, greaterThan(0));
          }
        });

        test('acepta cualquier número en una zona vacía', () {
          for (var numero = 1; numero <= 6; numero++) {
            expect(crear(tipo).esPosibleAgregar([], numero), isTrue);
          }
        });

        test('esPosibleAgregar no modifica la lista recibida', () {
          final actuales = [2, 2];

          crear(tipo).esPosibleAgregar(actuales, 5);

          expect(actuales, [2, 2]);
        });

        test('obtenerInformacion tiene tres líneas', () {
          final lineas = crear(tipo).obtenerInformacion().trim().split('\n');

          expect(lineas, hasLength(3));
          expect(lineas[0], startsWith('Tipo: '));
          expect(lineas[1], startsWith('Regla: '));
          expect(lineas[2], startsWith('Puntuación: '));
        });
      });
    }
  });

  group('Cada número contra cada regla', () {
    test('Azul con [3] solo acepta el 3', () {
      final azul = crear(TipoZona.azul);
      for (var numero = 1; numero <= 6; numero++) {
        expect(
          azul.esPosibleAgregar([3], numero),
          numero == 3,
          reason: 'número $numero',
        );
      }
    });

    test('Rojo con [1, 4] acepta todo menos el 1 y el 4', () {
      final rojo = crear(TipoZona.rojo);
      for (var numero = 1; numero <= 6; numero++) {
        expect(
          rojo.esPosibleAgregar([1, 4], numero),
          numero != 1 && numero != 4,
          reason: 'número $numero',
        );
      }
    });

    test('Amarillo con [2, 3, 5] acepta solo el 1, 4 y 6', () {
      final amarillo = crear(TipoZona.amarillo);
      for (var numero = 1; numero <= 6; numero++) {
        expect(
          amarillo.esPosibleAgregar([2, 3, 5], numero),
          {1, 4, 6}.contains(numero),
          reason: 'número $numero',
        );
      }
    });

    test('Morado con [2, 6] solo acepta el 2 y el 6', () {
      final morado = crear(TipoZona.morado);
      for (var numero = 1; numero <= 6; numero++) {
        expect(
          morado.esPosibleAgregar([2, 6], numero),
          numero == 2 || numero == 6,
          reason: 'número $numero',
        );
      }
    });

    test('Morado con [4] acepta cualquier número', () {
      final morado = crear(TipoZona.morado);
      for (var numero = 1; numero <= 6; numero++) {
        expect(morado.esPosibleAgregar([4], numero), isTrue);
      }
    });

    test('Rojo con 1 al 5 solo acepta el 6', () {
      final rojo = crear(TipoZona.rojo);
      for (var numero = 1; numero <= 6; numero++) {
        expect(rojo.esPosibleAgregar([1, 2, 3, 4, 5], numero), numero == 6);
      }
    });

    test('Verde con seis números iguales sigue aceptando cualquiera', () {
      final verde = crear(TipoZona.verde);
      for (var numero = 1; numero <= 6; numero++) {
        expect(verde.esPosibleAgregar([5, 5, 5, 5, 5, 5], numero), isTrue);
      }
    });
  });

  group('Reglas al completar, caso por caso', () {
    test('Azul [6, 6, 6, 6] es válido', () {
      expect(crear(TipoZona.azul).validarMovimiento([6, 6, 6, 6]), isTrue);
    });

    test('Azul [6, 6, 6, 5] no es válido', () {
      expect(crear(TipoZona.azul).validarMovimiento([6, 6, 6, 5]), isFalse);
    });

    test('Rojo [6, 5, 4, 3, 2, 1] es válido', () {
      expect(
        crear(TipoZona.rojo).validarMovimiento([6, 5, 4, 3, 2, 1]),
        isTrue,
      );
    });

    test('Rojo [1, 2, 3, 4, 5, 5] no es válido', () {
      expect(
        crear(TipoZona.rojo).validarMovimiento([1, 2, 3, 4, 5, 5]),
        isFalse,
      );
    });

    test('Verde [1, 1, 1, 1, 1, 1] es válido', () {
      expect(
        crear(TipoZona.verde).validarMovimiento([1, 1, 1, 1, 1, 1]),
        isTrue,
      );
    });

    test('Morado [1, 1, 1, 1, 1, 2] es válido', () {
      expect(
        crear(TipoZona.morado).validarMovimiento([1, 1, 1, 1, 1, 2]),
        isTrue,
      );
    });

    test('Morado [1, 2, 1, 2, 1, 3] no es válido', () {
      expect(
        crear(TipoZona.morado).validarMovimiento([1, 2, 1, 2, 1, 3]),
        isFalse,
      );
    });

    test('Amarillo con cinco números distintos es válido', () {
      expect(
        crear(TipoZona.amarillo).validarMovimiento([6, 1, 5, 2, 4]),
        isTrue,
      );
    });
  });
}
