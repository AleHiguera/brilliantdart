import 'package:brilliantdart/clasificacion.dart';
import 'package:brilliantdart/mapa_uno.dart';
import 'package:brilliantdart/puntuacion_multijugador.dart';
import 'package:test/test.dart';

List<(int, String, int)> resumen(Clasificacion clasificacion) => [
  for (final puesto in clasificacion.puestos)
    (puesto.lugar, puesto.jugador, puesto.puntos),
];

void main() {
  group('Clasificación final', () {
    test('El ganador es primero y los demás van de mayor a menor', () {
      final clasificacion = Clasificacion(
        puntos: {'ana': 12, 'luis': 27, 'eva': 20},
        jugadores: ['ana', 'luis', 'eva'],
      );

      expect(resumen(clasificacion), [
        (1, 'luis', 27),
        (2, 'eva', 20),
        (3, 'ana', 12),
      ]);
    });

    test('Los empatados comparten el lugar', () {
      final clasificacion = Clasificacion(
        puntos: {'ana': 20, 'luis': 27, 'eva': 20, 'sol': 9},
        jugadores: ['ana', 'luis', 'eva', 'sol'],
      );

      expect(resumen(clasificacion), [
        (1, 'luis', 27),
        (2, 'ana', 20),
        (2, 'eva', 20),
        (3, 'sol', 9),
      ]);
    });

    test('Un empate en primero da dos ganadores y el siguiente es 2.º', () {
      final clasificacion = Clasificacion(
        puntos: {'ana': 26, 'luis': 26, 'eva': 10},
        jugadores: ['ana', 'luis', 'eva'],
      );

      expect(resumen(clasificacion), [
        (1, 'ana', 26),
        (1, 'luis', 26),
        (2, 'eva', 10),
      ]);
    });

    test('Pueden empatar tres o más', () {
      final clasificacion = Clasificacion(
        puntos: {'a': 26, 'b': 8, 'c': 8, 'd': 8},
        jugadores: ['a', 'b', 'c', 'd'],
      );

      expect(clasificacion.puestos.map((puesto) => puesto.lugar), [1, 2, 2, 2]);
    });

    test('Con los mismos puntos se respeta el orden de llegada', () {
      final clasificacion = Clasificacion(
        puntos: {'eva': 8, 'ana': 8},
        jugadores: ['ana', 'luis', 'eva'],
      );

      expect(clasificacion.puestos.map((puesto) => puesto.jugador), [
        'ana',
        'eva',
        'luis',
      ]);
    });

    test('Quien no completó ninguna zona queda al final con 0', () {
      final clasificacion = Clasificacion(
        puntos: {'ana': 26},
        jugadores: ['ana', 'luis'],
      );

      expect(resumen(clasificacion), [(1, 'ana', 26), (2, 'luis', 0)]);
    });

    test('Quien salió conserva su lugar según sus puntos', () {
      final clasificacion = Clasificacion(
        puntos: {'ana': 26, 'luis': 14, 'eva': 3},
        jugadores: ['ana', 'eva'],
      );

      expect(resumen(clasificacion), [
        (1, 'ana', 26),
        (2, 'luis', 14),
        (3, 'eva', 3),
      ]);
      expect(
        clasificacion.puestos.where((puesto) => puesto.salio).single.jugador,
        'luis',
      );
    });

    test('Quien salió sin puntos no aparece', () {
      final clasificacion = Clasificacion(
        puntos: {'ana': 26},
        jugadores: ['ana'],
      );

      expect(clasificacion.puestos.map((puesto) => puesto.jugador), ['ana']);
    });

    group('Ejemplos de la especificación', () {
      test('A: tres jugadores, gana quien llegó a 24', () {
        final clasificacion = Clasificacion(
          puntos: {'jugador1': 24, 'jugador2': 21, 'jugador3': 17},
          jugadores: ['jugador1', 'jugador2', 'jugador3'],
        );

        expect(resumen(clasificacion), [
          (1, 'jugador1', 24),
          (2, 'jugador2', 21),
          (3, 'jugador3', 17),
        ]);
      });

      test('B: cinco jugadores, gana quien llegó a 20', () {
        final clasificacion = Clasificacion(
          puntos: {
            'jugador1': 19,
            'jugador2': 13,
            'jugador3': 20,
            'jugador4': 16,
            'jugador5': 10,
          },
          jugadores: [
            'jugador1',
            'jugador2',
            'jugador3',
            'jugador4',
            'jugador5',
          ],
        );

        expect(resumen(clasificacion), [
          (1, 'jugador3', 20),
          (2, 'jugador1', 19),
          (3, 'jugador4', 16),
          (4, 'jugador2', 13),
          (5, 'jugador5', 10),
        ]);
      });
    });

    test('Sabe el lugar de cada jugador', () {
      final clasificacion = Clasificacion(
        puntos: {'ana': 20, 'luis': 27, 'eva': 20},
        jugadores: ['ana', 'luis', 'eva'],
      );

      expect(clasificacion.lugarDe('luis'), 1);
      expect(clasificacion.lugarDe('eva'), 2);
      expect(clasificacion.lugarDe('nadie'), isNull);
      expect(clasificacion.lugarDe(null), isNull);
    });

    test('Se arma con los puntos que dan las zonas', () {
      // Mapa 1: zona 1 amarilla (8, 6, 4), zona 3 azul (7, 5, 3).
      final puntos = const PuntuacionMultijugador(mapaUno, {
        1: {'ana': 1, 'luis': 2},
        3: {'luis': 1, 'eva': 1},
      }).puntos;

      final clasificacion = Clasificacion(
        puntos: puntos,
        jugadores: ['ana', 'luis', 'eva'],
      );

      expect(resumen(clasificacion), [
        (1, 'luis', 13),
        (2, 'ana', 8),
        (3, 'eva', 7),
      ]);
    });
  });

  group('Ganar por abandono', () {
    test('Quien se quedó va primero aunque tenga menos puntos', () {
      final clasificacion = Clasificacion(
        puntos: {'ana': 4, 'luis': 12, 'eva': 7},
        jugadores: ['ana'],
        ganadores: ['ana'],
      );

      expect(resumen(clasificacion), [
        (1, 'ana', 4),
        (2, 'luis', 12),
        (3, 'eva', 7),
      ]);
    });

    test('Los que salieron siguen en la lista, marcados como fuera', () {
      final clasificacion = Clasificacion(
        puntos: {'luis': 6},
        jugadores: ['ana'],
        ganadores: ['ana'],
      );

      expect(clasificacion.puestos.map((p) => (p.jugador, p.salio)), [
        ('ana', false),
        ('luis', true),
      ]);
    });

    test('Ganar sin puntos también va primero', () {
      final clasificacion = Clasificacion(
        puntos: {'luis': 6, 'eva': 6},
        jugadores: ['ana'],
        ganadores: ['ana'],
      );

      expect(resumen(clasificacion), [
        (1, 'ana', 0),
        (2, 'luis', 6),
        (2, 'eva', 6),
      ]);
      expect(clasificacion.lugarDe('ana'), 1);
    });

    test('Si los ganadores son los de más puntos, nada cambia', () {
      for (final (puntos, ganadores) in [
        ({'ana': 26, 'luis': 20, 'eva': 20, 'leo': 3}, ['ana']),
        ({'ana': 26, 'luis': 26, 'eva': 10}, ['ana', 'luis']),
        ({'ana': 8, 'luis': 0}, ['ana']),
      ]) {
        final jugadores = puntos.keys.toList();
        expect(
          resumen(
            Clasificacion(
              puntos: puntos,
              jugadores: jugadores,
              ganadores: ganadores,
            ),
          ),
          resumen(Clasificacion(puntos: puntos, jugadores: jugadores)),
          reason: '$puntos',
        );
      }
    });
  });
}
