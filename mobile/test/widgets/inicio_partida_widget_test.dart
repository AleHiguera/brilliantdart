import 'package:brilliant_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  group('Widgets: inicio de la partida', () {
    testWidgets('La selección muestra los cuatro mapas disponibles', (
      tester,
    ) async {
      await tester.pumpWidget(const BrilliantApp());

      expect(find.text('Elige tu mapa'), findsOneWidget);
      expect(find.text('Mapa 1'), findsOneWidget);
      expect(find.text('Mapa 2'), findsOneWidget);
      expect(find.text('Mapa 3'), findsOneWidget);
      expect(find.text('Mapa 4'), findsOneWidget);
      expect(find.text('Próximamente'), findsNothing);
      expect(find.text('Disponible'), findsNWidgets(4));

      await tester.tap(find.byKey(const Key('map-choice-1')));
      await tester.pumpAndSettle();

      expect(find.text('Tablero'), findsOneWidget);
      expect(find.byType(GridView), findsOneWidget);
      expect(
        find.text('Coloca los 6 números iniciales para comenzar'),
        findsOneWidget,
      );
      expect(find.text('0/6'), findsOneWidget);
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull,
      );
    });

    testWidgets(
      'Los números iniciales repetidos se mueven y Comenzar se activa con 1 a 6',
      (tester) async {
        final dados = DadosFijos([(1, 6), (6, 4)]);
        await tester.pumpWidget(
          MaterialApp(
            home: TableroPage(dados: dados, sonidoDados: SonidoFalso()),
          ),
        );

        await tester.tap(find.byKey(const Key('initial-cell-1-3')));
        await tester.pumpAndSettle();
        expect(find.textContaining('Celda ('), findsNothing);
        for (var numero = 1; numero <= 6; numero++) {
          expect(find.text('$numero'), findsOneWidget);
        }
        expect(find.text('Vaciar celda'), findsOneWidget);
        await tester.tap(find.byKey(const Key('initial-value-4')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('initial-cell-6-3')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('initial-value-4')));
        await tester.pumpAndSettle();

        expect(
          find.descendant(
            of: find.byKey(const Key('initial-cell-1-3')),
            matching: find.text('+'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const Key('initial-cell-6-3')),
            matching: find.text('4'),
          ),
          findsOneWidget,
        );

        const asignaciones = <String, int>{
          '1-3': 1,
          '2-6': 2,
          '4-2': 3,
          '4-5': 4,
          '6-3': 5,
          '7-5': 6,
        };
        for (final asignacion in asignaciones.entries) {
          await tester.tap(find.byKey(Key('initial-cell-${asignacion.key}')));
          await tester.pumpAndSettle();
          await tester.tap(
            find.byKey(Key('initial-value-${asignacion.value}')),
          );
          await tester.pumpAndSettle();
        }

        expect(
          tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
          isNotNull,
        );
        expect(find.text('6/6'), findsOneWidget);

        await tester.tap(find.text('Comenzar'));
        await tester.pump();
        expect(find.byKey(const Key('roll-dice-button')), findsOneWidget);

        await tester.tap(find.byKey(const Key('roll-dice-button')));
        await tester.pump();
        expect(find.text('Lanzando dados...'), findsOneWidget);

        await tester.pump(const Duration(milliseconds: 1300));
        await tester.pumpAndSettle();

        expect(find.text('Lanzando dados...'), findsNothing);
        expect(find.textContaining(RegExp(r'Dado 1: [1-6]')), findsOneWidget);
        expect(find.textContaining(RegExp(r'Dado 2: [1-6]')), findsOneWidget);

        final textoDado1 = tester.widget<Text>(find.textContaining('Dado 1:'));
        final textoDado2 = tester.widget<Text>(find.textContaining('Dado 2:'));
        final valorDado1 = int.parse(textoDado1.data!.split(': ').last);
        final valorDado2 = int.parse(textoDado2.data!.split(': ').last);
        expect((valorDado1, valorDado2), (1, 6));
        expect(
          tester
              .widget<FilledButton>(find.byKey(const Key('roll-dice-button')))
              .onPressed,
          isNull,
        );
        expect(find.byKey(const Key('pass-turn-button')), findsOneWidget);
        expect(
          tester.getSize(find.byKey(const Key('pass-turn-button'))).width,
          lessThan(180),
        );
        final opcionDado1 = find.byKey(Key('anchor-option-$valorDado1'));
        final opcionDado2 = find.byKey(Key('anchor-option-$valorDado2'));

        expect(opcionDado1, findsOneWidget);
        expect(opcionDado2, findsOneWidget);
        await tester.tap(opcionDado1);
        await tester.pumpAndSettle();
        expect(
          find.descendant(
            of: opcionDado1,
            matching: find.byIcon(Icons.check_circle),
          ),
          findsOneWidget,
        );

        const primeraPosicion = Key('candidate-cell-1-2');
        expect(find.byKey(primeraPosicion), findsOneWidget);
        await tester.tap(find.byKey(primeraPosicion));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('movement-summary')), findsOneWidget);
        expect(find.text('Número a colocar: $valorDado2'), findsOneWidget);

        await tester.tap(find.byKey(const Key('confirm-move-button')));
        await tester.pumpAndSettle();
        expect(
          find.descendant(
            of: find.byKey(const Key('board-cell-1-2')),
            matching: find.text('6'),
          ),
          findsOneWidget,
        );
        expect(
          dados.historial.lanzamientos[0].accionRealizada,
          '1 ancla → coloca 6',
        );
        comprobarFilaHistorial(tester, 1, (1, 6), accion: '1 ancla → coloca 6');
        expect(
          tester
              .widget<FilledButton>(find.byKey(const Key('roll-dice-button')))
              .onPressed,
          isNotNull,
        );

        await tester.tap(find.byKey(const Key('roll-dice-button')));
        await tester.pump();
        expect(find.text('Lanzando dados...'), findsOneWidget);
        await tester.pump(const Duration(milliseconds: 1300));
        await tester.pumpAndSettle();

        expect(find.text('Dado 1: 6'), findsOneWidget);
        expect(find.text('Dado 2: 4'), findsOneWidget);
        await tester.tap(find.byKey(const Key('anchor-option-6')));
        await tester.pumpAndSettle();

        const posicionJuntoAlNuevoAncla = Key('candidate-cell-2-2');
        expect(find.byKey(posicionJuntoAlNuevoAncla), findsOneWidget);
        await tester.tap(find.byKey(posicionJuntoAlNuevoAncla));
        await tester.pumpAndSettle();
        expect(find.text('Número a colocar: 4'), findsOneWidget);

        await tester.tap(find.byKey(const Key('confirm-move-button')));
        await tester.pumpAndSettle();
        expect(
          find.descendant(
            of: find.byKey(const Key('board-cell-2-2')),
            matching: find.text('4'),
          ),
          findsOneWidget,
        );
        expect(
          dados.historial.lanzamientos[0].accionRealizada,
          '1 ancla → coloca 6',
        );
        expect(
          dados.historial.lanzamientos[1].accionRealizada,
          '6 ancla → coloca 4',
        );
      },
    );
  });
}
