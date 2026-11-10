import 'package:brilliant_mobile/panel_fin_compartido.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> mostrarFinal(
  WidgetTester tester, {
  required Map<String, int> puntos,
  required List<String> ganadores,
  required String usuario,
  required int meta,
}) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: PanelFinCompartido(
          ganadores: ganadores,
          usuario: usuario,
          puntos: puntos,
          jugadores: puntos.keys.toList(),
          meta: meta,
          onVolver: () {},
        ),
      ),
    ),
  ),
);

Finder enPuesto(String jugador, String texto) => find.descendant(
  of: find.byKey(Key('clasificacion-$jugador')),
  matching: find.text(texto),
);

/// De arriba hacia abajo, en qué orden quedaron los jugadores.
List<String> ordenEnPantalla(WidgetTester tester, Iterable<String> jugadores) =>
    [...jugadores]..sort(
      (a, b) => tester
          .getTopLeft(find.byKey(Key('clasificacion-$a')))
          .dy
          .compareTo(tester.getTopLeft(find.byKey(Key('clasificacion-$b'))).dy),
    );

void main() {
  group('Widgets: ejemplos de la especificación', () {
    const ejemploA = {'jugador1': 24, 'jugador2': 21, 'jugador3': 17};
    const ejemploB = {
      'jugador1': 19,
      'jugador2': 13,
      'jugador3': 20,
      'jugador4': 16,
      'jugador5': 10,
    };

    testWidgets('A: el jugador 1 gana con 24 y los demás van por puntos', (
      tester,
    ) async {
      await mostrarFinal(
        tester,
        puntos: ejemploA,
        ganadores: ['jugador1'],
        usuario: 'jugador2',
        meta: 24,
      );

      expect(find.text('Ganó @jugador1 con 24 puntos'), findsOneWidget);
      expect(find.text('Se alcanzó la meta de 24 puntos.'), findsOneWidget);
      expect(ordenEnPantalla(tester, ejemploA.keys), [
        'jugador1',
        'jugador2',
        'jugador3',
      ]);
      expect(enPuesto('jugador1', '1.º'), findsOneWidget);
      expect(enPuesto('jugador1', '24 pts'), findsOneWidget);
      expect(enPuesto('jugador2', '2.º'), findsOneWidget);
      expect(enPuesto('jugador2', '21 pts'), findsOneWidget);
      expect(enPuesto('jugador3', '3.er'), findsOneWidget);
      expect(enPuesto('jugador3', '17 pts'), findsOneWidget);
      expect(find.text('Quedaste en 2.º lugar'), findsOneWidget);
    });

    testWidgets('B: el jugador 3 gana con 20 y los demás van por puntos', (
      tester,
    ) async {
      await mostrarFinal(
        tester,
        puntos: ejemploB,
        ganadores: ['jugador3'],
        usuario: 'jugador3',
        meta: 20,
      );

      expect(find.text('¡Ganaste!'), findsOneWidget);
      expect(find.text('Ganó @jugador3 (tú) con 20 puntos'), findsOneWidget);
      expect(ordenEnPantalla(tester, ejemploB.keys), [
        'jugador3',
        'jugador1',
        'jugador4',
        'jugador2',
        'jugador5',
      ]);
      expect(enPuesto('jugador1', '2.º'), findsOneWidget);
      expect(enPuesto('jugador4', '3.er'), findsOneWidget);
      expect(enPuesto('jugador2', '4.º'), findsOneWidget);
      expect(enPuesto('jugador5', '5.º'), findsOneWidget);
      expect(enPuesto('jugador5', '10 pts'), findsOneWidget);
    });

    Finder enGanadores(String texto) => find.descendant(
      of: find.byKey(const Key('clasificacion-ganadores')),
      matching: find.text(texto),
    );

    testWidgets('A: la palabra Ganador va sobre el jugador 1', (tester) async {
      await mostrarFinal(
        tester,
        puntos: ejemploA,
        ganadores: ['jugador1'],
        usuario: 'jugador2',
        meta: 24,
      );

      expect(enGanadores('Ganador'), findsOneWidget);
      expect(enGanadores('@jugador1'), findsOneWidget);
      expect(enGanadores('@jugador2 (tú)'), findsNothing);
      expect(enGanadores('@jugador3'), findsNothing);
      expect(
        tester.getTopLeft(enGanadores('Ganador')).dy,
        lessThan(
          tester.getTopLeft(find.byKey(const Key('clasificacion-jugador1'))).dy,
        ),
      );
    });

    testWidgets('B: Ganador solo encabeza al jugador 3', (tester) async {
      await mostrarFinal(
        tester,
        puntos: ejemploB,
        ganadores: ['jugador3'],
        usuario: 'jugador1',
        meta: 20,
      );

      expect(enGanadores('Ganador'), findsOneWidget);
      expect(enGanadores('@jugador3'), findsOneWidget);
      for (final otro in ['jugador2', 'jugador4', 'jugador5']) {
        expect(enGanadores('@$otro'), findsNothing);
      }
    });

    testWidgets('Con un empate en primero dice Ganadores', (tester) async {
      await mostrarFinal(
        tester,
        puntos: const {'ana': 26, 'luis': 26, 'eva': 10},
        ganadores: ['ana', 'luis'],
        usuario: 'eva',
        meta: 26,
      );

      expect(enGanadores('Ganadores'), findsOneWidget);
      expect(enGanadores('Ganador'), findsNothing);
      expect(enGanadores('@ana'), findsOneWidget);
      expect(enGanadores('@luis'), findsOneWidget);
      expect(enGanadores('@eva (tú)'), findsNothing);
    });

    testWidgets('Los seis jugadores ven la misma clasificación', (
      tester,
    ) async {
      const puntos = {'j1': 22, 'j2': 6, 'j3': 4, 'j4': 0, 'j5': 0, 'j6': 0};
      List<String>? ordenDeReferencia;

      for (final usuario in puntos.keys) {
        await mostrarFinal(
          tester,
          puntos: puntos,
          ganadores: ['j1'],
          usuario: usuario,
          meta: 20,
        );

        final orden = ordenEnPantalla(tester, puntos.keys);
        ordenDeReferencia ??= orden;
        expect(orden, ordenDeReferencia, reason: 'visto por $usuario');
        expect(find.text('Se alcanzó la meta de 20 puntos.'), findsOneWidget);
        expect(enPuesto('j1', '1.º'), findsOneWidget);
        expect(enPuesto('j4', '4.º (empate)'), findsOneWidget);
        expect(enPuesto('j6', '4.º (empate)'), findsOneWidget);
        expect(
          find.text(
            usuario == 'j1'
                ? 'Ganó @j1 (tú) con 22 puntos'
                : 'Ganó @j1 con 22 puntos',
          ),
          findsOneWidget,
          reason: 'visto por $usuario',
        );
      }
    });

    testWidgets('B cabe en un celular', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await mostrarFinal(
        tester,
        puntos: ejemploB,
        ganadores: ['jugador3'],
        usuario: 'jugador1',
        meta: 20,
      );

      expect(tester.takeException(), isNull);
    });
  });
}
