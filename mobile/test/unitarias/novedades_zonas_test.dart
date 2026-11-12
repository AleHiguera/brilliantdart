// Prueba unitaria: qué zonas completaron los demás desde la última consulta
// (las propias no: esas se festejan al mover).

import 'package:brilliant_mobile/novedades_zonas.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Zonas nuevas de otros', () {
    test('Sin cambios no hay nada nuevo', () {
      final registro = {
        3: {'luis': 1},
      };

      expect(
        zonasNuevasDeOtros(antes: registro, ahora: registro, usuario: 'ana'),
        isEmpty,
      );
    });

    test('Detecta la zona que otro acaba de completar', () {
      expect(
        zonasNuevasDeOtros(
          antes: {},
          ahora: {
            3: {'luis': 2},
          },
          usuario: 'ana',
        ),
        [(jugador: 'luis', zona: 3, ronda: 2)],
      );
    });

    test('Las del propio jugador no cuentan', () {
      expect(
        zonasNuevasDeOtros(
          antes: {},
          ahora: {
            3: {'ana': 1},
          },
          usuario: 'ana',
        ),
        isEmpty,
      );
    });

    test('Otro jugador en una zona ya conocida sí es nuevo', () {
      expect(
        zonasNuevasDeOtros(
          antes: {
            3: {'luis': 1},
          },
          ahora: {
            3: {'luis': 1, 'eva': 2},
          },
          usuario: 'ana',
        ),
        [(jugador: 'eva', zona: 3, ronda: 2)],
      );
    });

    test('Varias a la vez, por número de zona', () {
      expect(
        zonasNuevasDeOtros(
          antes: {},
          ahora: {
            7: {'eva': 1},
            2: {'luis': 1},
          },
          usuario: 'ana',
        ).map((nueva) => nueva.zona),
        [2, 7],
      );
    });

    test('Sin usuario, todas son de otros', () {
      expect(
        zonasNuevasDeOtros(
          antes: {},
          ahora: {
            3: {'ana': 1},
          },
          usuario: null,
        ),
        hasLength(1),
      );
    });
  });

  group('A quién se le avisa y cuándo', () {
    RepartoAvisos repartir(
      List<ZonaAjena> pendientes,
      Map<int, Map<String, int>> registro, {
      String usuario = 'ana',
      int rondaActual = 2,
      bool yaJugo = true,
    }) => repartirAvisos(
      pendientes: pendientes,
      registro: registro,
      usuario: usuario,
      rondaActual: rondaActual,
      yaJugoEstaRonda: yaJugo,
    );

    const deLuis = (jugador: 'luis', zona: 3, ronda: 2);

    test('Si no la ha llenado y ya jugó, se le avisa', () {
      final reparto = repartir(
        [deLuis],
        {
          3: {'luis': 2},
        },
      );

      expect(reparto.avisar, [deLuis]);
      expect(reparto.esperar, isEmpty);
      expect(reparto.descartar, isEmpty);
    });

    test('Si todavía no juega esta ronda, espera', () {
      final reparto = repartir(
        [deLuis],
        {
          3: {'luis': 2},
        },
        yaJugo: false,
      );

      expect(reparto.esperar, [deLuis]);
      expect(reparto.avisar, isEmpty);
    });

    test('Lo de una ronda ya cerrada no espera', () {
      final reparto = repartir(
        [deLuis],
        {
          3: {'luis': 2},
        },
        rondaActual: 3,
        yaJugo: false,
      );

      expect(reparto.avisar, [deLuis]);
    });

    test('Si la llenó antes, no se le avisa nunca', () {
      final reparto = repartir(
        [deLuis],
        {
          3: {'ana': 1, 'luis': 2},
        },
      );

      expect(reparto.descartar, [deLuis]);
      expect(reparto.avisar, isEmpty);
    });

    test('Si la llenó en la misma ronda (empate), tampoco', () {
      final reparto = repartir(
        [deLuis],
        {
          3: {'ana': 2, 'luis': 2},
        },
      );

      expect(reparto.descartar, [deLuis]);
    });

    test('Ejemplo de 4 jugadores, ronda por ronda', () {
      // Ronda 1: pepe llena primero la azul (zona 3).
      // Ronda 2: luis la llena segundo. Ronda 3: eva la llena tercera.
      // Ana nunca la llena.
      const dePepe = (jugador: 'pepe', zona: 3, ronda: 1);
      const deLuis2 = (jugador: 'luis', zona: 3, ronda: 2);
      const deEva = (jugador: 'eva', zona: 3, ronda: 3);
      final registro = {
        3: {'pepe': 1, 'luis': 2, 'eva': 3},
      };

      List<ZonaAjena> avisosPara(String usuario, List<ZonaAjena> ajenas) =>
          repartir(
            [
              for (final ajena in ajenas)
                if (ajena.jugador != usuario) ajena,
            ],
            registro,
            usuario: usuario,
            rondaActual: 4,
          ).avisar;

      final todas = [dePepe, deLuis2, deEva];
      // Pepe ya la tenía cuando la llenaron luis y eva.
      expect(avisosPara('pepe', todas), isEmpty);
      // Luis supo de pepe, pero no de eva: él ya la tenía.
      expect(avisosPara('luis', todas), [dePepe]);
      // Eva supo de pepe y de luis, antes de llenarla ella.
      expect(avisosPara('eva', todas), [dePepe, deLuis2]);
      // Ana, que nunca la llenó, supo de los tres.
      expect(avisosPara('ana', todas), todas);
    });

    test('Empate entre tres: a ninguno de los tres le llega', () {
      const registro = {
        3: {'ana': 2, 'luis': 2, 'eva': 2},
      };
      for (final usuario in ['ana', 'luis', 'eva']) {
        final ajenas = [
          for (final jugador in ['ana', 'luis', 'eva'])
            if (jugador != usuario) (jugador: jugador, zona: 3, ronda: 2),
        ];
        expect(
          repartir(ajenas, registro, usuario: usuario).avisar,
          isEmpty,
          reason: usuario,
        );
      }
    });
  });

  group('Dos zonas del mismo color son independientes', () {
    test(
      'Si llenó la verde 1, igual se le avisa cuando otro llena la verde 2',
      () {
        // Zona 4 = verde 1, zona 7 = verde 2 (cualquier par de zonas distintas).
        const deLuis = (jugador: 'luis', zona: 7, ronda: 2);
        final reparto = repartirAvisos(
          pendientes: [deLuis],
          registro: {
            4: {'ana': 1},
            7: {'luis': 2},
          },
          usuario: 'ana',
          rondaActual: 3,
          yaJugoEstaRonda: false,
        );

        expect(reparto.avisar, [deLuis]);
        expect(reparto.descartar, isEmpty);
      },
    );

    test('Y si llenó esa misma verde 2, no', () {
      const deLuis = (jugador: 'luis', zona: 7, ronda: 2);
      final reparto = repartirAvisos(
        pendientes: [deLuis],
        registro: {
          4: {'ana': 1},
          7: {'ana': 1, 'luis': 2},
        },
        usuario: 'ana',
        rondaActual: 3,
        yaJugoEstaRonda: false,
      );

      expect(reparto.descartar, [deLuis]);
    });
  });
}
