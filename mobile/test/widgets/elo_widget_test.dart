// Prueba de widgets: el ELO junto a cada jugador en la sala de espera,
// durante la partida, al final y en el menú.

import 'dart:convert';

import 'package:brilliantdart/mapa_uno.dart';
import 'package:brilliantdart/puntuacion_multijugador.dart';
import 'package:brilliant_mobile/datos_sala.dart';
import 'package:brilliant_mobile/etiqueta_elo.dart';
import 'package:brilliant_mobile/main.dart';
import 'package:brilliant_mobile/mi_elo.dart';
import 'package:brilliant_mobile/panel_fin_compartido.dart';
import 'package:brilliant_mobile/elo_del_puesto.dart';
import 'package:brilliant_mobile/servicio_auth.dart';
import 'package:brilliant_mobile/tabla_puntos_partida.dart';
import 'package:brilliant_mobile/tarjetas_sala.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

SalaPartida sala({Map<String, int> elos = const {}}) => SalaPartida(
  codigo: 'ABC234',
  mapa: 1,
  capacidad: 3,
  anfitrion: 'ana',
  jugadores: const ['ana', 'luis'],
  listos: const ['luis'],
  comenzada: false,
  finalizados: const [],
  configurada: false,
  miTablero: const [],
  ronda: 0,
  dados: const [],
  jugaron: const [],
  elos: elos,
);

const Map<String, ResultadoEloJugador> resultados = {
  'luis': (lugar: 2, antes: 1032, cambio: -15, despues: 1017),
  'ana': (lugar: 1, antes: 1000, cambio: 17, despues: 1017),
  'eva': (lugar: 3, antes: 990, cambio: -2, despues: 988),
};

Future<void> mostrar(WidgetTester tester, Widget hijo) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(body: SingleChildScrollView(child: hijo)),
  ),
);

Finder en(String clave, String texto) =>
    find.descendant(of: find.byKey(Key(clave)), matching: find.text(texto));

/// El texto del widget [Text] que lleva esta clave.
String? texto(String clave) =>
    (find.byKey(Key(clave)).evaluate().single.widget as Text).data;

/// La pantalla final con estos resultados de ELO. Los puntos siguen el lugar
/// del ELO (más puntos, mejor lugar) para que la clasificación coincida.
Future<void> fin(
  WidgetTester tester,
  Map<String, ResultadoEloJugador> resultadosElo, {
  Map<String, int>? puntos,
  String usuario = 'ana',
}) {
  final jugadores = (puntos?.keys ?? resultadosElo.keys).toList();
  final puntosDe =
      puntos ??
      {for (final j in jugadores) j: 30 - resultadosElo[j]!.lugar * 5};
  final mejor = puntosDe.values.reduce((a, b) => a > b ? a : b);
  return mostrar(
    tester,
    PanelFinCompartido(
      ganadores: [
        for (final j in jugadores)
          if (puntosDe[j] == mejor) j,
      ],
      usuario: usuario,
      puntos: puntosDe,
      jugadores: jugadores,
      meta: 26,
      onVolver: () {},
      resultadosElo: resultadosElo,
    ),
  );
}

