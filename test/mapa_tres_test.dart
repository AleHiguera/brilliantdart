import 'package:test/test.dart';

import 'package:brilliantdart/bloc_valores_iniciales.dart';
import 'package:brilliantdart/mapa.dart';
import 'package:brilliantdart/mapa_dos.dart';
import 'package:brilliantdart/mapa_tres.dart';
import 'package:brilliantdart/mapa_uno.dart';
import 'package:brilliantdart/region.dart';
import 'package:brilliantdart/tablero.dart';
import 'package:brilliantdart/tipoo.dart';

void main() {
  /// Zonas de un color, con sus celdas contando filas y columnas desde 1.
  List<Set<(int, int)>> zonasDe(Tablero tablero, TipoZona tipo) => [
    for (final zona in tablero.regiones)
      if (zona.tipo.tipo == tipo)
        zona.coordenadas.map((celda) => (celda.x + 1, celda.y + 1)).toSet(),
  ];

  Region zonaEn(Tablero tablero, int fila, int columna) =>
      tablero.regiones.singleWhere(
        (zona) => zona.coordenadas.any(
          (celda) => celda.x == fila - 1 && celda.y == columna - 1,
        ),
      );

  /// Llena todo el tablero respetando la regla de cada color.
  void llenarRespetandoReglas(Tablero tablero) {
    for (final zona in tablero.regiones) {
      for (var indice = 0; indice < zona.coordenadas.length; indice++) {
        final numero = switch (zona.tipo.tipo) {
          TipoZona.azul || TipoZona.gris => 4,
          TipoZona.rojo || TipoZona.amarillo => indice + 1,
          TipoZona.verde => indice % 3 + 1,
          TipoZona.morado => indice == 0 ? 2 : 5,
        };
        final celda = zona.coordenadas[indice];
        tablero.colocarDato(celda.x, celda.y, numero);
      }
    }
  }

  group('Mapa 3: su descripción', () {
    test('mapaTres es un Mapa', () {
      expect(mapaTres, isA<Mapa>());
    });

    test('Es el mapa número 3', () {
      expect(mapaTres.numero, 3);
    });

    test('const MapaTres() es el mismo objeto que mapaTres', () {
      expect(identical(const MapaTres(), mapaTres), isTrue);
    });

    test('El dibujo es el del papel, fila por fila', () {
      const m = TipoZona.morado,
          g = TipoZona.gris,
          v = TipoZona.verde,
          a = TipoZona.amarillo,
          r = TipoZona.rojo,
          z = TipoZona.azul;

      expect(mapaTres.tiposPorCelda, [
        [a, a, m, g, m, a, a],
        [g, a, m, m, m, a, g],
        [r, r, r, m, r, r, r],
        [r, r, r, g, r, r, r],
        [v, z, z, z, z, z, v],
        [v, v, v, v, v, v, v],
        [m, m, m, g, m, m, m],
      ]);
    });

    test('El dibujo no se puede modificar desde fuera', () {
      expect(
        () => mapaTres.tiposPorCelda[0][0] = TipoZona.verde,
        throwsUnsupportedError,
      );
    });

    test('Es distinto a los mapas 1 y 2', () {
      expect(mapaTres.tiposPorCelda, isNot(mapaUno.tiposPorCelda));
      expect(mapaTres.tiposPorCelda, isNot(mapaDos.tiposPorCelda));
    });

    test('Usa los 6 colores', () {
      expect(mapaTres.tiposPresentes.toSet(), TipoZona.values.toSet());
    });

    test('Cuántas celdas tiene cada color', () {
      int celdasDe(TipoZona tipo) => mapaTres.tiposPorCelda
          .expand((fila) => fila)
          .where((celda) => celda == tipo)
          .length;

      expect(celdasDe(TipoZona.amarillo), 6);
      expect(celdasDe(TipoZona.morado), 12);
      expect(celdasDe(TipoZona.gris), 5);
      expect(celdasDe(TipoZona.rojo), 12);
      expect(celdasDe(TipoZona.verde), 9);
      expect(celdasDe(TipoZona.azul), 5);
    });

    test('Tiene sus 6 celdas iniciales', () {
      expect(mapaTres.celdasIniciales, [
        (2, 3),
        (2, 6),
        (4, 4),
        (5, 2),
        (5, 7),
        (7, 3),
      ]);
    });

    test('El amarillo y el gris van unidos; el morado no', () {
      expect(mapaTres.tiposUnidos, {TipoZona.amarillo, TipoZona.gris});
      expect(mapaTres.tiposUnidos, isNot(contains(TipoZona.morado)));
    });

    test('Solo se unen los dos morados de abajo', () {
      expect(mapaTres.partesUnidas, [
        [(7, 1), (7, 5)],
      ]);
    });

    test('Puntos: amarillo 7, morado 7, gris 8, rojo 6, verde 6 y azul 7', () {
      expect(mapaTres.crearTipo(TipoZona.amarillo).puntuacion, 7);
      expect(mapaTres.crearTipo(TipoZona.morado).puntuacion, 7);
      expect(mapaTres.crearTipo(TipoZona.gris).puntuacion, 8);
      expect(mapaTres.crearTipo(TipoZona.rojo).puntuacion, 6);
      expect(mapaTres.crearTipo(TipoZona.verde).puntuacion, 6);
      expect(mapaTres.crearTipo(TipoZona.azul).puntuacion, 7);
    });

    test('Cada color tiene la regla de su tipo', () {
      expect(mapaTres.crearTipo(TipoZona.morado), isA<TipoMorado>());
      expect(mapaTres.crearTipo(TipoZona.gris), isA<TipoGris>());
      expect(mapaTres.crearTipo(TipoZona.verde), isA<TipoVerde>());
      expect(mapaTres.crearTipo(TipoZona.amarillo), isA<TipoAmarillo>());
      expect(mapaTres.crearTipo(TipoZona.rojo), isA<TipoRojo>());
      expect(mapaTres.crearTipo(TipoZona.azul), isA<TipoAzul>());
    });
  });

  group('Mapa 3: sus zonas', () {
    late Tablero tablero;
    setUp(() => tablero = mapaTres.crearTablero());

    test('Tiene 8 zonas', () {
      expect(tablero.regiones, hasLength(8));
    });

    test('Cuántas zonas tiene cada color', () {
      expect(zonasDe(tablero, TipoZona.amarillo), hasLength(1));
      expect(zonasDe(tablero, TipoZona.morado), hasLength(2));
      expect(zonasDe(tablero, TipoZona.gris), hasLength(1));
      expect(zonasDe(tablero, TipoZona.rojo), hasLength(2));
      expect(zonasDe(tablero, TipoZona.verde), hasLength(1));
      expect(zonasDe(tablero, TipoZona.azul), hasLength(1));
    });

    test('Las zonas cubren las 49 celdas sin repetir ninguna', () {
      final celdas = [
        for (final zona in tablero.regiones)
          for (final celda in zona.coordenadas) (celda.x, celda.y),
      ];

      expect(celdas, hasLength(49));
      expect(celdas.toSet(), hasLength(49));
    });

    test('Los amarillos de las dos esquinas son una sola zona de 6', () {
      expect(zonasDe(tablero, TipoZona.amarillo).single, {
        (1, 1),
        (1, 2),
        (2, 2),
        (1, 6),
        (1, 7),
        (2, 6),
      });
    });

    test('Los 5 grises separados son una sola zona', () {
      expect(zonasDe(tablero, TipoZona.gris).single, {
        (1, 4),
        (2, 1),
        (2, 7),
        (4, 4),
        (7, 4),
      });
    });

    test('El morado de arriba es su propia zona de 6', () {
      expect(
        zonasDe(tablero, TipoZona.morado),
        contains(equals({(1, 3), (1, 5), (2, 3), (2, 4), (2, 5), (3, 4)})),
      );
    });

    test('Los dos morados de abajo son una sola zona de 6', () {
      expect(
        zonasDe(tablero, TipoZona.morado),
        contains(equals({(7, 1), (7, 2), (7, 3), (7, 5), (7, 6), (7, 7)})),
      );
    });

    test('El gris (7, 4) no pertenece a la zona morada de abajo', () {
      final moradaAbajo = zonaEn(tablero, 7, 1);

      expect(moradaAbajo.tipo.tipo, TipoZona.morado);
      expect(
        moradaAbajo.coordenadas.any((celda) => celda.x == 6 && celda.y == 3),
        isFalse,
      );
    });

    test('Rojo: una zona a la izquierda y otra a la derecha de 6 celdas', () {
      expect(zonasDe(tablero, TipoZona.rojo), [
        {(3, 1), (3, 2), (3, 3), (4, 1), (4, 2), (4, 3)},
        {(3, 5), (3, 6), (3, 7), (4, 5), (4, 6), (4, 7)},
      ]);
    });

    test('Verde: una zona de 9 celdas', () {
      expect(zonasDe(tablero, TipoZona.verde).single, {
        (5, 1),
        (5, 7),
        for (var columna = 1; columna <= 7; columna++) (6, columna),
      });
    });

    test('Azul: una zona de 5 celdas en la fila 5', () {
      expect(zonasDe(tablero, TipoZona.azul).single, {
        for (var columna = 2; columna <= 6; columna++) (5, columna),
      });
    });

    test('El máximo de puntos es 54', () {
      expect(tablero.puntuacionMaxima, 7 + 7 * 2 + 8 + 6 * 2 + 6 + 7);
      expect(tablero.puntuacionMaxima, 54);
    });

    test('Cada llamada a crearTablero da un tablero nuevo', () {
      tablero.colocarDato(0, 0, 3);

      expect(mapaTres.crearTablero().obtenerCelda(0, 0).valor, isNull);
    });

    test('Los mapas 1 y 2 no cambian', () {
      expect(mapaUno.crearTablero().regiones, hasLength(9));
      expect(mapaDos.crearTablero().regiones, hasLength(10));
    });
  });

  group('Mapa 3: celdas iniciales', () {
    test('Los colores de las celdas iniciales', () {
      expect(
        [
          for (final (fila, columna) in mapaTres.celdasIniciales)
            mapaTres.tipoEn(fila - 1, columna - 1),
        ],
        [
          TipoZona.morado,
          TipoZona.amarillo,
          TipoZona.gris,
          TipoZona.azul,
          TipoZona.verde,
          TipoZona.morado,
        ],
      );
    });

    test('Cada celda inicial cae en una zona distinta', () {
      final tablero = mapaTres.crearTablero();
      final zonas = {
        for (final (fila, columna) in mapaTres.celdasIniciales)
          zonaEn(tablero, fila, columna).id,
      };

      expect(zonas, hasLength(6));
    });

    test('La (7, 3) es inicial y está en la zona morada de abajo', () {
      final tablero = mapaTres.crearTablero();

      expect(mapaTres.celdasIniciales, contains((7, 3)));
      expect(mapaTres.celdasIniciales, isNot(contains((6, 3))));
      expect(zonaEn(tablero, 7, 3), same(zonaEn(tablero, 7, 5)));
    });

    test('La (6, 3) ya no es inicial: el bloc la rechaza', () {
      final tablero = mapaTres.crearTablero();
      final bloc = BlocValoresIniciales(
        tablero,
        celdasIniciales: mapaTres.celdasIniciales,
      );

      expect(() => bloc.colocarValorInicial(6, 3, 1), throwsArgumentError);
      expect(tablero.obtenerCelda(5, 2).valor, isNull);

      bloc.colocarValorInicial(7, 3, 6);
      expect(tablero.obtenerCelda(6, 2).valor, 6);
    });

    test('El bloc acepta los 6 números en sus celdas iniciales', () {
      final tablero = mapaTres.crearTablero();
      final bloc = BlocValoresIniciales(
        tablero,
        celdasIniciales: mapaTres.celdasIniciales,
      );

      for (var i = 0; i < 6; i++) {
        final (fila, columna) = mapaTres.celdasIniciales[i];
        bloc.colocarValorInicial(fila, columna, i + 1);
      }

      expect(bloc.puedeIniciar, isTrue);
      expect(bloc.obtenerValoresIniciales(), [1, 2, 3, 4, 5, 6]);
    });

    test('El bloc rechaza celdas que no son iniciales en el Mapa 3', () {
      final bloc = BlocValoresIniciales(
        mapaTres.crearTablero(),
        celdasIniciales: mapaTres.celdasIniciales,
      );

      expect(() => bloc.colocarValorInicial(1, 1, 1), throwsArgumentError);
      expect(() => bloc.colocarValorInicial(7, 5, 1), throwsArgumentError);
    });
  });

  group('Mapa 3: reglas jugando', () {
    test('Los morados de abajo comparten la regla de dos números', () {
      final tablero = mapaTres.crearTablero()
        ..colocarDato(6, 0, 1)
        ..colocarDato(6, 6, 2);

      expect(tablero.puedeColocarDato(6, 4, 3), isFalse);
      expect(tablero.puedeColocarDato(6, 4, 1), isTrue);
      expect(tablero.puedeColocarDato(6, 2, 2), isTrue);
    });

    test('El morado de arriba no se ve afectado por el de abajo', () {
      final tablero = mapaTres.crearTablero()
        ..colocarDato(6, 0, 1)
        ..colocarDato(6, 6, 2);

      expect(tablero.puedeColocarDato(1, 2, 3), isTrue);
    });

    test('Completar los dos morados de abajo suma 7 una sola vez', () {
      final tablero = mapaTres.crearTablero();
      for (final columna in [0, 1, 2, 4, 5, 6]) {
        tablero.colocarDato(6, columna, columna < 3 ? 1 : 2);
      }

      expect(tablero.zonasCompletadasPorTipo(TipoZona.morado), 1);
      expect(tablero.puntuacionPorTipo(TipoZona.morado), 7);
    });

    test('Todos los grises deben llevar el mismo número', () {
      final tablero = mapaTres.crearTablero()..colocarDato(0, 3, 5);

      expect(tablero.puedeColocarDato(6, 3, 5), isTrue);
      expect(tablero.puedeColocarDato(6, 3, 4), isFalse);
      expect(tablero.puedeColocarDato(1, 0, 2), isFalse);
    });

    test('Completar los 5 grises iguales suma 8', () {
      final tablero = mapaTres.crearTablero();
      for (final (fila, columna) in [(0, 3), (1, 0), (1, 6), (3, 3), (6, 3)]) {
        tablero.colocarDato(fila, columna, 6);
      }

      expect(tablero.puntuacionPorTipo(TipoZona.gris), 8);
    });

    test('Un amarillo no repite el número de la otra esquina', () {
      final tablero = mapaTres.crearTablero()..colocarDato(0, 0, 3);

      expect(tablero.puedeColocarDato(0, 6, 3), isFalse);
      expect(tablero.puedeColocarDato(0, 6, 4), isTrue);
    });

    test('Llenar todo respetando las reglas da 54 puntos', () {
      final tablero = mapaTres.crearTablero();

      llenarRespetandoReglas(tablero);

      expect(tablero.estaLleno, isTrue);
      expect(tablero.puntuacionTotal, 54);
      expect(tablero.puntuacionPorTipo(TipoZona.amarillo), 7);
      expect(tablero.puntuacionPorTipo(TipoZona.morado), 14);
      expect(tablero.puntuacionPorTipo(TipoZona.gris), 8);
      expect(tablero.puntuacionPorTipo(TipoZona.rojo), 12);
      expect(tablero.puntuacionPorTipo(TipoZona.verde), 6);
      expect(tablero.puntuacionPorTipo(TipoZona.azul), 7);
      expect(tablero.regiones.every((zona) => zona.completado), isTrue);
    });
  });
}
