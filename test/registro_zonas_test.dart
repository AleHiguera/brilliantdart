// Prueba unitaria: el historial de quién llenó cada zona, con su lugar y sus
// puntos, en el orden en que se muestra.

import 'package:brilliantdart/mapa_uno.dart';
import 'package:brilliantdart/puntuacion_multijugador.dart';
import 'package:brilliantdart/registro_zonas.dart';
import 'package:test/test.dart';

List<ZonaLograda> entradas(Map<int, Map<String, int>> rondas) =>
    RegistroZonas(PuntuacionMultijugador(mapaUno, rondas)).entradas;

void main() {
  // Mapa 1: la zona 1 es amarilla (8, 6, 4 puntos).
  final amarilla = mapaUno.crearTablero().regiones.firstWhere(
    (region) => region.id == 1,
  );

  group('Registro de zonas', () {
    test('Sin zonas llenas está vacío', () {
      expect(entradas({}), isEmpty);
    });

    test('Cada uno con su lugar y sus puntos', () {
      final registro = entradas({
        1: {'ana': 1, 'luis': 2, 'eva': 3, 'leo': 4},
      });

      expect(
        {for (final e in registro) e.jugador: (e.lugar, e.puntos)},
        {'ana': (1, 8), 'luis': (2, 6), 'eva': (3, 4), 'leo': (4, 0)},
      );
    });

    test('Los de la misma ronda comparten lugar', () {
      final registro = entradas({
        1: {'ana': 2, 'luis': 2, 'eva': 3},
      });

      expect(
        {for (final e in registro) e.jugador: e.lugar},
        {'ana': 1, 'luis': 1, 'eva': 2},
      );
    });

    test('Lo más reciente va primero', () {
      final registro = entradas({
        1: {'ana': 1},
        3: {'luis': 4},
        5: {'eva': 2},
      });

      expect(registro.map((e) => e.ronda), [4, 2, 1]);
    });

    test('En la misma ronda, por zona y luego por lugar', () {
      final registro = entradas({
        3: {'ana': 2},
        1: {'luis': 1, 'eva': 2},
      });

      expect(registro.map((e) => (e.zona, e.jugador)), [
        (1, 'eva'),
        (3, 'ana'),
        (1, 'luis'),
      ]);
    });

    test('Dice de qué color es la zona y en qué ronda se llenó', () {
      final registro = entradas({
        1: {'ana': 3},
      });

      expect(registro.single.tipo, amarilla.tipo.tipo);
      expect(registro.single.ronda, 3);
      expect(registro.single.zona, 1);
    });

    test('Quien salió de la partida sigue en el registro', () {
      // El registro no sabe quién sigue: lo que el servidor guardó, se muestra.
      expect(
        entradas({
          1: {'ya_se_fue': 1},
        }).single.jugador,
        'ya_se_fue',
      );
    });
  });
}