void main() {
  group('Widgets: etiqueta de ELO', () {
    testWidgets('Dice ELO y el número', (tester) async {
      await mostrar(tester, const EtiquetaElo(elo: 1016));

      expect(find.text('ELO 1016'), findsOneWidget);
    });

    testWidgets('El cambio se ve con su signo y color', (tester) async {
      await mostrar(
        tester,
        const Column(
          children: [
            CambioElo(cambio: 16),
            CambioElo(cambio: -16),
            CambioElo(cambio: 0),
          ],
        ),
      );

      Color? colorDe(String texto) =>
          tester.widget<Text>(find.text(texto)).style?.color;
      expect(colorDe('+16'), CambioElo.color(16));
      expect(colorDe('−16'), CambioElo.color(-16));
      expect(colorDe('±0'), CambioElo.color(0));
    });
  });

  group('Widgets: ELO que empieza en 0', () {
    testWidgets('Un jugador nuevo se ve con ELO 0', (tester) async {
      await mostrar(tester, const EtiquetaElo(elo: 0));

      expect(find.text('ELO 0'), findsOneWidget);
    });

    testWidgets('En la sala de espera los nuevos salen con ELO 0', (
      tester,
    ) async {
      await mostrar(
        tester,
        TarjetaJugadores(
          sala: sala(elos: {'ana': 0, 'luis': 16}),
          usuario: 'ana',
        ),
      );

      expect(en('sala-jugador-ana', 'ELO 0'), findsOneWidget);
      expect(en('sala-jugador-luis', 'ELO 16'), findsOneWidget);
    });

    testWidgets('Al final: el ganador 0 → 16 y quien perdió con 0 queda ±0', (
      tester,
    ) async {
      await fin(tester, {
        'ana': (lugar: 1, antes: 0, cambio: 16, despues: 16),
        'luis': (lugar: 2, antes: 0, cambio: 0, despues: 0),
      });

      expect(en('elo-ana', '0 → 16'), findsOneWidget);
      expect(en('elo-ana', '+16'), findsOneWidget);
      expect(en('elo-luis', '0 → 0'), findsOneWidget);
      expect(en('elo-luis', '±0'), findsOneWidget);
    });

    testWidgets('Al final: con 5 se pierde solo 5 y se queda en 0', (
      tester,
    ) async {
      await fin(tester, {
        'ana': (lugar: 1, antes: 5, cambio: 16, despues: 21),
        'luis': (lugar: 2, antes: 5, cambio: -5, despues: 0),
      });

      expect(en('elo-luis', '5 → 0'), findsOneWidget);
      expect(en('elo-luis', '−5'), findsOneWidget);
    });
  });

  group('Widgets: ELO en la sala de espera', () {
    testWidgets('Cada jugador lleva su ELO junto al nombre', (tester) async {
      await mostrar(
        tester,
        TarjetaJugadores(
          sala: sala(elos: {'ana': 1000, 'luis': 1032}),
          usuario: 'ana',
        ),
      );

      expect(en('sala-jugador-ana', 'ELO 1000'), findsOneWidget);
      expect(en('sala-jugador-luis', 'ELO 1032'), findsOneWidget);
    });

    testWidgets('Con un servidor anterior (sin ELO) no sale la etiqueta', (
      tester,
    ) async {
      await mostrar(tester, TarjetaJugadores(sala: sala(), usuario: 'ana'));

      expect(find.byType(EtiquetaElo), findsNothing);
      expect(find.text('@ana (tú)'), findsOneWidget);
    });

    testWidgets('En un celular angosto no se desborda', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await mostrar(
        tester,
        TarjetaJugadores(
          sala: sala(elos: {'ana': 1000, 'luis': 2345}),
          usuario: 'ana',
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('Widgets: ELO durante la partida', () {
    Future<void> tabla(WidgetTester tester, Map<String, int> elos) => mostrar(
      tester,
      TablaPuntosPartida(
        puntuacion: PuntuacionMultijugador(mapaUno, const {}),
        jugadores: const ['ana', 'luis'],
        usuario: 'ana',
        ronda: 1,
        elos: elos,
      ),
    );

    testWidgets('La tabla de puntos lleva el ELO de cada uno', (tester) async {
      await tabla(tester, {'ana': 1000, 'luis': 1032});

      expect(en('puntos-ana', 'ELO 1000'), findsOneWidget);
      expect(en('puntos-luis', 'ELO 1032'), findsOneWidget);
    });

    testWidgets('Sin ELO, la tabla se ve como antes', (tester) async {
      await tabla(tester, const {});

      expect(find.byType(EtiquetaElo), findsNothing);
      expect(en('puntos-ana', '0 pts'), findsOneWidget);
    });
  });

  group('Widgets: ELO al final de la partida', () {
    testWidgets('Cada jugador: antes → después y el cambio', (tester) async {
      await fin(tester, resultados);

      expect(en('elo-ana', '1000 → 1017'), findsOneWidget);
      expect(en('elo-ana', '+17'), findsOneWidget);
      expect(en('elo-luis', '1032 → 1017'), findsOneWidget);
      expect(en('elo-luis', '−15'), findsOneWidget);
      expect(en('elo-eva', '990 → 988'), findsOneWidget);
      expect(en('elo-eva', '−2'), findsOneWidget);
    });

    testWidgets('El ELO va dentro de la fila de su lugar en la tabla', (
      tester,
    ) async {
      await fin(tester, resultados);

      for (final j in ['ana', 'luis', 'eva']) {
        expect(
          find.descendant(
            of: find.byKey(Key('clasificacion-$j')),
            matching: find.byKey(Key('elo-$j')),
          ),
          findsOneWidget,
        );
      }
      expect(en('clasificacion-ana', '1.º'), findsOneWidget);
      expect(en('clasificacion-eva', '3.er'), findsOneWidget);
    });

    testWidgets('Las filas van por lugar: el ELO sigue a la clasificación', (
      tester,
    ) async {
      await fin(tester, resultados);

      final alturas = [
        for (final j in ['ana', 'luis', 'eva'])
          tester.getTopLeft(find.byKey(Key('elo-$j'))).dy,
      ];
      expect(alturas, orderedEquals([...alturas]..sort()));
    });

    testWidgets('El ELO sale debajo del nombre y los puntos de cada uno', (
      tester,
    ) async {
      await fin(tester, resultados);

      expect(
        tester.getTopLeft(find.byKey(const Key('elo-luis'))).dy,
        greaterThan(tester.getTopLeft(find.text('@luis')).dy),
      );
      expect(en('clasificacion-luis', '20 pts'), findsOneWidget);
    });

    testWidgets('Un empate sin cambio se ve ±0', (tester) async {
      await fin(tester, {
        'sol': (lugar: 1, antes: 1000, cambio: 0, despues: 1000),
        'leo': (lugar: 1, antes: 1000, cambio: 0, despues: 1000),
      }, usuario: 'sol');

      expect(en('elo-sol', '±0'), findsOneWidget);
      expect(en('elo-leo', '1000 → 1000'), findsOneWidget);
    });

    testWidgets('Mi fila dice (tú) y lleva mi ELO', (tester) async {
      await fin(tester, resultados);

      expect(en('clasificacion-ana', '@ana (tú)'), findsOneWidget);
      expect(en('clasificacion-ana', '+17'), findsOneWidget);
    });

    testWidgets('Quien salió también ve su ELO en la tabla', (tester) async {
      await mostrar(
        tester,
        PanelFinCompartido(
          ganadores: const ['ana'],
          usuario: 'ana',
          puntos: const {'ana': 8, 'luis': 12},
          jugadores: const ['ana'],
          meta: 26,
          onVolver: () {},
          porAbandono: true,
          resultadosElo: const {
            'ana': (lugar: 1, antes: 0, cambio: 16, despues: 16),
            'luis': (lugar: 2, antes: 0, cambio: 0, despues: 0),
          },
        ),
      );

      expect(en('clasificacion-luis', '@luis (salió)'), findsOneWidget);
      expect(en('clasificacion-luis', '0 → 0'), findsOneWidget);
    });

    testWidgets('Con ELO, la tabla se llama Clasificación y ELO', (
      tester,
    ) async {
      await fin(tester, resultados);

      expect(texto('clasificacion-titulo'), 'Clasificación y ELO');
    });

    testWidgets('Ya no hay un apartado de ELO aparte: todo va en la tabla', (
      tester,
    ) async {
      await fin(tester, resultados);

      expect(find.byKey(const Key('resultados-elo')), findsNothing);
      expect(find.text('ELO de la partida'), findsNothing);
      expect(find.byType(EloDelPuesto), findsNWidgets(3));
    });

    testWidgets('La tabla con ELO va antes de Volver al menú', (tester) async {
      await fin(tester, resultados);

      expect(
        tester.getTopLeft(find.byKey(const Key('elo-eva'))).dy,
        lessThan(tester.getTopLeft(find.byKey(const Key('fin-volver'))).dy),
      );
    });

    testWidgets('Sin resultados de ELO, la tabla se ve como antes', (
      tester,
    ) async {
      await fin(tester, const {}, puntos: const {'ana': 8, 'luis': 3});

      expect(find.byType(EloDelPuesto), findsNothing);
      expect(texto('clasificacion-titulo'), 'Clasificación');
      expect(en('clasificacion-ana', '8 pts'), findsOneWidget);
    });

    testWidgets('Si falta el ELO de alguien, solo su fila va sin ELO', (
      tester,
    ) async {
      await fin(
        tester,
        const {'ana': (lugar: 1, antes: 0, cambio: 16, despues: 16)},
        puntos: const {'ana': 8, 'luis': 3},
      );

      expect(find.byKey(const Key('elo-ana')), findsOneWidget);
      expect(find.byKey(const Key('elo-luis')), findsNothing);
      expect(find.byKey(const Key('clasificacion-luis')), findsOneWidget);
    });

    testWidgets('Con seis jugadores y nombres largos cabe en un celular', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await fin(tester, {
        for (final (i, j) in [
          'ana',
          'luis',
          'eva',
          'sol',
          'leo',
          'un_nombre_muy_largo_de_verdad',
        ].indexed)
          j: (
            lugar: i + 1,
            antes: 10000 + i * 111,
            cambio: 16 - i * 6,
            despues: 10000 + i * 111 + 16 - i * 6,
          ),
      });

      expect(tester.takeException(), isNull);
      expect(find.byType(EloDelPuesto), findsNWidgets(6));
    });
  });

  group('Widgets: la línea de ELO de un puesto', () {
    testWidgets('Dice ELO, antes → después y el cambio', (tester) async {
      await mostrar(
        tester,
        const EloDelPuesto(
          jugador: 'ana',
          resultado: (lugar: 1, antes: 984, cambio: 16, despues: 1000),
        ),
      );

      expect(find.text('ELO '), findsOneWidget);
      expect(texto('elo-antes-despues-ana'), '984 → 1000');
      expect(en('elo-cambio-ana', '+16'), findsOneWidget);
    });

    testWidgets('Subir en verde y bajar en rojo', (tester) async {
      await mostrar(
        tester,
        const Column(
          children: [
            EloDelPuesto(
              jugador: 'ana',
              resultado: (lugar: 1, antes: 0, cambio: 16, despues: 16),
            ),
            EloDelPuesto(
              jugador: 'luis',
              resultado: (lugar: 2, antes: 20, cambio: -16, despues: 4),
            ),
          ],
        ),
      );

      Color? colorDe(String texto) =>
          tester.widget<Text>(find.text(texto)).style?.color;
      expect(colorDe('+16'), CambioElo.color(16));
      expect(colorDe('−16'), CambioElo.color(-16));
    });

    testWidgets('Mi línea va en negritas', (tester) async {
      await mostrar(
        tester,
        const EloDelPuesto(
          jugador: 'ana',
          soyYo: true,
          resultado: (lugar: 1, antes: 0, cambio: 16, despues: 16),
        ),
      );

      expect(
        tester.widget<Text>(find.text('0 → 16')).style?.fontWeight,
        FontWeight.bold,
      );
    });
  });

  group('Widgets: mi ELO en el menú', () {
    ServicioAuth auth({required Object respuesta, List<String>? rutas}) =>
        ServicioAuth(
          servidor: 'https://servidor:8443',
          cliente: MockClient((p) async {
            rutas?.add(p.url.path);
            return http.Response.bytes(utf8.encode(jsonEncode(respuesta)), 200);
          }),
        )..sesion = const Sesion(usuario: 'ana', nombre: 'Ana', token: 'abc');

    Future<void> esperarServidor(WidgetTester tester) async {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
    }

    testWidgets('Al abrir el menú se pide y se ve mi ELO', (tester) async {
      final rutas = <String>[];
      await tester.pumpWidget(
        BrilliantApp(
          auth: auth(
            respuesta: {'ok': true, 'mensaje': 'ELO.', 'elo': 1016},
            rutas: rutas,
          ),
        ),
      );
      await esperarServidor(tester);

      expect(rutas, contains('/api/elo'));
      expect(en('mi-elo', 'ELO 1016'), findsOneWidget);
      expect(find.byKey(const Key('sesion-actual')), findsOneWidget);
    });

    testWidgets('Con ELO 0, en el menú se ve ELO 0', (tester) async {
      await tester.pumpWidget(
        BrilliantApp(
          auth: auth(respuesta: {'ok': true, 'mensaje': 'ELO.', 'elo': 0}),
        ),
      );
      await esperarServidor(tester);

      expect(en('mi-elo', 'ELO 0'), findsOneWidget);
    });

    testWidgets('Mientras no llega, no se muestra nada', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MiElo(auth: auth(respuesta: {'ok': false, 'mensaje': 'No.'})),
          ),
        ),
      );
      await esperarServidor(tester);

      expect(find.byKey(const Key('mi-elo')), findsNothing);
    });

    testWidgets('Cambia solo cuando cambia el ELO de la sesión', (
      tester,
    ) async {
      final sesion = auth(
        respuesta: {'ok': true, 'mensaje': 'ELO.', 'elo': 1000},
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: MiElo(auth: sesion)),
        ),
      );
      await esperarServidor(tester);
      expect(find.text('ELO 1000'), findsOneWidget);

      // Como al terminar una partida.
      sesion.elo.value = 1016;
      await tester.pump();

      expect(find.text('ELO 1016'), findsOneWidget);
    });

    testWidgets('Con un nombre largo, el menú no se desborda', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final sesion =
          auth(respuesta: {'ok': true, 'mensaje': 'ELO.', 'elo': 1016})
            ..sesion = const Sesion(
              usuario: 'un_usuario_muy_largo_de_verdad',
              nombre: 'Un Nombre Muy Largo De Verdad',
              token: 'abc',
            );

      await tester.pumpWidget(BrilliantApp(auth: sesion));
      await esperarServidor(tester);

      expect(tester.takeException(), isNull);
    });
  });
}
