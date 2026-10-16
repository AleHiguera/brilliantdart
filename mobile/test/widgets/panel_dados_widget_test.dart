import 'package:brilliantdart/mapa_uno.dart';
import 'package:brilliantdart/tablero.dart';
import 'package:brilliantdart/validador_anclas.dart';
import 'package:brilliant_mobile/panel_lanzamiento_dados.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  group('Widgets: panel de dados', () {
    testWidgets(
      'Pasar turno con un movimiento válido registra "Turno pasado"',
      (tester) async {
        final tablero = MapaUno.crearTablero();
        tablero.colocarDato(0, 2, 2);
        final dados = DadosFijos([(2, 6)]);
        final validador = ValidadorAnclas(tablero);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: PanelLanzamientoDados(
                  dados: dados,
                  validadorAnclas: validador,
                  onOpcionAnclaChanged: (_) {},
                  onPasarTurno: () {},
                  onHistorialActualizado: () {},
                  partidaFinalizada: false,
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.byKey(const Key('roll-dice-button')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1300));
        await tester.pumpAndSettle();

        expect(
          find.text('No se puede realizar ningún movimiento'),
          findsNothing,
        );
        expect(find.byKey(const Key('candidate-cell-1-4')), findsNothing);
        expect(find.byKey(const Key('pass-turn-button')), findsOneWidget);

        await tester.tap(find.byKey(const Key('pass-turn-button')));
        expect(
          dados.historial.lanzamientos.single.accionRealizada,
          'Turno pasado',
        );
        expect(tablero.obtenerCelda(0, 2).valor, 2);
        expect(tablero.valoresColocados, {2});
      },
    );

    testWidgets(
      'Sin movimiento válido se pasa el turno sin colocar ningún número',
      (tester) async {
        final tablero = Tablero();
        final dados = DadosFijos([(5, 5), (3, 4)]);
        final validador = ValidadorAnclas(tablero);
        var turnosPasados = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: PanelLanzamientoDados(
                  dados: dados,
                  validadorAnclas: validador,
                  onOpcionAnclaChanged: (_) {},
                  onPasarTurno: () => turnosPasados++,
                  onHistorialActualizado: () {},
                  partidaFinalizada: false,
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.byKey(const Key('roll-dice-button')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1300));
        await tester.pumpAndSettle();

        expect(
          find.text('No se puede realizar ningún movimiento'),
          findsOneWidget,
        );
        expect(
          find.text(
            'Ninguno de los números puede colocarse respetando las reglas del tablero.',
          ),
          findsOneWidget,
        );
        expect(
          tester
              .widget<FilledButton>(find.byKey(const Key('roll-dice-button')))
              .onPressed,
          isNull,
        );
        expect(tablero.valoresColocados, isEmpty);

        await tester.tap(find.byKey(const Key('pass-turn-button')));
        expect(turnosPasados, 1);
        expect(
          dados.historial.lanzamientos.first.accionRealizada,
          'Movimiento inválido',
        );
        await tester.pump();
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

        expect(find.text('Dado 1: 3'), findsOneWidget);
        expect(find.text('Dado 2: 4'), findsOneWidget);
        expect(
          find.text('No se puede realizar ningún movimiento'),
          findsOneWidget,
        );
        expect(tablero.valoresColocados, isEmpty);
      },
    );

    testWidgets(
      'Con la partida terminada el botón de lanzar está desactivado',
      (tester) async {
        final dados = DadosFijos([(1, 2)]);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: PanelLanzamientoDados(
                  dados: dados,
                  validadorAnclas: ValidadorAnclas(Tablero()),
                  onOpcionAnclaChanged: (_) {},
                  onPasarTurno: () {},
                  onHistorialActualizado: () {},
                  partidaFinalizada: true,
                ),
              ),
            ),
          ),
        );

        expect(
          tester
              .widget<FilledButton>(find.byKey(const Key('roll-dice-button')))
              .onPressed,
          isNull,
        );

        await tester.tap(find.byKey(const Key('roll-dice-button')));
        await tester.pump(const Duration(milliseconds: 1300));

        expect(find.text('Lanzando dados...'), findsNothing);
        expect(dados.historial.lanzamientos, isEmpty);
      },
    );
  });
}
