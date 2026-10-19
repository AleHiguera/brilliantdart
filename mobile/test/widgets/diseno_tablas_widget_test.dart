import 'package:brilliantdart/historial_dados.dart';
import 'package:brilliantdart/mapa_uno.dart';
import 'package:brilliant_mobile/historial_dados_view.dart';
import 'package:brilliant_mobile/main.dart';
import 'package:brilliant_mobile/tabla_puntuacion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  group('Widgets: diseño de las tablas', () {
    Color? fondoFila(WidgetTester tester, String color) =>
        (tester
                    .widget<AnimatedContainer>(
                      find.byKey(Key('score-row-$color')),
                    )
                    .decoration
                as BoxDecoration?)
            ?.color;

    double? avance(WidgetTester tester) => tester
        .widget<LinearProgressIndicator>(
          find.byKey(const Key('score-progress')),
        )
        .value;

    testWidgets('La barra de progreso va de 0 a 54 puntos', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TablaPuntuacion(tablero: MapaUno.crearTablero()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(avance(tester), 0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TablaPuntuacion(tablero: tableroCasiLleno())),
        ),
      );
      await tester.pumpAndSettle();
      expect(avance(tester), closeTo(50 / 54, 0.001));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TablaPuntuacion(tablero: tableroCompleto())),
        ),
      );
      await tester.pumpAndSettle();
      expect(avance(tester), 1);
    });

    testWidgets('Solo se tiñen los colores con todas sus zonas completas', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TablaPuntuacion(tablero: tableroCasiLleno())),
        ),
      );
      await tester.pumpAndSettle();

      expect(fondoFila(tester, 'verde'), Colors.white);
      for (final color in ['azul', 'rojo', 'morado', 'amarillo']) {
        expect(fondoFila(tester, color), isNot(Colors.white), reason: color);
      }
    });

    testWidgets('El lanzamiento más reciente va arriba y resaltado', (
      tester,
    ) async {
      final historial = HistorialDados()
        ..registrarLanzamiento(1, 2)
        ..registrarLanzamiento(3, 4)
        ..registrarLanzamiento(5, 6);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HistorialDadosView(historial: historial, maxAlturaFilas: 300),
          ),
        ),
      );

      Color bordeFila(int numero) =>
          (tester
                      .widget<Container>(
                        find.byKey(Key('dice-history-row-$numero')),
                      )
                      .decoration
                  as BoxDecoration)
              .border!
              .top
              .color;
      double alturaFila(int numero) =>
          tester.getTopLeft(find.byKey(Key('dice-history-row-$numero'))).dy;

      expect(alturaFila(3), lessThan(alturaFila(2)));
      expect(alturaFila(2), lessThan(alturaFila(1)));
      expect(bordeFila(3), Colors.black);
      expect(bordeFila(2), Colors.transparent);
      expect(bordeFila(1), Colors.transparent);
      expect(
        tester.widget<Text>(find.byKey(const Key('dice-history-count'))).data,
        '3',
      );
    });

    testWidgets('Cada tipo de acción tiene su propia etiqueta', (tester) async {
      final historial = HistorialDados()
        ..registrarLanzamiento(1, 2)
        ..registrarLanzamiento(3, 4)
        ..registrarLanzamiento(5, 6)
        ..registrarLanzamiento(6, 6);
      historial
        ..registrarAccion(1, '1 ancla → coloca 2')
        ..registrarAccion(2, 'Movimiento inválido')
        ..registrarAccion(3, 'Turno pasado');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HistorialDadosView(historial: historial, maxAlturaFilas: 400),
          ),
        ),
      );

      const iconos = {
        1: Icons.check,
        2: Icons.block,
        3: Icons.skip_next,
        4: Icons.hourglass_empty,
      };
      for (final MapEntry(key: numero, value: icono) in iconos.entries) {
        expect(
          find.descendant(
            of: find.byKey(Key('dice-history-action-$numero')),
            matching: find.byIcon(icono),
          ),
          findsOneWidget,
          reason: 'Lanzamiento $numero',
        );
      }
      comprobarFilaHistorial(tester, 4, (6, 6));
    });

    testWidgets('Los dados del historial se dibujan con puntos', (
      tester,
    ) async {
      final historial = HistorialDados()..registrarLanzamiento(3, 5);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: HistorialDadosView(historial: historial)),
        ),
      );

      expect(find.byType(DadoMini), findsNWidgets(2));
      expect(
        find.descendant(
          of: find.byKey(const Key('dice-history-row-1')),
          matching: find.text('3'),
        ),
        findsNothing,
      );
      comprobarFilaHistorial(tester, 1, (3, 5));
    });

    testWidgets('En un celular las tablas caben con un historial largo', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final dados = DadosFijos([(1, 3)]);
      for (var i = 0; i < 8; i++) {
        dados.historial
          ..registrarLanzamiento(i % 6 + 1, 6 - i % 6)
          ..registrarAccion(i + 1, 'Movimiento inválido');
      }
      await tester.pumpWidget(
        MaterialApp(
          home: TableroPage(
            dados: dados,
            tablero: tableroCasiLleno(),
            sonidoVictoria: SonidoFalso(),
            sonidoDados: SonidoFalso(),
          ),
        ),
      );
      await tester.tap(find.text('Comenzar'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('dice-history')), findsOneWidget);
      expect(find.byKey(const Key('score-table')), findsOneWidget);
    });
  });
}
