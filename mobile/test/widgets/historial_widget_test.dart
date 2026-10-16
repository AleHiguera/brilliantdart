import 'package:brilliantdart/historial_dados.dart';
import 'package:brilliantdart/tablero.dart';
import 'package:brilliantdart/validador_anclas.dart';
import 'package:brilliant_mobile/historial_dados_view.dart';
import 'package:brilliant_mobile/main.dart';
import 'package:brilliant_mobile/panel_lanzamiento_dados.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  group('Widgets: historial de dados', () {
    testWidgets('El historial muestra los resultados guardados de los dados', (
      tester,
    ) async {
      final historial = HistorialDados()
        ..registrarLanzamiento(2, 6)
        ..registrarLanzamiento(4, 1);
      historial.registrarAccion(1, '5 ancla → coloca 2');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: HistorialDadosView(historial: historial)),
        ),
      );

      comprobarFilaHistorial(tester, 1, (2, 6), accion: '5 ancla → coloca 2');
      comprobarFilaHistorial(tester, 2, (4, 1));
      expect(find.text('Historial de dados'), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('dice-history-count'))).data,
        '2',
      );

      // El lanzamiento más reciente aparece primero.
      expect(
        tester.getTopLeft(find.byKey(const Key('dice-history-row-2'))).dy,
        lessThan(
          tester.getTopLeft(find.byKey(const Key('dice-history-row-1'))).dy,
        ),
      );
    });

    testWidgets(
      'Cuatro lanzamientos seguidos quedan visibles en el historial',
      (tester) async {
        final dados = DadosFijos([(5, 5), (2, 6), (4, 1), (3, 6)]);
        final tablero = Tablero();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: StatefulBuilder(
                  builder: (context, setState) => Column(
                    children: [
                      HistorialDadosView(historial: dados.historial),
                      PanelLanzamientoDados(
                        dados: dados,
                        validadorAnclas: ValidadorAnclas(tablero),
                        onOpcionAnclaChanged: (_) {},
                        onPasarTurno: () {},
                        onHistorialActualizado: () => setState(() {}),
                        partidaFinalizada: false,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

        const resultados = [(5, 5), (2, 6), (4, 1), (3, 6)];
        for (var indice = 0; indice < resultados.length; indice++) {
          await tester.tap(find.byKey(const Key('roll-dice-button')));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 1300));
          await tester.pumpAndSettle();

          expect(
            find.text('No se puede realizar ningún movimiento'),
            findsOneWidget,
          );
          final numeroLanzamiento = indice + 1;
          comprobarFilaHistorial(tester, numeroLanzamiento, resultados[indice]);
          if (indice > 0) {
            comprobarFilaHistorial(
              tester,
              numeroLanzamiento - 1,
              resultados[indice - 1],
              accion: 'Movimiento inválido',
            );
          }
          expect(dados.historial.lanzamientos, hasLength(numeroLanzamiento));

          if (indice < resultados.length - 1) {
            await tester.tap(find.byKey(const Key('pass-turn-button')));
            await tester.pumpAndSettle();
            expect(
              dados.historial.lanzamientos[indice].accionRealizada,
              'Movimiento inválido',
            );
          }
        }

        expect(dados.historial.lanzamientos, hasLength(4));
      },
    );

    testWidgets(
      'En pantalla ancha el historial aparece a la derecha del tablero',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final dados = DadosFijos([])..historial.registrarLanzamiento(2, 6);
        await tester.pumpWidget(
          MaterialApp(
            home: TableroPage(dados: dados, sonidoDados: SonidoFalso()),
          ),
        );

        final tablero = tester.getRect(find.byType(GridView).first);
        final historial = tester.getRect(find.byKey(const Key('dice-history')));
        final puntuacion = tester.getRect(find.byKey(const Key('score-table')));
        expect(historial.left, greaterThanOrEqualTo(tablero.right));
        expect(puntuacion.left, greaterThanOrEqualTo(tablero.right));
        expect(find.text('Historial de dados'), findsOneWidget);
        expect(find.text('Puntuación'), findsOneWidget);
        expect(find.text('0 pts'), findsOneWidget);
      },
    );
  });
}
