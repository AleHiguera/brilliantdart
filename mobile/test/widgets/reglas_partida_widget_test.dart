import 'package:brilliant_mobile/main.dart';
import 'package:brilliant_mobile/sonidos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  group('Widgets: reglas de la pantalla durante la partida', () {
    Future<void> elegirCelda(WidgetTester tester) async {
      await lanzarDados(tester);
      await tester.tap(find.byKey(const Key('anchor-option-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('candidate-cell-4-7')));
      await tester.pumpAndSettle();
    }

    testWidgets('Tras comenzar ya no se pueden cambiar los números iniciales', (
      tester,
    ) async {
      await abrirTableroCasiLleno(tester, [(1, 3)]);

      await tester.tap(find.byKey(const Key('initial-cell-1-3')));
      await tester.pumpAndSettle();

      expect(find.byType(SimpleDialog), findsNothing);
      expect(textoEn('initial-cell-1-3', '1'), findsOneWidget);
    });

    testWidgets('La celda elegida muestra el número antes de confirmar', (
      tester,
    ) async {
      await abrirTableroCasiLleno(tester, [(1, 3)]);
      await elegirCelda(tester);

      expect(textoEn('candidate-cell-4-7', '3'), findsOneWidget);
    });

    testWidgets('Cambiar de opción borra la celda elegida', (tester) async {
      await abrirTableroCasiLleno(tester, [(1, 3)]);
      await elegirCelda(tester);
      expect(find.byKey(const Key('movement-summary')), findsOneWidget);

      await tester.tap(find.byKey(const Key('anchor-option-3')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('movement-summary')), findsNothing);
      expect(textoEn('candidate-cell-4-7', '3'), findsNothing);
    });

    testWidgets('Pasar turno con una opción elegida limpia el tablero', (
      tester,
    ) async {
      await abrirTableroCasiLleno(tester, [(1, 3), (2, 2)]);
      await elegirCelda(tester);

      await tester.tap(find.byKey(const Key('pass-turn-button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('movement-summary')), findsNothing);
      expect(find.byKey(const Key('candidate-cell-4-7')), findsNothing);
      expect(find.byKey(const Key('board-cell-4-7')), findsOneWidget);
      comprobarFilaHistorial(tester, 1, (1, 3), accion: 'Turno pasado');
    });

    testWidgets('Con la partida terminada el tablero no ofrece jugadas', (
      tester,
    ) async {
      await abrirTableroCasiLleno(tester, [(1, 3)]);
      await jugarUltimaCelda(tester);
      await tester.tap(find.text('Aceptar'));
      await tester.pumpAndSettle();

      final candidatas = find.byWidgetPredicate(
        (widget) =>
            widget.key is ValueKey<String> &&
            (widget.key! as ValueKey<String>).value.startsWith('candidate-'),
      );
      expect(candidatas, findsNothing);

      await tester.tap(find.byKey(const Key('board-cell-4-7')));
      await tester.pumpAndSettle();
      expect(find.byType(SimpleDialog), findsNothing);
      expect(find.byKey(const Key('movement-summary')), findsNothing);
    });

    testWidgets('Girar el celular a mitad de partida no pierde nada', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(400, 860);
      addTearDown(tester.view.reset);
      await abrirTableroCasiLleno(tester, [(4, 6), (1, 3)]);
      await lanzarDados(tester);
      await tester.tap(find.byKey(const Key('pass-turn-button')));
      await tester.pumpAndSettle();
      await elegirCelda(tester);

      tester.view.physicalSize = const Size(1000, 700);
      await tester.pumpAndSettle();

      expect(find.text('Turno 2'), findsOneWidget);
      expect(find.byKey(const Key('movement-summary')), findsOneWidget);
      comprobarFilaHistorial(tester, 1, (4, 6), accion: 'Movimiento inválido');
      comprobarFilaHistorial(tester, 2, (1, 3));

      await tester.tap(find.byKey(const Key('confirm-move-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('game-over-dialog')), findsOneWidget);
    });

    testWidgets('Al salir del tablero se cierran los sonidos', (tester) async {
      final sonidoDados = SonidoFalso();
      final sonidoVictoria = SonidoFalso();
      await tester.pumpWidget(
        MaterialApp(
          home: TableroPage(
            sonidoDados: sonidoDados,
            sonidoVictoria: sonidoVictoria,
          ),
        ),
      );

      await tester.pumpWidget(const MaterialApp(home: SizedBox()));

      expect(sonidoDados.cierres, 1);
      expect(sonidoVictoria.cierres, 1);
    });

    testWidgets('Atrás vuelve a los mapas y el tablero empieza de cero', (
      tester,
    ) async {
      await tester.pumpWidget(const BrilliantApp());
      await tester.tap(find.byKey(const Key('map-choice-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('initial-cell-1-3')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('initial-value-5')));
      await tester.pumpAndSettle();
      expect(find.text('1/6'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Elige tu mapa'), findsOneWidget);

      await tester.tap(find.byKey(const Key('map-choice-1')));
      await tester.pumpAndSettle();
      expect(find.text('0/6'), findsOneWidget);
      expect(textoEn('initial-cell-1-3', '+'), findsOneWidget);
    });

    testWidgets('El sonido real no falla aunque no haya audio disponible', (
      tester,
    ) async {
      // En las pruebas no hay sistema de audio y el reproductor nunca
      // responde. La app lanza el sonido sin esperarlo, así que aquí se hace
      // igual: no debe lanzar errores ni romper la pantalla.
      final sonido = SonidoAsset(Sonido.dados);
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));

      expect(() => sonido.reproducir(), returnsNormally);
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(() => sonido.dispose(), returnsNormally);
    });
  });
}
