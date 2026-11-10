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
}
