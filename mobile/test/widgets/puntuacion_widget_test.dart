import 'package:brilliantdart/constructor_tablero.dart';
import 'package:brilliantdart/mapa_uno.dart';
import 'package:brilliantdart/tablero.dart';
import 'package:brilliantdart/tipoo.dart';
import 'package:brilliant_mobile/colores_zonas.dart';
import 'package:brilliant_mobile/tabla_puntuacion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

/// Tablero todo verde con 3 celdas grises separadas, unidas en una zona.
Tablero tableroConGris() => ConstructorTablero(
  tiposPorCelda: List.generate(
    7,
    (fila) => List.generate(
      7,
      (columna) => [(0, 3), (3, 0), (6, 6)].contains((fila, columna))
          ? TipoZona.gris
          : TipoZona.verde,
    ),
  ),
  crearTipo: (tipo) => Tipo(
    tipo: tipo,
    color: tipo.name,
    regla: 'regla',
    puntuacion: tipo == TipoZona.gris ? 3 : 4,
  ),
  tiposUnidos: const {TipoZona.gris},
).construir();

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

    testWidgets('El Mapa 1 no muestra fila gris', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TablaPuntuacion(tablero: mapaUno.crearTablero()),
          ),
        ),
      );

      expect(find.byKey(const Key('score-row-gris')), findsNothing);
      expect(find.text('Gris'), findsNothing);
      for (final color in ['morado', 'amarillo', 'verde', 'azul', 'rojo']) {
        expect(find.byKey(Key('score-row-$color')), findsOneWidget);
      }
    });

    testWidgets('Un tablero con gris muestra su fila Gris', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TablaPuntuacion(tablero: tableroConGris())),
        ),
      );

      expect(find.byKey(const Key('score-row-gris')), findsOneWidget);
      expect(textoEn('score-row-gris', 'Gris'), findsOneWidget);
      expect(textoEn('score-row-gris', '0/1'), findsOneWidget);
    });

    testWidgets('Solo muestra filas de los colores que tiene el tablero', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TablaPuntuacion(tablero: tableroConGris())),
        ),
      );

      expect(find.byKey(const Key('score-row-verde')), findsOneWidget);
      for (final color in ['morado', 'amarillo', 'azul', 'rojo']) {
        expect(find.byKey(Key('score-row-$color')), findsNothing);
      }
    });

    testWidgets('Completar los grises con el mismo número suma 3 puntos', (
      tester,
    ) async {
      final tablero = tableroConGris()
        ..colocarDato(0, 3, 5)
        ..colocarDato(3, 0, 5)
        ..colocarDato(6, 6, 5);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TablaPuntuacion(tablero: tablero)),
        ),
      );

      expect(textoEn('score-row-gris', '1/1'), findsOneWidget);
      expect(textoEn('score-row-gris', '3'), findsOneWidget);
      expect(find.text('3 pts'), findsOneWidget);
    });

    test('El gris tiene su propio color en la app', () {
      expect(coloresZonas[TipoZona.gris], const Color(0xFF9E9E9E));
      expect(coloresZonas.keys.toSet(), TipoZona.values.toSet());
    });
  });
}
