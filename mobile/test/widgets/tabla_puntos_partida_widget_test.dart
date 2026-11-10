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
    testWidgets('Sin nadie que la complete vale el primer lugar', (
      tester,
    ) async {
      await dibujar(tester);

      expect(enFila('zona-$amarilla', 'Amarilla'), findsOneWidget);
      expect(enFila('zona-$amarilla', 'Vale 8'), findsOneWidget);
    });

    testWidgets('Baja cuando otros ganan los lugares', (tester) async {
      await dibujar(
        tester,
        rondas: {
          amarilla: {'luis': 1},
        },
      );
      expect(enFila('zona-$amarilla', 'Vale 6'), findsOneWidget);

      await dibujar(
        tester,
        rondas: {
          amarilla: {'luis': 1, 'eva': 2},
        },
      );
      expect(enFila('zona-$amarilla', 'Vale 4'), findsOneWidget);
    });

    testWidgets('Agotados los lugares ya no da puntos', (tester) async {
      await dibujar(
        tester,
        rondas: {
          amarilla: {'luis': 1, 'eva': 2, 'sol': 3},
        },
      );

      expect(enFila('zona-$amarilla', 'Sin puntos'), findsOneWidget);
    });

    testWidgets('Si otro la completó en esta ronda, aún se puede empatar', (
      tester,
    ) async {
      await dibujar(
        tester,
        ronda: 3,
        rondas: {
          amarilla: {'luis': 3},
        },
      );

      expect(enFila('zona-$amarilla', 'Vale 8'), findsOneWidget);
    });

    testWidgets('Un empate anterior no gasta lugares', (tester) async {
      await dibujar(
        tester,
        rondas: {
          amarilla: {'luis': 1, 'eva': 1},
        },
      );

      expect(enFila('zona-$amarilla', 'Vale 6'), findsOneWidget);
    });

    testWidgets('La zona propia muestra el lugar ganado', (tester) async {
      await dibujar(
        tester,
        rondas: {
          amarilla: {'luis': 1, 'ana': 2},
        },
      );

      expect(enFila('zona-$amarilla', '2.º · 6 pts'), findsOneWidget);
    });

    testWidgets('El tercer lugar se escribe 3.er', (tester) async {
      await dibujar(
        tester,
        rondas: {
          amarilla: {'luis': 1, 'eva': 2, 'ana': 3},
        },
      );

      expect(enFila('zona-$amarilla', '3.er · 4 pts'), findsOneWidget);
    });

    testWidgets('El cuarto lugar muestra que no ganó puntos', (tester) async {
      await dibujar(
        tester,
        rondas: {
          amarilla: {'luis': 1, 'eva': 2, 'sol': 3, 'ana': 4},
        },
      );

      expect(enFila('zona-$amarilla', '4.º · 0 pts'), findsOneWidget);
    });

    testWidgets('Dos zonas verdes se nombran y valen por separado', (
      tester,
    ) async {
      await dibujar(
        tester,
        rondas: {
          verdes[0]: {'luis': 1, 'eva': 2, 'sol': 3},
        },
      );

      expect(enFila('zona-${verdes[0]}', 'Verde 1'), findsOneWidget);
      expect(enFila('zona-${verdes[0]}', 'Sin puntos'), findsOneWidget);
      expect(enFila('zona-${verdes[1]}', 'Verde 2'), findsOneWidget);
      expect(enFila('zona-${verdes[1]}', 'Vale 4'), findsOneWidget);
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
