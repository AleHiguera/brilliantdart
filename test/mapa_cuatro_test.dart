import 'package:test/test.dart';

import 'package:brilliantdart/bloc_valores_iniciales.dart';
import 'package:brilliantdart/mapa.dart';
import 'package:brilliantdart/mapa_cuatro.dart';
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

  TipoNaranja naranjaEn(Tablero tablero, int fila) =>
      zonaEn(tablero, fila, 1).tipo as TipoNaranja;

  /// Llena todo el tablero respetando la regla de cada zona.
  void llenarRespetandoReglas(Tablero tablero) {
    for (final zona in tablero.regiones) {
      for (var indice = 0; indice < zona.coordenadas.length; indice++) {
        final numero = switch (zona.tipo.tipo) {
          TipoZona.azul || TipoZona.gris => 4,
          TipoZona.rojo || TipoZona.amarillo => indice + 1,
          TipoZona.verde => indice % 3 + 1,
          TipoZona.morado => indice == 0 ? 2 : 5,
          TipoZona.naranja => (zona.tipo as TipoNaranja).maximo,
        };
        final celda = zona.coordenadas[indice];
        tablero.colocarDato(celda.x, celda.y, numero);
      }
    }
  }

  group('Mapa 4: su descripción', () {
    test('mapaCuatro es un Mapa', () {
      expect(mapaCuatro, isA<Mapa>());
    });

    test('Es el mapa número 4', () {
      expect(mapaCuatro.numero, 4);
    });

    test('const MapaCuatro() es el mismo objeto que mapaCuatro', () {
      expect(identical(const MapaCuatro(), mapaCuatro), isTrue);
    });

    test('El dibujo es el del papel, fila por fila', () {
      const n = TipoZona.naranja,
          m = TipoZona.morado,
          v = TipoZona.verde,
          a = TipoZona.amarillo,
          r = TipoZona.rojo,
          z = TipoZona.azul;

      expect(mapaCuatro.tiposPorCelda, [
        [n, n, n, n, n, n, n],
        [a, r, z, v, z, r, a],
        [r, r, m, m, m, r, r],
        [a, v, z, m, z, v, a],
        [r, r, m, m, m, r, r],
        [a, r, z, v, z, r, a],
        [n, n, n, n, n, n, n],
      ]);
    });

    test('El dibujo es simétrico de izquierda a derecha', () {
      for (final fila in mapaCuatro.tiposPorCelda) {
        expect(fila, fila.reversed.toList());
      }
    });

    test('Es distinto a los otros mapas', () {
      for (final otro in [mapaUno, mapaDos, mapaTres]) {
        expect(mapaCuatro.tiposPorCelda, isNot(otro.tiposPorCelda));
      }
    });

    test('Usa naranja y no usa gris', () {
      expect(mapaCuatro.tiposPresentes, contains(TipoZona.naranja));
      expect(mapaCuatro.tiposPresentes, isNot(contains(TipoZona.gris)));
      expect(() => mapaCuatro.crearTipo(TipoZona.gris), throwsArgumentError);
    });

    test('Cuántas celdas tiene cada color', () {
      int celdasDe(TipoZona tipo) => mapaCuatro.tiposPorCelda
          .expand((fila) => fila)
          .where((celda) => celda == tipo)
          .length;

      expect(celdasDe(TipoZona.naranja), 14);
      expect(celdasDe(TipoZona.amarillo), 6);
      expect(celdasDe(TipoZona.rojo), 12);
      expect(celdasDe(TipoZona.azul), 6);
      expect(celdasDe(TipoZona.verde), 4);
      expect(celdasDe(TipoZona.morado), 7);
    });

    test('Tiene sus 6 celdas iniciales', () {
      expect(mapaCuatro.celdasIniciales, [
        (1, 5),
        (3, 3),
        (3, 6),
        (4, 1),
        (6, 5),
        (7, 2),
      ]);
    });

    test('Amarillo, azul y verde van unidos', () {
      expect(mapaCuatro.tiposUnidos, {
        TipoZona.amarillo,
        TipoZona.azul,
        TipoZona.verde,
      });
    });

    test('Se unen los rojos de cada lado', () {
      expect(mapaCuatro.partesUnidas, [
        [(3, 1), (5, 1)],
        [(3, 7), (5, 7)],
      ]);
    });

    test(
      'Puntos: amarillo 8, rojo 6, azul 8, verde 3, morado 7, naranja 6',
      () {
        expect(mapaCuatro.crearTipo(TipoZona.amarillo).puntuacion, 8);
        expect(mapaCuatro.crearTipo(TipoZona.rojo).puntuacion, 6);
        expect(mapaCuatro.crearTipo(TipoZona.azul).puntuacion, 8);
        expect(mapaCuatro.crearTipo(TipoZona.verde).puntuacion, 3);
        expect(mapaCuatro.crearTipo(TipoZona.morado).puntuacion, 7);
        expect(mapaCuatro.crearTipo(TipoZona.naranja).puntuacion, 6);
      },
    );

    test('Cada color tiene la regla de su tipo', () {
      expect(mapaCuatro.crearTipo(TipoZona.amarillo), isA<TipoAmarillo>());
      expect(mapaCuatro.crearTipo(TipoZona.rojo), isA<TipoRojo>());
      expect(mapaCuatro.crearTipo(TipoZona.azul), isA<TipoAzul>());
      expect(mapaCuatro.crearTipo(TipoZona.verde), isA<TipoVerde>());
      expect(mapaCuatro.crearTipo(TipoZona.morado), isA<TipoMorado>());
      expect(mapaCuatro.crearTipo(TipoZona.naranja), isA<TipoNaranja>());
    });

    test('El naranja de arriba es del 4 al 6 y el de abajo del 1 al 3', () {
      final arriba =
          mapaCuatro.crearTipoDeZona(TipoZona.naranja, const [(1, 1)])
              as TipoNaranja;
      final abajo =
          mapaCuatro.crearTipoDeZona(TipoZona.naranja, const [(7, 1)])
              as TipoNaranja;

      expect((arriba.minimo, arriba.maximo), (4, 6));
      expect((abajo.minimo, abajo.maximo), (1, 3));
      expect(arriba.puntuacion, abajo.puntuacion);
    });

    test('Los demás colores usan la regla de su color en cualquier zona', () {
      final tipo = mapaCuatro.crearTipoDeZona(TipoZona.morado, const [(3, 3)]);

      expect(tipo, isA<TipoMorado>());
      expect(tipo.puntuacion, 7);
    });
  });

  group('Mapa 4: sus zonas', () {
    late Tablero tablero;
    setUp(() => tablero = mapaCuatro.crearTablero());

    test('Tiene 8 zonas', () {
      expect(tablero.regiones, hasLength(8));
    });

    test('Cuántas zonas tiene cada color', () {
      expect(zonasDe(tablero, TipoZona.naranja), hasLength(2));
      expect(zonasDe(tablero, TipoZona.amarillo), hasLength(1));
      expect(zonasDe(tablero, TipoZona.rojo), hasLength(2));
      expect(zonasDe(tablero, TipoZona.azul), hasLength(1));
      expect(zonasDe(tablero, TipoZona.verde), hasLength(1));
      expect(zonasDe(tablero, TipoZona.morado), hasLength(1));
    });

    test('Las zonas cubren las 49 celdas sin repetir ninguna', () {
      final celdas = [
        for (final zona in tablero.regiones)
          for (final celda in zona.coordenadas) (celda.x, celda.y),
      ];

      expect(celdas, hasLength(49));
      expect(celdas.toSet(), hasLength(49));
    });

    test('Naranja: la fila 1 y la fila 7, cada una su zona de 7', () {
      expect(zonasDe(tablero, TipoZona.naranja), [
        {for (var columna = 1; columna <= 7; columna++) (1, columna)},
        {for (var columna = 1; columna <= 7; columna++) (7, columna)},
      ]);
    });

    test('Cada naranja tiene su rango en el tablero', () {
      expect(
        (naranjaEn(tablero, 1).minimo, naranjaEn(tablero, 1).maximo),
        (4, 6),
      );
      expect(
        (naranjaEn(tablero, 7).minimo, naranjaEn(tablero, 7).maximo),
        (1, 3),
      );
    });

    test('Los 6 amarillos de las orillas son una sola zona', () {
      expect(zonasDe(tablero, TipoZona.amarillo).single, {
        (2, 1),
        (2, 7),
        (4, 1),
        (4, 7),
        (6, 1),
        (6, 7),
      });
    });

    test('Los 6 azules sueltos son una sola zona', () {
      expect(zonasDe(tablero, TipoZona.azul).single, {
        (2, 3),
        (2, 5),
        (4, 3),
        (4, 5),
        (6, 3),
        (6, 5),
      });
    });

    test('Los 4 verdes sueltos son una sola zona', () {
      expect(zonasDe(tablero, TipoZona.verde).single, {
        (2, 4),
        (4, 2),
        (4, 6),
        (6, 4),
      });
    });

    test('Rojo: los 6 de la izquierda y los 6 de la derecha', () {
      expect(zonasDe(tablero, TipoZona.rojo), [
        {(2, 2), (3, 1), (3, 2), (5, 1), (5, 2), (6, 2)},
        {(2, 6), (3, 6), (3, 7), (5, 6), (5, 7), (6, 6)},
      ]);
    });

    test('Morado: una zona de 7 en el centro', () {
      expect(zonasDe(tablero, TipoZona.morado).single, {
        (3, 3),
        (3, 4),
        (3, 5),
        (4, 4),
        (5, 3),
        (5, 4),
        (5, 5),
      });
    });

    test('El máximo de puntos es 50', () {
      expect(tablero.puntuacionMaxima, 6 * 2 + 8 + 6 * 2 + 8 + 3 + 7);
      expect(tablero.puntuacionMaxima, 50);
    });

    test('Los otros mapas no cambian', () {
      expect(mapaUno.crearTablero().regiones, hasLength(9));
      expect(mapaDos.crearTablero().regiones, hasLength(10));
      expect(mapaTres.crearTablero().regiones, hasLength(8));
    });
  });

  group('Mapa 4: celdas iniciales', () {
    test('Los colores de las celdas iniciales', () {
      expect(
        [
          for (final (fila, columna) in mapaCuatro.celdasIniciales)
            mapaCuatro.tipoEn(fila - 1, columna - 1),
        ],
        [
          TipoZona.naranja,
          TipoZona.morado,
          TipoZona.rojo,
          TipoZona.amarillo,
          TipoZona.azul,
          TipoZona.naranja,
        ],
      );
    });

    test('Cada celda inicial cae en una zona distinta', () {
      final tablero = mapaCuatro.crearTablero();
      final zonas = {
        for (final (fila, columna) in mapaCuatro.celdasIniciales)
          zonaEn(tablero, fila, columna).id,
      };

      expect(zonas, hasLength(6));
    });

    test('La (1, 5) es del naranja alto y la (7, 2) del naranja bajo', () {
      final tablero = mapaCuatro.crearTablero();

      expect(zonaEn(tablero, 1, 5), same(zonaEn(tablero, 1, 1)));
      expect(zonaEn(tablero, 7, 2), same(zonaEn(tablero, 7, 1)));
    });

    test('El bloc acepta los 6 números en sus celdas iniciales', () {
      final tablero = mapaCuatro.crearTablero();
      final bloc = BlocValoresIniciales(
        tablero,
        celdasIniciales: mapaCuatro.celdasIniciales,
      );
      const valores = [6, 2, 3, 4, 5, 1];

      for (var i = 0; i < 6; i++) {
        final (fila, columna) = mapaCuatro.celdasIniciales[i];
        bloc.colocarValorInicial(fila, columna, valores[i]);
      }

      expect(bloc.puedeIniciar, isTrue);
      expect(bloc.obtenerValoresIniciales(), valores);
    });
  });

  group('Mapa 4: reglas jugando', () {
    test('El naranja de arriba solo acepta del 4 al 6', () {
      final tablero = mapaCuatro.crearTablero();

      for (final numero in [4, 5, 6]) {
        expect(tablero.puedeColocarDato(0, 0, numero), isTrue);
      }
      for (final numero in [1, 2, 3]) {
        expect(tablero.puedeColocarDato(0, 0, numero), isFalse);
      }
    });

    test('El naranja de abajo solo acepta del 1 al 3', () {
      final tablero = mapaCuatro.crearTablero();

      for (final numero in [1, 2, 3]) {
        expect(tablero.puedeColocarDato(6, 0, numero), isTrue);
      }
      for (final numero in [4, 5, 6]) {
        expect(tablero.puedeColocarDato(6, 0, numero), isFalse);
      }
    });

    test('Naranja de arriba con cuatro 4 y tres 6 suma 6', () {
      final tablero = mapaCuatro.crearTablero();
      for (var columna = 0; columna < 7; columna++) {
        tablero.colocarDato(0, columna, columna < 4 ? 4 : 6);
      }

      expect(tablero.puntuacionPorTipo(TipoZona.naranja), 6);
    });

    test('Naranja de abajo con solo 1 y 3 suma 6', () {
      final tablero = mapaCuatro.crearTablero();
      for (var columna = 0; columna < 7; columna++) {
        tablero.colocarDato(6, columna, columna.isEven ? 1 : 3);
      }

      expect(tablero.puntuacionPorTipo(TipoZona.naranja), 6);
    });

    test('Un número fuera de rango en el naranja no suma', () {
      final tablero = mapaCuatro.crearTablero();
      for (var columna = 0; columna < 7; columna++) {
        tablero.colocarDato(0, columna, columna == 6 ? 2 : 5);
      }

      expect(tablero.puntuacionPorTipo(TipoZona.naranja), 0);
    });

    test('Todos los azules deben ser iguales aunque estén separados', () {
      final tablero = mapaCuatro.crearTablero()..colocarDato(1, 2, 3);

      expect(tablero.puedeColocarDato(5, 4, 3), isTrue);
      expect(tablero.puedeColocarDato(5, 4, 2), isFalse);
    });

    test('Los rojos de arriba y abajo de un lado no repiten números', () {
      final tablero = mapaCuatro.crearTablero()..colocarDato(1, 1, 4);

      expect(tablero.puedeColocarDato(5, 1, 4), isFalse);
      expect(tablero.puedeColocarDato(5, 1, 1), isTrue);
      // El rojo del otro lado es otra zona.
      expect(tablero.puedeColocarDato(1, 5, 4), isTrue);
    });

    test('Llenar todo respetando las reglas da 50 puntos', () {
      final tablero = mapaCuatro.crearTablero();

      llenarRespetandoReglas(tablero);

      expect(tablero.estaLleno, isTrue);
      expect(tablero.puntuacionTotal, 50);
      expect(tablero.puntuacionPorTipo(TipoZona.naranja), 12);
      expect(tablero.puntuacionPorTipo(TipoZona.amarillo), 8);
      expect(tablero.puntuacionPorTipo(TipoZona.rojo), 12);
      expect(tablero.puntuacionPorTipo(TipoZona.azul), 8);
      expect(tablero.puntuacionPorTipo(TipoZona.verde), 3);
      expect(tablero.puntuacionPorTipo(TipoZona.morado), 7);
    });
  });
}
