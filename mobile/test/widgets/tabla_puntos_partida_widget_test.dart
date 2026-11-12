import 'package:brilliant_mobile/tabla_puntos_partida.dart';
import 'package:brilliantdart/mapa_uno.dart';
import 'package:brilliantdart/puntuacion_multijugador.dart';
import 'package:brilliantdart/tipoo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

List<int> zonasDe(TipoZona color) => [
  for (final zona in mapaUno.crearTablero().regiones)
    if (zona.tipo.tipo == color) zona.id,
];

Future<void> dibujar(
  WidgetTester tester, {
  Map<int, Map<String, int>> rondas = const {},
  List<String> jugadores = const ['ana', 'luis', 'eva'],
  String usuario = 'ana',
  int ronda = 9,
}) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: TablaPuntosPartida(
          puntuacion: PuntuacionMultijugador(mapaUno, rondas),
          jugadores: jugadores,
          usuario: usuario,
          ronda: ronda,
        ),
      ),
    ),
  ),
);

Finder enFila(String clave, String texto) =>
    find.descendant(of: find.byKey(Key(clave)), matching: find.text(texto));

/// De arriba hacia abajo, en qué orden aparecen esos jugadores.
List<String> ordenDe(WidgetTester tester, List<String> jugadores) =>
    [...jugadores]..sort(
      (a, b) => tester
          .getTopLeft(find.byKey(Key('puntos-$a')))
          .dy
          .compareTo(tester.getTopLeft(find.byKey(Key('puntos-$b'))).dy),
    );

