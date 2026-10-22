import 'package:brilliantdart/mapa_uno.dart';
import 'package:brilliant_mobile/tabla_puntuacion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  group('Widgets: puntuación en pantalla', () {
    testWidgets('Un tablero nuevo muestra 0 puntos', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TablaPuntuacion(tablero: mapaUno.crearTablero()),
          ),
        ),
      );

      expect(find.text('0 pts'), findsOneWidget);
      expect(textoEn('score-row-amarillo', '0/1'), findsOneWidget);
      for (final color in ['morado', 'verde', 'azul', 'rojo']) {
        expect(textoEn('score-row-$color', '0/2'), findsOneWidget);
      }
    });

    testWidgets('Un tablero completo muestra los puntos de cada color', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TablaPuntuacion(tablero: tableroCompleto())),
        ),
      );

      const esperado = {
        'morado': ('2/2', '12'),
        'amarillo': ('1/1', '8'),
        'verde': ('2/2', '8'),
        'azul': ('2/2', '14'),
        'rojo': ('2/2', '12'),
      };
      for (final MapEntry(key: color, value: (hechas, puntos))
          in esperado.entries) {
        expect(textoEn('score-row-$color', hechas), findsOneWidget);
        expect(textoEn('score-row-$color', puntos), findsOneWidget);
      }
      expect(find.text('54 pts'), findsOneWidget);
    });

    testWidgets('La tabla se actualiza al completar una zona jugando', (
      tester,
    ) async {
      await abrirTableroCasiLleno(tester, [(1, 3)]);

      expect(find.text('50 pts'), findsOneWidget);
      expect(textoEn('score-row-verde', '1/2'), findsOneWidget);

      await jugarUltimaCelda(tester);
      await tester.tap(find.text('Aceptar'));
      await tester.pumpAndSettle();

      expect(find.text('54 pts'), findsOneWidget);
      expect(textoEn('score-row-verde', '2/2'), findsOneWidget);
      expect(textoEn('board-cell-4-7', '3'), findsOneWidget);
      comprobarFilaHistorial(tester, 1, (1, 3), accion: '1 ancla → coloca 3');
    });
  });
}
