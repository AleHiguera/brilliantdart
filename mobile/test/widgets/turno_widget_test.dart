import 'package:brilliantdart/mapa_uno.dart';
import 'package:brilliantdart/validador_anclas.dart';
import 'package:brilliant_mobile/main.dart';
import 'package:brilliant_mobile/panel_lanzamiento_dados.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  group('Widgets: turno de juego', () {
    testWidgets('Una opción cuyo número no está en el tablero sale bloqueada', (
      tester,
    ) async {
      final tablero = MapaUno.crearTablero()..colocarDato(3, 3, 2);
      final opcionesElegidas = <OpcionAncla?>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PanelLanzamientoDados(
                dados: DadosFijos([(2, 5)]),
                validadorAnclas: ValidadorAnclas(tablero),
                onOpcionAnclaChanged: opcionesElegidas.add,
                onPasarTurno: () {},
                onHistorialActualizado: () {},
                partidaFinalizada: false,
              ),
            ),
          ),
        ),
      );
      await lanzarDados(tester);
      opcionesElegidas.clear();

      expect(textoEn('anchor-option-5', 'No disponible'), findsOneWidget);
      expect(textoEn('anchor-option-2', 'No disponible'), findsNothing);

      await tester.tap(find.byKey(const Key('anchor-option-5')));
      await tester.pump();
      expect(opcionesElegidas, isEmpty);

      await tester.tap(find.byKey(const Key('anchor-option-2')));
      await tester.pump();
      expect(opcionesElegidas.single?.ancla, 2);
      expect(opcionesElegidas.single?.numeroAColocar, 5);
    });

    testWidgets('Con dados dobles solo aparece una opción', (tester) async {
      await abrirTableroCasiLleno(tester, [(1, 1)]);
      await lanzarDados(tester);

      expect(find.byKey(const Key('anchor-option-1')), findsOneWidget);
      expect(find.text('Ancla: 1  ·  Colocar: 1'), findsOneWidget);
    });

    testWidgets('Avisa cuando la opción elegida no tiene posiciones válidas', (
      tester,
    ) async {
      await abrirTableroCasiLleno(tester, [(1, 4)]);
      await lanzarDados(tester);

      await tester.tap(find.byKey(const Key('anchor-option-4')));
      await tester.pumpAndSettle();

      expect(
        find.text('No hay posiciones válidas para esta opción.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('candidate-cell-4-7')), findsNothing);

      await tester.tap(find.byKey(const Key('anchor-option-1')));
      await tester.pumpAndSettle();

      expect(
        find.text('No hay posiciones válidas para esta opción.'),
        findsNothing,
      );
      expect(find.byKey(const Key('candidate-cell-4-7')), findsOneWidget);
    });

    testWidgets('Pide tocar una celda resaltada y no acepta otras', (
      tester,
    ) async {
      await abrirTableroCasiLleno(tester, [(1, 3)]);
      await lanzarDados(tester);
      await tester.tap(find.byKey(const Key('anchor-option-1')));
      await tester.pumpAndSettle();

      expect(
        find.text('Toca una posición resaltada del tablero.'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('board-cell-1-2')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('movement-summary')), findsNothing);

      await tester.tap(find.byKey(const Key('candidate-cell-4-7')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('movement-summary')), findsOneWidget);
      expect(find.text('Número a colocar: 3'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('movement-summary')),
          matching: find.text('Ancla: 1'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('El resumen del movimiento nunca muestra coordenadas', (
      tester,
    ) async {
      await abrirTableroCasiLleno(tester, [(1, 3)]);
      await lanzarDados(tester);
      await tester.tap(find.byKey(const Key('anchor-option-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('candidate-cell-4-7')));
      await tester.pumpAndSettle();

      final textos = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byKey(const Key('movement-summary')),
              matching: find.byType(Text),
            ),
          )
          .map((texto) => texto.data ?? '')
          .toList();
      expect(textos, isNotEmpty);
      for (final texto in textos) {
        expect(texto, isNot(contains('Posición')));
        expect(texto, isNot(matches(RegExp(r'\(\d+, \d+\)'))));
      }
    });

    testWidgets('No se puede volver a lanzar sin decidir el turno', (
      tester,
    ) async {
      final dados = DadosFijos([(1, 3), (2, 2)]);
      await tester.pumpWidget(
        MaterialApp(
          home: TableroPage(
            dados: dados,
            tablero: tableroCasiLleno(),
            sonidoDados: SonidoFalso(),
          ),
        ),
      );
      await tester.tap(find.text('Comenzar'));
      await tester.pump();
      await lanzarDados(tester);

      await tester.tap(find.byKey(const Key('roll-dice-button')));
      await tester.pump(const Duration(milliseconds: 1300));

      expect(dados.historial.lanzamientos, hasLength(1));
    });
  });
}