void main() {
  final amarilla = zonasDe(TipoZona.amarillo).single;
  final verdes = zonasDe(TipoZona.verde);

  group('Widgets: puntos de todos los jugadores', () {
    testWidgets('Al empezar todos tienen 0 y se marca quién soy', (
      tester,
    ) async {
      await dibujar(tester);

      expect(enFila('puntos-ana', '@ana (tú)'), findsOneWidget);
      expect(enFila('puntos-ana', '0 pts'), findsOneWidget);
      expect(enFila('puntos-luis', '@luis'), findsOneWidget);
      expect(enFila('puntos-eva', '0 pts'), findsOneWidget);
    });

    testWidgets('Muestra los puntos según el lugar de cada uno', (
      tester,
    ) async {
      await dibujar(
        tester,
        rondas: {
          amarilla: {'luis': 1, 'eva': 2, 'ana': 3},
        },
      );

      expect(enFila('puntos-luis', '8 pts'), findsOneWidget);
      expect(enFila('puntos-eva', '6 pts'), findsOneWidget);
      expect(enFila('puntos-ana', '4 pts'), findsOneWidget);
    });

    testWidgets('Quien va ganando aparece primero', (tester) async {
      await dibujar(
        tester,
        rondas: {
          amarilla: {'eva': 1, 'ana': 2},
        },
      );

      expect(ordenDe(tester, ['ana', 'luis', 'eva']), ['eva', 'ana', 'luis']);
    });

    testWidgets('Con los mismos puntos se respeta el orden de llegada', (
      tester,
    ) async {
      await dibujar(
        tester,
        rondas: {
          amarilla: {'eva': 1, 'luis': 1},
        },
      );

      expect(ordenDe(tester, ['ana', 'luis', 'eva']), ['luis', 'eva', 'ana']);
    });

    testWidgets('Quien salió conserva sus puntos y se indica', (tester) async {
      await dibujar(
        tester,
        jugadores: ['ana', 'eva'],
        rondas: {
          amarilla: {'luis': 1},
        },
      );

      expect(enFila('puntos-luis', '@luis (salió)'), findsOneWidget);
      expect(enFila('puntos-luis', '8 pts'), findsOneWidget);
    });

    testWidgets('Quien salió sin puntos ya no aparece', (tester) async {
      await dibujar(tester, jugadores: ['ana', 'eva']);

      expect(find.byKey(const Key('puntos-luis')), findsNothing);
    });
  });

  group('Widgets: cuánto vale cada zona', () {
    const siguiente = EstadoLugar.siguiente;
    const libre = EstadoLugar.libre;
    const ganado = EstadoLugar.ganado;
    const mio = EstadoLugar.mio;

    List<EstadoLugar> estados(WidgetTester tester, int zona) => [
      for (var lugar = 1; lugar <= 3; lugar++)
        tester
            .widget<CasillaLugar>(find.byKey(Key('zona-$zona-lugar-$lugar')))
            .estado,
    ];

    List<String> valores(WidgetTester tester, int zona) => [
      for (var lugar = 1; lugar <= 3; lugar++)
        tester
            .widget<Text>(
              find.descendant(
                of: find.byKey(Key('zona-$zona-lugar-$lugar')),
                matching: find.byType(Text),
              ),
            )
            .data!,
    ];

    testWidgets('Siempre se ven los puntos de los 3 lugares', (tester) async {
      await dibujar(tester);

      expect(enFila('zona-$amarilla', 'Amarilla'), findsOneWidget);
      expect(valores(tester, amarilla), ['8', '6', '4']);
      for (final zona in mapaUno.crearTablero().regiones) {
        expect(valores(tester, zona.id), [
          for (var lugar = 1; lugar <= 3; lugar++)
            '${zona.tipo.puntosDeLugar(lugar)}',
        ], reason: 'zona ${zona.id}');
      }
    });

    testWidgets('Arriba dice qué lugar es cada columna', (tester) async {
      await dibujar(tester);

      for (final lugar in ['1.º', '2.º', '3.er']) {
        expect(enFila('tabla-zonas-lugares', lugar), findsOneWidget);
      }
    });

    testWidgets('Sin nadie que la llene, el 1.º es el siguiente', (
      tester,
    ) async {
      await dibujar(tester);

      expect(estados(tester, amarilla), [siguiente, libre, libre]);
    });

    testWidgets('Los lugares ganados se marcan y avanza el siguiente', (
      tester,
    ) async {
      await dibujar(
        tester,
        rondas: {
          amarilla: {'luis': 1},
        },
      );
      expect(estados(tester, amarilla), [ganado, siguiente, libre]);

      await dibujar(
        tester,
        rondas: {
          amarilla: {'luis': 1, 'eva': 2},
        },
      );
      expect(estados(tester, amarilla), [ganado, ganado, siguiente]);
      // Los puntos siguen a la vista aunque ya se hayan ganado.
      expect(valores(tester, amarilla), ['8', '6', '4']);
    });

    testWidgets('Con los 3 lugares ganados, ya no queda ninguno', (
      tester,
    ) async {
      await dibujar(
        tester,
        rondas: {
          amarilla: {'luis': 1, 'eva': 2, 'sol': 3},
        },
      );

      expect(estados(tester, amarilla), [ganado, ganado, ganado]);
    });

    testWidgets('Si otro la llenó en esta ronda, aún se puede empatar', (
      tester,
    ) async {
      await dibujar(
        tester,
        ronda: 3,
        rondas: {
          amarilla: {'luis': 3},
        },
      );

      expect(estados(tester, amarilla), [siguiente, libre, libre]);
    });

    testWidgets('Un empate anterior gana un solo lugar', (tester) async {
      await dibujar(
        tester,
        rondas: {
          amarilla: {'luis': 1, 'eva': 1},
        },
      );

      expect(estados(tester, amarilla), [ganado, siguiente, libre]);
    });

    testWidgets('El lugar que ganó el jugador se marca como suyo', (
      tester,
    ) async {
      await dibujar(
        tester,
        rondas: {
          amarilla: {'luis': 1, 'ana': 2},
        },
      );

      expect(estados(tester, amarilla), [ganado, mio, libre]);
    });

    testWidgets('Ganar el 3.º también se marca', (tester) async {
      await dibujar(
        tester,
        rondas: {
          amarilla: {'luis': 1, 'eva': 2, 'ana': 3},
        },
      );

      expect(estados(tester, amarilla), [ganado, ganado, mio]);
    });

    testWidgets('Quien la llenó 4.º ve los 3 ganados por otros', (
      tester,
    ) async {
      await dibujar(
        tester,
        rondas: {
          amarilla: {'luis': 1, 'eva': 2, 'sol': 3, 'ana': 4},
        },
      );

      expect(estados(tester, amarilla), [ganado, ganado, ganado]);
    });

    testWidgets('Lo ganado se tacha y lo propio va en negro', (tester) async {
      await dibujar(
        tester,
        rondas: {
          amarilla: {'luis': 1, 'ana': 2},
        },
      );

      Text texto(int lugar) => tester.widget<Text>(
        find.descendant(
          of: find.byKey(Key('zona-$amarilla-lugar-$lugar')),
          matching: find.byType(Text),
        ),
      );
      BoxDecoration caja(int lugar) =>
          tester
                  .widget<Container>(
                    find
                        .descendant(
                          of: find.byKey(Key('zona-$amarilla-lugar-$lugar')),
                          matching: find.byType(Container),
                        )
                        .first,
                  )
                  .decoration!
              as BoxDecoration;

      expect(texto(1).style!.decoration, TextDecoration.lineThrough);
      expect(texto(2).style!.decoration, isNull);
      expect(caja(2).color, Colors.black);
      expect(texto(2).style!.color, Colors.white);
      expect(texto(3).style!.decoration, isNull);
    });

    testWidgets('Al dejar el dedo encima explica cada lugar', (tester) async {
      await dibujar(
        tester,
        rondas: {
          amarilla: {'luis': 1},
        },
      );

      expect(
        find.byTooltip('1.º lugar: 8 puntos, ya lo ganó otro jugador'),
        findsOneWidget,
      );
      expect(
        find.byTooltip('2.º lugar: 6 puntos, es el siguiente disponible'),
        findsOneWidget,
      );
    });

    testWidgets('Dos zonas verdes se nombran y se marcan por separado', (
      tester,
    ) async {
      await dibujar(
        tester,
        rondas: {
          verdes[0]: {'luis': 1, 'eva': 2, 'sol': 3},
        },
      );

      expect(enFila('zona-${verdes[0]}', 'Verde 1'), findsOneWidget);
      expect(estados(tester, verdes[0]), [ganado, ganado, ganado]);
      expect(enFila('zona-${verdes[1]}', 'Verde 2'), findsOneWidget);
      expect(estados(tester, verdes[1]), [siguiente, libre, libre]);
    });

    testWidgets('Aparecen todas las zonas del mapa', (tester) async {
      await dibujar(tester);

      for (final zona in mapaUno.crearTablero().regiones) {
        expect(find.byKey(Key('zona-${zona.id}')), findsOneWidget);
      }
    });
  });

  testWidgets('Cabe en una columna angosta con nombres largos', (tester) async {
    tester.view.physicalSize = const Size(170, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await dibujar(
      tester,
      jugadores: ['ana', 'un_usuario_con_nombre_muy_largo_de_verdad'],
      rondas: {
        amarilla: {'ana': 3},
      },
    );

    expect(tester.takeException(), isNull);
  });
}
