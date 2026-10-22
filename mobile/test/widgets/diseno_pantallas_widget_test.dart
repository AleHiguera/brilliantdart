import 'package:brilliant_mobile/historial_dados_view.dart';
import 'package:brilliant_mobile/main.dart';
import 'package:brilliant_mobile/paneles_juego.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  group('Widgets: diseño de las pantallas', () {
    double opacidadNumero(WidgetTester tester, int numero) => tester
        .widget<AnimatedOpacity>(find.byKey(Key('setup-number-$numero')))
        .opacity;

    Future<void> elegirInicial(
      WidgetTester tester,
      String celda,
      int numero,
    ) async {
      await tester.tap(find.byKey(Key('initial-cell-$celda')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('initial-value-$numero')));
      await tester.pumpAndSettle();
    }

    testWidgets('La selección de mapa explica cómo se juega', (tester) async {
      await tester.pumpWidget(const BrilliantApp());
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('how-to-play')),
        200,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );

      expect(find.byKey(const Key('how-to-play')), findsOneWidget);
      expect(find.text('Cómo se juega'), findsOneWidget);
      expect(find.text('Disponible'), findsNWidgets(2));
      expect(find.text('Muy pronto podrás jugarlo.'), findsOneWidget);
      final textosMapa1 = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byKey(const Key('map-choice-1')),
              matching: find.byType(Text),
            ),
          )
          .map((texto) => texto.data)
          .toList();
      expect(textosMapa1, ['Mapa 1', 'Disponible']);
    });

    testWidgets('Los números usados se encienden en la preparación', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: TableroPage()));

      for (var numero = 1; numero <= 6; numero++) {
        expect(opacidadNumero(tester, numero), lessThan(1));
      }

      await elegirInicial(tester, '1-3', 4);

      expect(opacidadNumero(tester, 4), 1);
      expect(opacidadNumero(tester, 1), lessThan(1));
      expect(find.text('1/6'), findsOneWidget);
      expect(
        find.text('Toca las celdas con + y usa cada número una vez.'),
        findsOneWidget,
      );
    });

    testWidgets('Con los seis números aparece el mensaje de listo', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: TableroPage()));

      const celdas = ['1-3', '2-6', '4-2', '4-5', '6-3', '7-5'];
      for (var i = 0; i < celdas.length; i++) {
        await elegirInicial(tester, celdas[i], i + 1);
      }

      expect(
        find.text('¡Listo! Ya puedes comenzar la partida.'),
        findsOneWidget,
      );
      for (var numero = 1; numero <= 6; numero++) {
        expect(opacidadNumero(tester, numero), 1);
      }
    });

    testWidgets('El diálogo marca el número actual y los que están en uso', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: TableroPage()));
      await elegirInicial(tester, '1-3', 2);
      await elegirInicial(tester, '2-6', 5);

      await tester.tap(find.byKey(const Key('initial-cell-1-3')));
      await tester.pumpAndSettle();

      expect(find.text('Elige un número'), findsOneWidget);
      Finder etiqueta(int numero, String texto) => find.descendant(
        of: find.byKey(Key('initial-value-$numero')),
        matching: find.text(texto),
      );
      expect(etiqueta(2, 'Actual'), findsOneWidget);
      expect(etiqueta(5, 'En uso'), findsOneWidget);
      expect(etiqueta(1, 'Libre'), findsOneWidget);
      expect(find.byType(DadoMini), findsWidgets);
    });

    testWidgets('El número de turno avanza al terminar cada turno', (
      tester,
    ) async {
      await abrirTableroCasiLleno(tester, [(4, 6), (1, 3)]);
      Finder turno(int n) => find.text('Turno $n');

      expect(turno(1), findsOneWidget);
      await lanzarDados(tester);
      expect(turno(1), findsOneWidget);

      await tester.tap(find.byKey(const Key('pass-turn-button')));
      await tester.pumpAndSettle();
      expect(turno(2), findsOneWidget);
    });

    testWidgets('Cada opción de ancla muestra sus dos dados', (tester) async {
      await abrirTableroCasiLleno(tester, [(1, 3)]);
      await lanzarDados(tester);

      for (final (ancla, numero) in [(1, 3), (3, 1)]) {
        final dados = tester
            .widgetList<DadoMini>(
              find.descendant(
                of: find.byKey(Key('anchor-option-$ancla')),
                matching: find.byType(DadoMini),
              ),
            )
            .map((dado) => dado.valor)
            .toList();
        expect(dados, [ancla, numero]);
      }
    });

    testWidgets('En pantalla ancha el turno va a la derecha del tablero', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await abrirTableroCasiLleno(tester, [(1, 3)]);

      final tablero = tester.getRect(find.byType(GridView).first);
      final turno = tester.getRect(find.byKey(const Key('turn-panel')));
      final puntuacion = tester.getRect(find.byKey(const Key('score-table')));

      expect(turno.left, greaterThanOrEqualTo(tablero.right));
      expect(puntuacion.top, greaterThan(turno.bottom));
      expect(tablero.height, greaterThan(700 * 0.8));
    });

    testWidgets('En un celular el tablero no se encoge al elegir movimiento', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 860);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await abrirTableroCasiLleno(tester, [(1, 3)]);
      final antes = tester.getRect(find.byType(GridView).first);

      await lanzarDados(tester);
      await tester.tap(find.byKey(const Key('anchor-option-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('candidate-cell-4-7')));
      await tester.pumpAndSettle();

      final despues = tester.getRect(find.byType(GridView).first);
      expect(despues.height, greaterThanOrEqualTo(antes.height * 0.95));
      expect(despues.height, greaterThan(860 * 0.4));

      final confirmar = tester.getRect(
        find.byKey(const Key('confirm-move-button')),
      );
      expect(confirmar.bottom, lessThanOrEqualTo(860));
      expect(confirmar.top, greaterThan(despues.bottom));
    });

    testWidgets('La tarjeta de fin queda entera a la vista en un celular', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 860);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await abrirTableroCasiLleno(tester, [(1, 3)]);
      await jugarUltimaCelda(tester);
      await tester.tap(find.text('Aceptar'));
      await tester.pumpAndSettle();

      final tablero = tester.getRect(find.byType(GridView).first);
      final fin = tester.getRect(find.byKey(const Key('game-finished-panel')));
      expect(fin.top, greaterThanOrEqualTo(tablero.bottom));
      expect(fin.bottom, lessThanOrEqualTo(860));
      expect(find.byKey(const Key('perfect-score')), findsOneWidget);
    });

    testWidgets('Sin puntuación perfecta no aparece el mensaje especial', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PanelFinPartida(
                puntos: 40,
                maximo: 54,
                onNuevaPartida: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Has puntuado 40 puntos'), findsOneWidget);
      expect(find.byKey(const Key('perfect-score')), findsNothing);
    });
  });
}
