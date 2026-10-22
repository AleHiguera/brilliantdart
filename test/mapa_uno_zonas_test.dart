import 'package:test/test.dart';

import 'package:brilliantdart/mapa_uno.dart';
import 'package:brilliantdart/tipoo.dart';

void main() {
  group('Colores del mapa uno', () {
    test('El dibujo del mapa es de 7 por 7', () {
      expect(mapaUno.tiposPorCelda, hasLength(7));
      for (final fila in mapaUno.tiposPorCelda) {
        expect(fila, hasLength(7));
      }
    });

    int celdasDe(TipoZona tipo) => mapaUno.tiposPorCelda
        .expand((fila) => fila)
        .where((celda) => celda == tipo)
        .length;

    test(
      'Tiene 5 celdas amarillas',
      () => expect(celdasDe(TipoZona.amarillo), 5),
    );
    test('Tiene 12 celdas verdes', () => expect(celdasDe(TipoZona.verde), 12));
    test('Tiene 8 celdas azules', () => expect(celdasDe(TipoZona.azul), 8));
    test(
      'Tiene 12 celdas moradas',
      () => expect(celdasDe(TipoZona.morado), 12),
    );
    test('Tiene 12 celdas rojas', () => expect(celdasDe(TipoZona.rojo), 12));

    test('Las celdas de todos los colores suman 49', () {
      expect(TipoZona.values.map(celdasDe).reduce((a, b) => a + b), 49);
    });

    test('Las cuatro esquinas son amarillas', () {
      for (final (fila, columna) in [(0, 0), (0, 6), (6, 0), (6, 6)]) {
        expect(mapaUno.tiposPorCelda[fila][columna], TipoZona.amarillo);
      }
    });

    test('El centro es amarillo', () {
      expect(mapaUno.tiposPorCelda[3][3], TipoZona.amarillo);
    });

    test('Las celdas iniciales tienen el color esperado', () {
      const esperados = [
        TipoZona.azul,
        TipoZona.morado,
        TipoZona.rojo,
        TipoZona.verde,
        TipoZona.morado,
        TipoZona.rojo,
      ];
      for (var i = 0; i < 6; i++) {
        final (fila, columna) = mapaUno.celdasIniciales[i];
        expect(mapaUno.tiposPorCelda[fila - 1][columna - 1], esperados[i]);
      }
    });
  });

  group('Zonas del mapa uno', () {
    test('Las zonas tienen ids del 1 al 9 sin repetir', () {
      final ids = mapaUno.crearTablero().regiones.map((zona) => zona.id);

      expect(ids.toList()..sort(), [1, 2, 3, 4, 5, 6, 7, 8, 9]);
    });

    test('Tamaños: dos azules de 4, una amarilla de 5 y el resto de 6', () {
      final tamanos =
          mapaUno
              .crearTablero()
              .regiones
              .map((zona) => zona.tamanoRegion)
              .toList()
            ..sort();

      expect(tamanos, [4, 4, 5, 6, 6, 6, 6, 6, 6]);
    });

    test('Las zonas azules tienen 4 celdas', () {
      for (final zona in mapaUno.crearTablero().regiones.where(
        (zona) => zona.tipo.tipo == TipoZona.azul,
      )) {
        expect(zona.tamanoRegion, 4);
      }
    });

    test('Ninguna zona empieza completada', () {
      for (final zona in mapaUno.crearTablero().regiones) {
        expect(zona.completado, isFalse);
      }
    });

    test('Cada celda pertenece a exactamente una zona', () {
      final tablero = mapaUno.crearTablero();

      for (final celda in tablero.celdas) {
        final zonas = tablero.regiones.where(
          (zona) => zona.contieneCoordenada(celda.x, celda.y),
        );
        expect(zonas, hasLength(1), reason: '(${celda.x}, ${celda.y})');
      }
    });

    test('Las zonas usan las mismas celdas que el tablero', () {
      final tablero = mapaUno.crearTablero();

      for (final zona in tablero.regiones) {
        for (final celda in zona.coordenadas) {
          expect(
            identical(celda, tablero.obtenerCelda(celda.x, celda.y)),
            isTrue,
          );
        }
      }
    });

    test('Cada zona tiene un texto de regla', () {
      for (final zona in mapaUno.crearTablero().regiones) {
        expect(zona.tipo.regla, isNotEmpty);
        expect(zona.tipo.color, isNotEmpty);
      }
    });

    test('Los nombres de los colores están en español', () {
      final nombres = mapaUno
          .crearTablero()
          .regiones
          .map((zona) => zona.tipo.color)
          .toSet();

      expect(nombres, {'Azul', 'Rojo', 'Verde', 'Amarillo', 'Morado'});
    });

    test('La suma de puntos posibles del mapa es 54', () {
      final maximo = mapaUno.crearTablero().regiones.fold(
        0,
        (total, zona) => total + zona.tipo.puntuacion,
      );

      expect(maximo, 54);
    });

    test('Escribir en una celda de la zona se ve en el tablero', () {
      final tablero = mapaUno.crearTablero();
      final celda = tablero.regiones.first.coordenadas.first;

      tablero.colocarDato(celda.x, celda.y, 4);

      expect(tablero.regiones.first.obtenerValores(), contains(4));
    });
  });
}
