import 'package:test/test.dart';

import 'package:brilliantdart/constructor_tablero.dart';
import 'package:brilliantdart/mapa.dart';
import 'package:brilliantdart/mapa_dos.dart';
import 'package:brilliantdart/mapa_uno.dart';
import 'package:brilliantdart/region.dart';
import 'package:brilliantdart/tablero.dart';
import 'package:brilliantdart/tipoo.dart';

/// Dibujo de prueba parecido al Mapa 3: todo verde, con un morado arriba
/// (fila 0) y dos morados abajo (fila 6) separados por un gris.
List<List<TipoZona>> dibujoConMorados() => List.generate(7, (fila) {
  if (fila == 0) {
    return List.generate(
      7,
      (columna) =>
          columna >= 2 && columna <= 4 ? TipoZona.morado : TipoZona.verde,
    );
  }
  if (fila == 6) {
    return List.generate(
      7,
      (columna) => columna == 3 ? TipoZona.gris : TipoZona.morado,
    );
  }
  return List.filled(7, TipoZona.verde);
});

Tipo tipoDePrueba(TipoZona tipo) =>
    Tipo(tipo: tipo, color: tipo.name, regla: 'regla', puntuacion: 5);

Tablero construir({
  List<List<(int, int)>> partes = const [],
  Set<TipoZona> unidos = const {},
}) => ConstructorTablero(
  tiposPorCelda: dibujoConMorados(),
  crearTipo: tipoDePrueba,
  tiposUnidos: unidos,
  partesUnidas: partes,
).construir();

List<Set<(int, int)>> moradas(Tablero tablero) => [
  for (final Region zona in tablero.regiones)
    if (zona.tipo.tipo == TipoZona.morado)
      zona.coordenadas.map((celda) => (celda.x, celda.y)).toSet(),
];

/// Mapa de prueba que une los dos morados de abajo con partesUnidas.
class MapaConPartes extends Mapa {
  const MapaConPartes();

  @override
  int get numero => 98;

  @override
  List<List<TipoZona>> get tiposPorCelda => dibujoConMorados();

  @override
  List<(int, int)> get celdasIniciales => const [
    (2, 1),
    (2, 3),
    (2, 5),
    (4, 1),
    (4, 3),
    (4, 5),
  ];

  @override
  Set<TipoZona> get tiposUnidos => const {};

  // Filas y columnas desde 1: (7, 1) y (7, 5).
  @override
  List<List<(int, int)>> get partesUnidas => const [
    [(7, 1), (7, 5)],
  ];

  @override
  Tipo crearTipo(TipoZona tipo) => tipoDePrueba(tipo);
}

