import 'package:test/test.dart';

import 'package:brilliantdart/tablero.dart';
import 'package:brilliantdart/tipoo.dart';
import 'package:brilliantdart/zona.dart';

void main() {
  group('Celdas del tablero', () {
    test('Tiene 7 filas y 7 columnas', () {
      expect(Tablero.filas, 7);
      expect(Tablero.columnas, 7);
    });

    test('Tiene 49 celdas', () {
      expect(Tablero().celdas, hasLength(49));
    });

    test('Todas las celdas tienen una posición diferente', () {
      final posiciones =
          Tablero().celdas.map((celda) => (celda.x, celda.y)).toSet();

      expect(posiciones, hasLength(49));
    });

    test('Un tablero nuevo está completamente vacío', () {
      final tablero = Tablero();

      expect(tablero.celdas.every((celda) => celda.valor == null), isTrue);
      expect(tablero.valoresColocados, isEmpty);
      expect(tablero.estaLleno, isFalse);
    });

    test('Un tablero nuevo no tiene regiones ni puntos', () {
      final tablero = Tablero();

      expect(tablero.regiones, isEmpty);
      expect(tablero.puntuacionTotal, 0);
    });

    test('obtenerCelda devuelve la celda de esa fila y columna', () {
      final tablero = Tablero();

      for (var fila = 0; fila < 7; fila++) {
        for (var columna = 0; columna < 7; columna++) {
          final celda = tablero.obtenerCelda(fila, columna);
          expect((celda.x, celda.y), (fila, columna));
        }
      }
    });

    test('obtenerCelda devuelve siempre la misma celda', () {
      final tablero = Tablero();

      expect(
        identical(tablero.obtenerCelda(2, 3), tablero.obtenerCelda(2, 3)),
        isTrue,
      );
    });

    test('Rechaza filas o columnas fuera del tablero', () {
      final tablero = Tablero();

      for (final (fila, columna) in [(-1, 0), (0, -1), (7, 0), (0, 7), (9, 9)]) {
        expect(() => tablero.obtenerCelda(fila, columna), throwsRangeError);
        expect(() => tablero.colocarDato(fila, columna, 1), throwsRangeError);
        expect(
          () => tablero.obtenerPosicionesAdyacentes(fila, columna),
          throwsRangeError,
        );
      }
    });

    test('colocarDato guarda el número en la celda', () {
      final tablero = Tablero()..colocarDato(4, 2, 6);

      expect(tablero.obtenerCelda(4, 2).valor, 6);
    });

    test('colocarDato con null vacía la celda', () {
      final tablero = Tablero()
        ..colocarDato(4, 2, 6)
        ..colocarDato(4, 2, null);

      expect(tablero.obtenerCelda(4, 2).valor, isNull);
    });

    test('colocarDato no toca las demás celdas', () {
      final tablero = Tablero()..colocarDato(1, 1, 3);

      final ocupadas = tablero.celdas.where((celda) => celda.valor != null);
      expect(ocupadas, hasLength(1));
    });

    test('valoresColocados no repite números', () {
      final tablero = Tablero()
        ..colocarDato(0, 0, 2)
        ..colocarDato(0, 1, 2)
        ..colocarDato(0, 2, 5);

      expect(tablero.valoresColocados, {2, 5});
    });

    test('extraerDatos devuelve 49 valores', () {
      expect(Tablero().extraerDatos(), hasLength(49));
    });

    test('extraerDatos de un tablero vacío son todos null', () {
      expect(Tablero().extraerDatos().every((dato) => dato == null), isTrue);
    });
  });

  group('Vecinas de una celda', () {
    test('Las esquinas tienen 2 vecinas', () {
      final tablero = Tablero();

      for (final (fila, columna) in [(0, 0), (0, 6), (6, 0), (6, 6)]) {
        expect(tablero.obtenerPosicionesAdyacentes(fila, columna), hasLength(2));
      }
    });

    test('Los bordes sin esquina tienen 3 vecinas', () {
      final tablero = Tablero();

      for (final (fila, columna) in [(0, 3), (3, 0), (6, 3), (3, 6)]) {
        expect(tablero.obtenerPosicionesAdyacentes(fila, columna), hasLength(3));
      }
    });

    test('Las celdas interiores tienen 4 vecinas', () {
      final tablero = Tablero();

      for (var fila = 1; fila < 6; fila++) {
        for (var columna = 1; columna < 6; columna++) {
          expect(
            tablero.obtenerPosicionesAdyacentes(fila, columna),
            hasLength(4),
          );
        }
      }
    });

    test('En total hay 168 relaciones de vecindad', () {
      final tablero = Tablero();
      var total = 0;
      for (final celda in tablero.celdas) {
        total += tablero.obtenerPosicionesAdyacentes(celda.x, celda.y).length;
      }

      expect(total, 168);
    });

    test('Las vecinas nunca incluyen la propia celda ni diagonales', () {
      final tablero = Tablero();

      for (final celda in tablero.celdas) {
        for (final vecina
            in tablero.obtenerPosicionesAdyacentes(celda.x, celda.y)) {
          final distancia =
              (celda.x - vecina.x).abs() + (celda.y - vecina.y).abs();
          expect(distancia, 1);
        }
      }
    });

    test('Si A es vecina de B, B es vecina de A', () {
      final tablero = Tablero();

      for (final celda in tablero.celdas) {
        for (final vecina
            in tablero.obtenerPosicionesAdyacentes(celda.x, celda.y)) {
          expect(
            tablero.obtenerPosicionesAdyacentes(vecina.x, vecina.y),
            contains(celda),
          );
        }
      }
    });
  });

  group('Regiones del tablero', () {
    Zona zonaVerde(Tablero tablero, int id, List<(int, int)> posiciones) {
      return Zona(
        id: id,
        tipo: Tipo(
          tipo: TipoZona.verde,
          color: 'Verde',
          regla: 'Libre',
          puntuacion: 4,
        ),
        coordenadas: [
          for (final (fila, columna) in posiciones)
            tablero.obtenerCelda(fila, columna),
        ],
      );
    }

    test('agregarRegion la añade a la lista', () {
      final tablero = Tablero();
      final zona = zonaVerde(tablero, 1, [(0, 0)]);

      tablero.agregarRegion(zona);

      expect(tablero.regiones, [zona]);
    });

    test('Puede tener varias regiones con ids distintos', () {
      final tablero = Tablero()
        ..agregarRegion(zonaVerde(Tablero(), 1, [(0, 0)]))
        ..agregarRegion(zonaVerde(Tablero(), 2, [(0, 1)]));

      expect(tablero.regiones.map((zona) => zona.id), [1, 2]);
    });

    test('obtenerCeldasDeRegion devuelve las celdas de la región', () {
      final tablero = Tablero();
      final zona = zonaVerde(tablero, 1, [(0, 0), (0, 1)]);
      tablero.agregarRegion(zona);

      expect(
        tablero.obtenerCeldasDeRegion(zona).map((c) => (c.x, c.y)).toList(),
        [(0, 0), (0, 1)],
      );
    });

    test('Una región verde llena suma sus puntos al tablero', () {
      final tablero = Tablero();
      tablero.agregarRegion(zonaVerde(tablero, 1, [(0, 0), (0, 1)]));

      tablero
        ..colocarDato(0, 0, 3)
        ..colocarDato(0, 1, 3);

      expect(tablero.puntuacionTotal, 4);
      expect(tablero.zonasCompletadasPorTipo(TipoZona.verde), 1);
    });

    test('Una celda sin región no se puede usar en el juego', () {
      final tablero = Tablero();
      tablero.agregarRegion(zonaVerde(tablero, 1, [(0, 0)]));

      expect(tablero.puedeColocarDato(0, 0, 1), isTrue);
      expect(tablero.puedeColocarDato(5, 5, 1), isFalse);
    });
  });
}
