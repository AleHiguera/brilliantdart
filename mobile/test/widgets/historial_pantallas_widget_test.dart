import 'package:brilliantdart/historial_dados.dart';
import 'package:brilliant_mobile/historial_dados_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  group('Widgets: historial y pantallas pequeñas', () {
    testWidgets('Un historial vacío dice Sin lanzamientos', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: HistorialDadosView(historial: HistorialDados())),
        ),
      );

      expect(find.text('Sin lanzamientos'), findsOneWidget);
    });

    testWidgets('En un celular el historial aparece debajo del tablero', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await abrirTableroCasiLleno(tester, [(1, 3)]);

      final tablero = tester.getRect(find.byType(GridView));
      final historial = tester.getRect(find.byKey(const Key('dice-history')));
      expect(historial.top, greaterThanOrEqualTo(tablero.bottom));
      expect(find.byKey(const Key('score-table')), findsOneWidget);

      await jugarUltimaCelda(tester);
      expect(find.byKey(const Key('game-over-dialog')), findsOneWidget);
    });
  });
}