void main() {
  group('Partes unidas: pedazos sueltos que son una sola zona', () {
    test('Sin partes unidas hay 3 zonas moradas', () {
      expect(moradas(construir()), hasLength(3));
    });

    test('Uniendo los dos morados de abajo quedan 2 zonas moradas', () {
      final zonas = moradas(
        construir(
          partes: [
            [(6, 0), (6, 4)],
          ],
        ),
      );

      expect(zonas, hasLength(2));
    });

    test('El morado de arriba queda aparte', () {
      final zonas = moradas(
        construir(
          partes: [
            [(6, 0), (6, 4)],
          ],
        ),
      );

      expect(zonas, contains(equals({(0, 2), (0, 3), (0, 4)})));
    });

    test('La zona unida tiene las 6 celdas de los dos pedazos', () {
      final zonas = moradas(
        construir(
          partes: [
            [(6, 0), (6, 4)],
          ],
        ),
      );

      expect(
        zonas,
        contains(equals({(6, 0), (6, 1), (6, 2), (6, 4), (6, 5), (6, 6)})),
      );
    });

    test('Basta con cualquier celda de cada pedazo', () {
      final porLaOrilla = moradas(
        construir(
          partes: [
            [(6, 0), (6, 6)],
          ],
        ),
      );
      final porElCentro = moradas(
        construir(
          partes: [
            [(6, 1), (6, 5)],
          ],
        ),
      );

      expect(porLaOrilla.toSet(), porElCentro.toSet());
    });

    test('El orden de las celdas del grupo no importa', () {
      final ida = moradas(
        construir(
          partes: [
            [(6, 0), (6, 4)],
          ],
        ),
      );
      final vuelta = moradas(
        construir(
          partes: [
            [(6, 4), (6, 0)],
          ],
        ),
      );

      expect(ida.toSet(), vuelta.toSet());
    });

    test('Se pueden unir los tres pedazos en un mismo grupo', () {
      final zonas = moradas(
        construir(
          partes: [
            [(0, 2), (6, 0), (6, 4)],
          ],
        ),
      );

      expect(zonas, hasLength(1));
      expect(zonas.single, hasLength(9));
    });

    test('Dos celdas del mismo pedazo no cambian nada', () {
      final zonas = moradas(
        construir(
          partes: [
            [(6, 0), (6, 1)],
          ],
        ),
      );

      expect(zonas, hasLength(3));
    });

    test('Los demás colores no cambian', () {
      final normal = construir();
      final unido = construir(
        partes: [
          [(6, 0), (6, 4)],
        ],
      );

      for (final tipo in [TipoZona.verde, TipoZona.gris]) {
        expect(
          unido.regiones.where((zona) => zona.tipo.tipo == tipo).length,
          normal.regiones.where((zona) => zona.tipo.tipo == tipo).length,
        );
      }
    });

    test('Todas las celdas siguen en exactamente una zona', () {
      final tablero = construir(
        partes: [
          [(6, 0), (6, 4)],
        ],
      );
      final celdas = [
        for (final zona in tablero.regiones)
          for (final celda in zona.coordenadas) (celda.x, celda.y),
      ];

      expect(celdas, hasLength(49));
      expect(celdas.toSet(), hasLength(49));
    });

    test('La regla se aplica a los dos pedazos juntos', () {
      final tablero = construir(
        partes: [
          [(6, 0), (6, 4)],
        ],
      );
      // Morado: exactamente dos números distintos en toda la zona.
      tablero
        ..colocarDato(6, 0, 1)
        ..colocarDato(6, 1, 2);

      expect(tablero.puedeColocarDato(6, 5, 3), isFalse);
      expect(tablero.puedeColocarDato(6, 5, 1), isTrue);
    });

    test('Completar los dos pedazos suma los puntos una sola vez', () {
      final tablero = construir(
        partes: [
          [(6, 0), (6, 4)],
        ],
      );
      for (final columna in [0, 1, 2, 4, 5, 6]) {
        tablero.colocarDato(6, columna, columna.isEven ? 1 : 2);
      }

      expect(tablero.zonasCompletadasPorTipo(TipoZona.morado), 1);
      expect(tablero.puntuacionPorTipo(TipoZona.morado), 5);
    });

    test('Llenar solo un pedazo no completa la zona', () {
      final tablero = construir(
        partes: [
          [(6, 0), (6, 4)],
        ],
      );
      for (final columna in [0, 1, 2]) {
        tablero.colocarDato(6, columna, columna == 0 ? 1 : 2);
      }

      expect(tablero.zonasCompletadasPorTipo(TipoZona.morado), 0);
    });

    test('Funciona junto con un color unido (gris)', () {
      final tablero = construir(
        partes: [
          [(6, 0), (6, 4)],
        ],
        unidos: {TipoZona.gris},
      );

      expect(moradas(tablero), hasLength(2));
      expect(
        tablero.regiones.where((zona) => zona.tipo.tipo == TipoZona.gris),
        hasLength(1),
      );
    });
  });

  group('Partes unidas: grupos inválidos', () {
    test('Un grupo de una sola celda es un error', () {
      expect(
        () => construir(
          partes: [
            [(6, 0)],
          ],
        ),
        throwsArgumentError,
      );
    });

    test('Un grupo vacío es un error', () {
      expect(() => construir(partes: [[]]), throwsArgumentError);
    });

    test('Celdas de colores distintos es un error', () {
      expect(
        () => construir(
          partes: [
            [(6, 0), (3, 3)],
          ],
        ),
        throwsArgumentError,
      );
    });

    test('Una celda fuera del tablero es un error', () {
      expect(
        () => construir(
          partes: [
            [(6, 0), (7, 4)],
          ],
        ),
        throwsRangeError,
      );
      expect(
        () => construir(
          partes: [
            [(-1, 0), (6, 4)],
          ],
        ),
        throwsRangeError,
      );
    });
  });

  group('Partes unidas desde un Mapa', () {
    const mapa = MapaConPartes();

    test('Los mapas 1 y 2 no tienen partes unidas', () {
      expect(mapaUno.partesUnidas, isEmpty);
      expect(mapaDos.partesUnidas, isEmpty);
    });

    test('El mapa da sus celdas desde 1 y se convierten bien', () {
      final zonas = moradas(mapa.crearTablero());

      expect(zonas, hasLength(2));
      expect(
        zonas,
        contains(equals({(6, 0), (6, 1), (6, 2), (6, 4), (6, 5), (6, 6)})),
      );
    });

    test('El Mapa 1 sigue con sus 9 zonas y el Mapa 2 con sus 10', () {
      expect(mapaUno.crearTablero().regiones, hasLength(9));
      expect(mapaDos.crearTablero().regiones, hasLength(10));
    });
  });
}
