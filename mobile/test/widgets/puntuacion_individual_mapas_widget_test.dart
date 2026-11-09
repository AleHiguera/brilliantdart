import 'package:brilliant_mobile/main.dart';
import 'package:brilliantdart/mapa.dart';
import 'package:brilliantdart/mapa_cuatro.dart';
import 'package:brilliantdart/mapa_dos.dart';
import 'package:brilliantdart/mapa_tres.dart';
import 'package:brilliantdart/mapa_uno.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

/// Lo que debe seguir pasando en una partida individual: al colocar el último
/// número de cada mapa se muestran sus puntos de siempre.
const List<(Mapa, (int, int), List<int>, int)> partidas = [
  (mapaUno, (4, 7), [1, 2, 3, 4, 5, 6], 54),
  (mapaDos, (3, 7), [1, 2, 3, 4, 5, 6], 55),
  (mapaTres, (6, 6), [1, 2, 3, 4, 5, 6], 54),
  (mapaCuatro, (2, 4), [6, 2, 3, 4, 5, 1], 50),
];

void main() {
  group('Widgets: puntuación individual de cada mapa', () {
    for (final (mapa, vacia, iniciales, puntos) in partidas) {
      testWidgets('Mapa ${mapa.numero}: termina con $puntos puntos', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: TableroPage(
              mapa: mapa,
              dados: DadosFijos([(1, 3)]),
              tablero: tableroCasiLleno(
                mapa: mapa,
                vacia: vacia,
                valoresIniciales: iniciales,
              ),
              sonidoVictoria: SonidoFalso(),
              sonidoDados: SonidoFalso(),
            ),
          ),
        );
        await tester.tap(find.text('Comenzar'));
        await tester.pump();

        await jugarUltimaCelda(tester, celda: '${vacia.$1}-${vacia.$2}');
        await tester.tap(find.text('Aceptar'));
        await tester.pumpAndSettle();

        expect(find.text('Has puntuado $puntos puntos'), findsOneWidget);
        expect(find.text('$puntos pts'), findsOneWidget);
      });
    }

    testWidgets('Antes de la última jugada aún no hay fin de partida', (
      tester,
    ) async {
      await abrirTableroCasiLleno(tester, [(1, 3)]);

      expect(find.byKey(const Key('game-over-dialog')), findsNothing);
      expect(find.text('Has puntuado 54 puntos'), findsNothing);
    });
  });
}
