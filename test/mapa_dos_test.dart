import 'package:test/test.dart';

import 'package:brilliantdart/bloc_valores_iniciales.dart';
import 'package:brilliantdart/mapa.dart';
import 'package:brilliantdart/mapa_dos.dart';
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
          TipoZona.naranja => (zona.tipo as TipoNaranja).minimo,
          TipoZona.morado => indice == 0 ? 2 : 5,
        };
        final celda = zona.coordenadas[indice];
        tablero.colocarDato(celda.x, celda.y, numero);
      }
    }
  }

  group('Mapa 2: su descripción', () {
    test('mapaDos es un Mapa', () {
      expect(mapaDos, isA<Mapa>());
    });

    test('Es el mapa número 2', () {
      expect(mapaDos.numero, 2);
    });

    test('const MapaDos() es el mismo objeto que mapaDos', () {
      expect(identical(const MapaDos(), mapaDos), isTrue);
    });

    test('Su dibujo es de 7 por 7', () {
      expect(mapaDos.tiposPorCelda, hasLength(7));
      for (final fila in mapaDos.tiposPorCelda) {
        expect(fila, hasLength(7));
      }
    });

    test('El dibujo es el del papel, fila por fila', () {
      const m = TipoZona.morado,
          g = TipoZona.gris,
          v = TipoZona.verde,
          a = TipoZona.amarillo,
          r = TipoZona.rojo,
          z = TipoZona.azul;

      expect(mapaDos.tiposPorCelda, [
        [m, m, m, g, v, v, v],
        [m, a, z, z, z, a, v],
        [m, r, r, z, z, r, v],
        [r, r, r, a, r, r, r],
        [v, r, z, z, r, r, m],
        [v, a, z, z, z, a, m],
        [v, v, v, g, m, m, m],
      ]);
    });

    test('Cada letra significa su color', () {
      expect(MapaDos.letras, {
        'M': TipoZona.morado,
        'G': TipoZona.gris,
        'V': TipoZona.verde,
        'A': TipoZona.amarillo,
        'R': TipoZona.rojo,
        'Z': TipoZona.azul,
        'N': TipoZona.naranja,
      });
    });

    test('El dibujo no se puede modificar desde fuera', () {
      expect(
        () => mapaDos.tiposPorCelda[0][0] = TipoZona.verde,
        throwsUnsupportedError,
      );
      expect(() => mapaDos.tiposPorCelda.add([]), throwsUnsupportedError);
    });

    test('Es distinto al Mapa 1', () {
      expect(mapaDos.tiposPorCelda, isNot(mapaUno.tiposPorCelda));
    });

    test('Usa los 6 colores, incluido el gris', () {
      expect(mapaDos.tiposPresentes.toSet(), {
        TipoZona.azul,
        TipoZona.rojo,
        TipoZona.verde,
        TipoZona.amarillo,
        TipoZona.morado,
        TipoZona.gris,
      });
      expect(mapaDos.tiposPresentes, isNot(contains(TipoZona.naranja)));
    });

    test('Cuántas celdas tiene cada color', () {
      int celdasDe(TipoZona tipo) => mapaDos.tiposPorCelda
          .expand((fila) => fila)
          .where((celda) => celda == tipo)
          .length;

      expect(celdasDe(TipoZona.morado), 10);
      expect(celdasDe(TipoZona.gris), 2);
      expect(celdasDe(TipoZona.verde), 10);
      expect(celdasDe(TipoZona.amarillo), 5);
      expect(celdasDe(TipoZona.rojo), 12);
      expect(celdasDe(TipoZona.azul), 10);
    });

    test('Tiene sus 6 celdas iniciales', () {
      expect(mapaDos.celdasIniciales, [
        (1, 5),
        (3, 1),
        (4, 3),
        (5, 6),
        (6, 2),
        (7, 5),
      ]);
    });

    test('El amarillo y el gris van unidos', () {
      expect(mapaDos.tiposUnidos, {TipoZona.amarillo, TipoZona.gris});
    });

    test('Puntos: morado 6, gris 3, verde 4, amarillo 6, rojo 6 y azul 7', () {
      expect(mapaDos.crearTipo(TipoZona.morado).puntuacion, 6);
      expect(mapaDos.crearTipo(TipoZona.gris).puntuacion, 3);
      expect(mapaDos.crearTipo(TipoZona.verde).puntuacion, 4);
      expect(mapaDos.crearTipo(TipoZona.amarillo).puntuacion, 6);
      expect(mapaDos.crearTipo(TipoZona.rojo).puntuacion, 6);
      expect(mapaDos.crearTipo(TipoZona.azul).puntuacion, 7);
    });

    test('El amarillo vale menos que en el Mapa 1', () {
      expect(mapaDos.crearTipo(TipoZona.amarillo).puntuacion, 6);
      expect(mapaUno.crearTipo(TipoZona.amarillo).puntuacion, 8);
    });

    test('Cada color tiene la regla de su tipo', () {
      expect(mapaDos.crearTipo(TipoZona.morado), isA<TipoMorado>());
      expect(mapaDos.crearTipo(TipoZona.gris), isA<TipoGris>());
      expect(mapaDos.crearTipo(TipoZona.verde), isA<TipoVerde>());
      expect(mapaDos.crearTipo(TipoZona.amarillo), isA<TipoAmarillo>());
      expect(mapaDos.crearTipo(TipoZona.rojo), isA<TipoRojo>());
      expect(mapaDos.crearTipo(TipoZona.azul), isA<TipoAzul>());
    });

    test('Cada color tiene nombre y regla escritos', () {
      for (final tipo in mapaDos.tiposPresentes) {
        expect(mapaDos.crearTipo(tipo).color, isNotEmpty);
        expect(mapaDos.crearTipo(tipo).regla, isNotEmpty);
      }
      expect(mapaDos.crearTipo(TipoZona.gris).color, 'Gris');
    });
  });

  group('Mapa 2: sus zonas', () {
    late Tablero tablero;
    setUp(() => tablero = mapaDos.crearTablero());

    test('Tiene 10 zonas', () {
      expect(tablero.regiones, hasLength(10));
    });

    test('Cuántas zonas tiene cada color', () {
      expect(zonasDe(tablero, TipoZona.morado), hasLength(2));
      expect(zonasDe(tablero, TipoZona.gris), hasLength(1));
      expect(zonasDe(tablero, TipoZona.verde), hasLength(2));
      expect(zonasDe(tablero, TipoZona.amarillo), hasLength(1));
      expect(zonasDe(tablero, TipoZona.rojo), hasLength(2));
      expect(zonasDe(tablero, TipoZona.azul), hasLength(2));
    });

    test('Las zonas cubren las 49 celdas sin repetir ninguna', () {
      final celdas = [
        for (final zona in tablero.regiones)
          for (final celda in zona.coordenadas) (celda.x, celda.y),
      ];

      expect(celdas, hasLength(49));
      expect(celdas.toSet(), hasLength(49));
    });

    test('Los dos grises separados son una sola zona', () {
      expect(zonasDe(tablero, TipoZona.gris).single, {(1, 4), (7, 4)});
    });

    test('Los 5 amarillos separados son una sola zona', () {
      expect(zonasDe(tablero, TipoZona.amarillo).single, {
        (2, 2),
        (2, 6),
        (4, 4),
        (6, 2),
        (6, 6),
      });
    });

    test(
      'Morado: una zona arriba a la izquierda y otra abajo a la derecha',
      () {
        expect(zonasDe(tablero, TipoZona.morado), [
          {(1, 1), (1, 2), (1, 3), (2, 1), (3, 1)},
          {(5, 7), (6, 7), (7, 5), (7, 6), (7, 7)},
        ]);
      },
    );

    test('Verde: una zona arriba a la derecha y otra abajo a la izquierda', () {
      expect(zonasDe(tablero, TipoZona.verde), [
        {(1, 5), (1, 6), (1, 7), (2, 7), (3, 7)},
        {(5, 1), (6, 1), (7, 1), (7, 2), (7, 3)},
      ]);
    });

    test('Azul: una zona arriba y otra abajo, de 5 celdas cada una', () {
      expect(zonasDe(tablero, TipoZona.azul), [
        {(2, 3), (2, 4), (2, 5), (3, 4), (3, 5)},
        {(5, 3), (5, 4), (6, 3), (6, 4), (6, 5)},
      ]);
    });

    test('Rojo: una zona a la izquierda y otra a la derecha de 6 celdas', () {
      expect(zonasDe(tablero, TipoZona.rojo), [
        {(3, 2), (3, 3), (4, 1), (4, 2), (4, 3), (5, 2)},
        {(3, 6), (4, 5), (4, 6), (4, 7), (5, 5), (5, 6)},
      ]);
    });

    test('Cada zona usa los puntos de su color', () {
      const puntos = {
        TipoZona.morado: 6,
        TipoZona.gris: 3,
        TipoZona.verde: 4,
        TipoZona.amarillo: 6,
        TipoZona.rojo: 6,
        TipoZona.azul: 7,
      };
      for (final zona in tablero.regiones) {
        expect(zona.tipo.puntuacion, puntos[zona.tipo.tipo]);
      }
    });

    test('El máximo de puntos es 55', () {
      final maximo = tablero.regiones.fold(
        0,
        (total, zona) => total + zona.tipo.puntuacion,
      );

      expect(maximo, 6 * 2 + 3 + 4 * 2 + 6 + 6 * 2 + 7 * 2);
      expect(maximo, 55);
    });

    test('Los ids de las zonas van del 1 al 10', () {
      expect(
        tablero.regiones.map((zona) => zona.id),
        List.generate(10, (indice) => indice + 1),
      );
    });

    test('Cada llamada a crearTablero da un tablero nuevo', () {
      tablero.colocarDato(0, 0, 3);

      expect(mapaDos.crearTablero().obtenerCelda(0, 0).valor, isNull);
    });

    test('Crear el Mapa 2 no cambia el Mapa 1', () {
      expect(mapaUno.crearTablero().regiones, hasLength(9));
    });
  });

  group('Mapa 2: celdas iniciales', () {
    test('Cada celda inicial cae en una zona distinta', () {
      final tablero = mapaDos.crearTablero();
      final zonas = {
        for (final (fila, columna) in mapaDos.celdasIniciales)
          zonaEn(tablero, fila, columna).id,
      };

      expect(zonas, hasLength(6));
    });

    test('Los colores de las celdas iniciales', () {
      expect(
        [
          for (final (fila, columna) in mapaDos.celdasIniciales)
            mapaDos.tipoEn(fila - 1, columna - 1),
        ],
        [
          TipoZona.verde,
          TipoZona.morado,
          TipoZona.rojo,
          TipoZona.rojo,
          TipoZona.amarillo,
          TipoZona.morado,
        ],
      );
    });

    test('Ninguna celda inicial es gris', () {
      for (final (fila, columna) in mapaDos.celdasIniciales) {
        expect(mapaDos.tipoEn(fila - 1, columna - 1), isNot(TipoZona.gris));
      }
    });

    test('El bloc acepta los 6 números en sus celdas iniciales', () {
      final tablero = mapaDos.crearTablero();
      final bloc = BlocValoresIniciales(
        tablero,
        celdasIniciales: mapaDos.celdasIniciales,
      );
      expect(bloc.puedeIniciar, isFalse);

      for (var i = 0; i < 6; i++) {
        final (fila, columna) = mapaDos.celdasIniciales[i];
        bloc.colocarValorInicial(fila, columna, i + 1);
      }

      expect(bloc.puedeIniciar, isTrue);
      expect(bloc.obtenerValoresIniciales(), [1, 2, 3, 4, 5, 6]);
      expect(tablero.obtenerCelda(0, 4).valor, 1);
      expect(tablero.obtenerCelda(6, 4).valor, 6);
    });

    test('El bloc rechaza las celdas iniciales del Mapa 1', () {
      final bloc = BlocValoresIniciales(
        mapaDos.crearTablero(),
        celdasIniciales: mapaDos.celdasIniciales,
      );

      for (final (fila, columna) in mapaUno.celdasIniciales) {
        if (mapaDos.celdasIniciales.contains((fila, columna))) continue;
        expect(
          () => bloc.colocarValorInicial(fila, columna, 1),
          throwsArgumentError,
        );
      }
    });

    test('La (7, 5) es celda inicial en los dos mapas', () {
      expect(mapaUno.celdasIniciales, contains((7, 5)));
      expect(mapaDos.celdasIniciales, contains((7, 5)));
      expect(mapaDos.celdasIniciales, isNot(contains((6, 5))));
    });

    test('La (7, 5) es morada y la (6, 5) es una celda azul normal', () {
      final tablero = mapaDos.crearTablero();
      final bloc = BlocValoresIniciales(
        tablero,
        celdasIniciales: mapaDos.celdasIniciales,
      );

      expect(mapaDos.tipoEn(6, 4), TipoZona.morado);
      expect(mapaDos.tipoEn(5, 4), TipoZona.azul);
      bloc.colocarValorInicial(7, 5, 6);
      expect(tablero.obtenerCelda(6, 4).valor, 6);
      expect(() => bloc.colocarValorInicial(6, 5, 6), throwsArgumentError);
    });
  });

  group('Mapa 2: reglas jugando', () {
    test('Los dos grises deben llevar el mismo número', () {
      final tablero = mapaDos.crearTablero()..colocarDato(0, 3, 5);

      expect(tablero.puedeColocarDato(6, 3, 5), isTrue);
      for (final otro in [1, 2, 3, 4, 6]) {
        expect(tablero.puedeColocarDato(6, 3, otro), isFalse);
      }
    });

    test('Completar el gris con números iguales suma 3 puntos', () {
      final tablero = mapaDos.crearTablero()
        ..colocarDato(0, 3, 2)
        ..colocarDato(6, 3, 2);

      expect(tablero.puntuacionPorTipo(TipoZona.gris), 3);
      expect(tablero.puntuacionTotal, 3);
    });

    test('Un gris distinto no suma puntos', () {
      final tablero = mapaDos.crearTablero()
        ..colocarDato(0, 3, 2)
        ..colocarDato(6, 3, 6);

      expect(tablero.puntuacionPorTipo(TipoZona.gris), 0);
    });

    test('Un amarillo no puede repetir un número de otro amarillo lejano', () {
      final tablero = mapaDos.crearTablero()..colocarDato(1, 1, 4);

      expect(tablero.puedeColocarDato(5, 5, 4), isFalse);
      expect(tablero.puedeColocarDato(5, 5, 3), isTrue);
    });

    test('Completar el amarillo suma 6 puntos', () {
      final tablero = mapaDos.crearTablero();
      final amarillos = [(1, 1), (1, 5), (3, 3), (5, 1), (5, 5)];
      for (var i = 0; i < amarillos.length; i++) {
        final (fila, columna) = amarillos[i];
        tablero.colocarDato(fila, columna, i + 1);
      }

      expect(tablero.puntuacionPorTipo(TipoZona.amarillo), 6);
    });

    test('Un azul solo acepta el número que ya tiene su zona', () {
      final tablero = mapaDos.crearTablero()..colocarDato(1, 2, 3);

      expect(tablero.puedeColocarDato(1, 3, 3), isTrue);
      expect(tablero.puedeColocarDato(1, 3, 4), isFalse);
      // La otra zona azul es aparte y puede llevar otro número.
      expect(tablero.puedeColocarDato(4, 2, 4), isTrue);
    });

    test('Un rojo no acepta un número repetido en su zona', () {
      final tablero = mapaDos.crearTablero()..colocarDato(3, 0, 5);

      expect(tablero.puedeColocarDato(3, 1, 5), isFalse);
      expect(tablero.puedeColocarDato(3, 1, 1), isTrue);
    });

    test('Llenar todo respetando las reglas da 55 puntos', () {
      final tablero = mapaDos.crearTablero();

      llenarRespetandoReglas(tablero);

      expect(tablero.estaLleno, isTrue);
      expect(tablero.puntuacionTotal, 55);
      expect(tablero.puntuacionPorTipo(TipoZona.morado), 12);
      expect(tablero.puntuacionPorTipo(TipoZona.gris), 3);
      expect(tablero.puntuacionPorTipo(TipoZona.verde), 8);
      expect(tablero.puntuacionPorTipo(TipoZona.amarillo), 6);
      expect(tablero.puntuacionPorTipo(TipoZona.rojo), 12);
      expect(tablero.puntuacionPorTipo(TipoZona.azul), 14);
      expect(tablero.regiones.every((zona) => zona.completado), isTrue);
    });

    test('Un tablero nuevo tiene 0 puntos', () {
      final tablero = mapaDos.crearTablero();

      expect(tablero.puntuacionTotal, 0);
      expect(tablero.estaLleno, isFalse);
    });
  });
}
