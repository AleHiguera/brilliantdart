import 'package:brilliant_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  group('Widgets: fin de la partida', () {
    testWidgets(
      'Llenar la última celda termina la partida y muestra la puntuación',
      (tester) async {
        final tablero = tableroCasiLleno();
        final dados = DadosFijos([(1, 3)]);
        final sonido = SonidoFalso();

        await tester.pumpWidget(
          MaterialApp(
            home: TableroPage(
              dados: dados,
              tablero: tablero,
              sonidoVictoria: sonido,
              sonidoDados: SonidoFalso(),
            ),
          ),
        );

        await tester.tap(find.text('Comenzar'));
        await tester.pump();
        expect(find.byKey(const Key('game-finished-message')), findsNothing);

        await jugarUltimaCelda(tester);
        expect(sonido.reproducciones, 1);

        expect(tablero.estaLleno, isTrue);
        expect(tablero.puntuacionTotal, 54);

        expect(find.byKey(const Key('game-over-dialog')), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(const Key('game-over-dialog')),
            matching: find.text('Fin de la partida'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const Key('game-over-dialog')),
            matching: find.text('Has puntuado 54 puntos'),
          ),
          findsOneWidget,
        );

        await tester.tap(find.text('Aceptar'));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('game-over-dialog')), findsNothing);
        expect(find.byKey(const Key('game-finished-message')), findsOneWidget);
        expect(
          tester
              .widget<Text>(find.byKey(const Key('game-finished-score')))
              .data,
          'Has puntuado 54 puntos',
        );
        expect(find.byKey(const Key('roll-dice-button')), findsNothing);
        expect(find.text('Lanza los dados para continuar'), findsNothing);
        expect(dados.historial.lanzamientos, hasLength(1));
        expect(sonido.reproducciones, 1);
      },
    );

    testWidgets('El sonido de victoria viene incluido en la app', (
      tester,
    ) async {
      final datos = await rootBundle.load('assets/sonidos/victoria.wav');

      expect(datos.lengthInBytes, greaterThan(44));
      expect(String.fromCharCodes(datos.buffer.asUint8List(0, 4)), 'RIFF');
    });

    testWidgets('El sonido de victoria no suena antes de llenar el tablero', (
      tester,
    ) async {
      final sonido = SonidoFalso();
      await tester.pumpWidget(
        MaterialApp(
          home: TableroPage(
            dados: DadosFijos([(1, 3)]),
            tablero: tableroCasiLleno(),
            sonidoVictoria: sonido,
            sonidoDados: SonidoFalso(),
          ),
        ),
      );

      await tester.tap(find.text('Comenzar'));
      await tester.pump();
      await tester.tap(find.byKey(const Key('roll-dice-button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1300));
      await tester.pumpAndSettle();

      expect(sonido.reproducciones, 0);
      expect(find.byKey(const Key('game-over-dialog')), findsNothing);
    });

    testWidgets(
      'Nueva partida desde el diálogo vuelve a la selección de mapa',
      (tester) async {
        await tester.pumpWidget(const BrilliantApp());
        final navigator = tester.state<NavigatorState>(find.byType(Navigator));
        navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => TableroPage(
              dados: DadosFijos([(1, 3)]),
              tablero: tableroCasiLleno(),
              sonidoVictoria: SonidoFalso(),
              sonidoDados: SonidoFalso(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Comenzar'));
        await tester.pump();
        await jugarUltimaCelda(tester);

        await tester.tap(find.byKey(const Key('new-game-dialog-button')));
        await tester.pumpAndSettle();

        expect(find.text('Elige tu mapa'), findsOneWidget);
        expect(find.byType(TableroPage), findsNothing);
        expect(find.byKey(const Key('game-over-dialog')), findsNothing);
        expect(navigator.canPop(), isFalse);
      },
    );

    testWidgets('Nueva partida desde el panel final empieza un tablero nuevo', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TableroPage(
            dados: DadosFijos([(1, 3)]),
            tablero: tableroCasiLleno(),
            sonidoVictoria: SonidoFalso(),
            sonidoDados: SonidoFalso(),
          ),
        ),
      );

      await tester.tap(find.text('Comenzar'));
      await tester.pump();
      await jugarUltimaCelda(tester);
      await tester.tap(find.text('Aceptar'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('new-game-button')));
      await tester.pumpAndSettle();

      expect(find.text('Elige tu mapa'), findsOneWidget);
      expect(find.byType(TableroPage), findsNothing);

      await tester.tap(find.byKey(const Key('map-choice-1')));
      await tester.pumpAndSettle();

      expect(find.text('0/6'), findsOneWidget);
      expect(find.byKey(const Key('game-finished-message')), findsNothing);
      expect(
        find.text('Coloca los 6 números iniciales para comenzar'),
        findsOneWidget,
      );
    });
  });
}
