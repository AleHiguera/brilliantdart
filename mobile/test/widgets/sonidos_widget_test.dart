import 'package:brilliantdart/mapa_uno.dart';
import 'package:brilliantdart/validador_anclas.dart';
import 'package:brilliant_mobile/main.dart';
import 'package:brilliant_mobile/panel_lanzamiento_dados.dart';
import 'package:brilliant_mobile/sonidos.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  group('Widgets: sonidos', () {
    Widget panelConSonido(
      Sonido sonido, {
      required List<(int, int)> lanzamientos,
      bool partidaFinalizada = false,
      VoidCallback? onPasarTurno,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PanelLanzamientoDados(
              dados: DadosFijos(lanzamientos),
              validadorAnclas: ValidadorAnclas(mapaUno.crearTablero()),
              onOpcionAnclaChanged: (_) {},
              onPasarTurno: onPasarTurno ?? () {},
              onHistorialActualizado: () {},
              partidaFinalizada: partidaFinalizada,
              sonidoDados: sonido,
            ),
          ),
        ),
      );
    }

    testWidgets('Los archivos de sonido vienen incluidos en la app', (
      tester,
    ) async {
      for (final ruta in [Sonido.dados, Sonido.victoria]) {
        final datos = await rootBundle.load('assets/$ruta');

        expect(datos.lengthInBytes, greaterThan(44), reason: ruta);
        expect(
          String.fromCharCodes(datos.buffer.asUint8List(8, 4)),
          'WAVE',
          reason: ruta,
        );
      }
    });

    testWidgets('Los dados suenan al empezar a lanzarlos', (tester) async {
      final sonido = SonidoFalso();
      await tester.pumpWidget(panelConSonido(sonido, lanzamientos: [(1, 2)]));
      expect(sonido.reproducciones, 0);

      await tester.tap(find.byKey(const Key('roll-dice-button')));
      await tester.pump();
      expect(find.text('Lanzando dados...'), findsOneWidget);
      expect(sonido.reproducciones, 1);

      await tester.pump(const Duration(milliseconds: 1300));
      await tester.pumpAndSettle();
      expect(sonido.reproducciones, 1);
    });

    testWidgets('Los dados suenan una vez por cada lanzamiento', (
      tester,
    ) async {
      final sonido = SonidoFalso();
      await tester.pumpWidget(
        panelConSonido(sonido, lanzamientos: [(1, 2), (3, 4), (5, 6)]),
      );

      for (var lanzamiento = 1; lanzamiento <= 3; lanzamiento++) {
        await lanzarDados(tester);
        expect(sonido.reproducciones, lanzamiento);
        await tester.tap(find.byKey(const Key('pass-turn-button')));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('No suenan si el botón está desactivado esperando decisión', (
      tester,
    ) async {
      final sonido = SonidoFalso();
      await tester.pumpWidget(
        panelConSonido(sonido, lanzamientos: [(1, 2), (3, 4)]),
      );
      await lanzarDados(tester);

      await tester.tap(find.byKey(const Key('roll-dice-button')));
      await tester.pump(const Duration(milliseconds: 1300));

      expect(sonido.reproducciones, 1);
    });

    testWidgets('No suenan cuando la partida ya terminó', (tester) async {
      final sonido = SonidoFalso();
      await tester.pumpWidget(
        panelConSonido(sonido, lanzamientos: [(1, 2)], partidaFinalizada: true),
      );

      await tester.tap(find.byKey(const Key('roll-dice-button')));
      await tester.pump(const Duration(milliseconds: 1300));

      expect(sonido.reproducciones, 0);
    });

    testWidgets('En el tablero suenan los dados y al final la victoria', (
      tester,
    ) async {
      final sonidoDados = SonidoFalso();
      final sonidoVictoria = SonidoFalso();
      await tester.pumpWidget(
        MaterialApp(
          home: TableroPage(
            dados: DadosFijos([(2, 6), (1, 3)]),
            tablero: tableroCasiLleno(),
            sonidoDados: sonidoDados,
            sonidoVictoria: sonidoVictoria,
          ),
        ),
      );
      await tester.tap(find.text('Comenzar'));
      await tester.pump();
      expect(sonidoDados.reproducciones, 0);

      await lanzarDados(tester);
      expect(sonidoDados.reproducciones, 1);
      await tester.tap(find.byKey(const Key('pass-turn-button')));
      await tester.pumpAndSettle();
      expect(sonidoVictoria.reproducciones, 0);

      await jugarUltimaCelda(tester);
      expect(sonidoDados.reproducciones, 2);
      expect(sonidoVictoria.reproducciones, 1);
    });
  });
}
