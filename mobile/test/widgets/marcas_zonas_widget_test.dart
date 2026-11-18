// Prueba de widgets: el tablero marca qué pedazos de color son la misma zona,
// la resalta entera al mantener presionado y la lista de reglas lo explica.

import 'package:brilliantdart/leyenda_reglas.dart';
import 'package:brilliantdart/mapa.dart';
import 'package:brilliantdart/mapa_cuatro.dart';
import 'package:brilliantdart/mapa_uno.dart';
import 'package:brilliantdart/marcas_zonas.dart';
import 'package:brilliant_mobile/main.dart';
import 'package:brilliant_mobile/panel_reglas.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  group('Widgets: marcas de las zonas', () {
    Future<void> abrir(WidgetTester tester, {Mapa? mapa}) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TableroPage(
            mapa: mapa ?? mapaUno,
            sonidoDados: SonidoFalso(),
            sonidoVictoria: SonidoFalso(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    /// Las celdas cuentan filas y columnas desde 1, como sus claves.
    Finder marcaEn(int fila, int columna) =>
        find.byKey(Key('marca-zona-$fila-$columna'));

    String textoMarca(WidgetTester tester, int fila, int columna) => tester
        .widget<Text>(
          find.descendant(
            of: marcaEn(fila, columna),
            matching: find.byType(Text),
          ),
        )
        .data!;

    /// Si la celda se ve apagada (otra zona está resaltada).
    bool apagada(WidgetTester tester, int fila, int columna) => tester
        .widgetList<Container>(
          find.descendant(
            of: find.byKey(Key('zona-celda-$fila-$columna')),
            matching: find.byType(Container),
          ),
        )
        .any((c) => c.foregroundDecoration != null);

    /// Mantiene presionada la celda y devuelve el dedo, sin soltarlo.
    Future<TestGesture> mantener(
      WidgetTester tester,
      int fila,
      int columna,
    ) async {
      final celda = find.byKey(Key('zona-celda-$fila-$columna'));
      await tester.ensureVisible(celda);
      await tester.pumpAndSettle();
      final dedo = await tester.startGesture(tester.getCenter(celda));
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
      return dedo;
    }

    testWidgets('Cada pedazo de una zona partida lleva la misma marca', (
      tester,
    ) async {
      await abrir(tester);
      final amarilla = MarcasZonas(
        mapaUno,
      ).marcas.singleWhere((m) => m.texto == 'A1');

      expect(amarilla.celdasMarca, hasLength(5));
      for (final (fila, columna) in amarilla.celdasMarca) {
        expect(textoMarca(tester, fila + 1, columna + 1), 'A1');
      }
    });

    testWidgets('Dos zonas verdes llevan marcas distintas', (tester) async {
      await abrir(tester);

      final textos = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byWidgetPredicate(
                (w) =>
                    w.key is ValueKey<String> &&
                    (w.key! as ValueKey<String>).value.startsWith(
                      'marca-zona-',
                    ),
              ),
              matching: find.byType(Text),
            ),
          )
          .map((t) => t.data)
          .toSet();

      expect(textos, containsAll(['V1', 'V2', 'R1', 'R2']));
    });

    testWidgets('Una celda que no empieza un pedazo no lleva marca', (
      tester,
    ) async {
      await abrir(tester);
      final conMarca = {
        for (final m in MarcasZonas(mapaUno).marcas)
          for (final (f, c) in m.celdasMarca) (f + 1, c + 1),
      };

      for (var fila = 1; fila <= 7; fila++) {
        for (var columna = 1; columna <= 7; columna++) {
          expect(
            marcaEn(fila, columna),
            conMarca.contains((fila, columna)) ? findsOneWidget : findsNothing,
          );
        }
      }
    });

    testWidgets('Mapa 4: las dos zonas rojas, cada una en sus dos pedazos', (
      tester,
    ) async {
      await abrir(tester, mapa: mapaCuatro);
      final marcas = MarcasZonas(mapaCuatro).marcas;

      for (final texto in ['R1', 'R2']) {
        final roja = marcas.singleWhere((m) => m.texto == texto);
        expect(roja.celdasMarca, hasLength(2));
        for (final (fila, columna) in roja.celdasMarca) {
          expect(textoMarca(tester, fila + 1, columna + 1), texto);
        }
      }
    });

    testWidgets('Mantener presionado resalta la zona y explica qué es', (
      tester,
    ) async {
      await abrir(tester);
      final marcas = MarcasZonas(mapaUno);
      final amarilla = marcas.marcas.singleWhere((m) => m.texto == 'A1');

      // La esquina de arriba a la izquierda es uno de los pedazos amarillos.
      final dedo = await mantener(tester, 1, 1);

      expect(
        find.descendant(
          of: find.byKey(const Key('aviso-zona-resaltada')),
          matching: find.text(marcas.descripcionDe(amarilla.zona)),
        ),
        findsOneWidget,
      );
      // Todos los pedazos amarillos siguen encendidos; lo demás se apaga.
      for (final (fila, columna) in marcas.celdasDe(amarilla.zona)) {
        expect(apagada(tester, fila + 1, columna + 1), isFalse);
      }
      expect(apagada(tester, 1, 2), isTrue);

      await dedo.up();
      await tester.pump();
    });

    testWidgets('Al soltar, el tablero vuelve a verse normal', (tester) async {
      await abrir(tester);
      final dedo = await mantener(tester, 1, 1);
      expect(find.byKey(const Key('aviso-zona-resaltada')), findsOneWidget);

      await dedo.up();
      await tester.pump();

      expect(find.byKey(const Key('aviso-zona-resaltada')), findsNothing);
      expect(apagada(tester, 1, 2), isFalse);
    });

    testWidgets('Una zona de otro color dice que puntúa aparte', (
      tester,
    ) async {
      await abrir(tester);
      final marcas = MarcasZonas(mapaUno);
      final v2 = marcas.marcas.singleWhere((m) => m.texto == 'V2');
      final (fila, columna) = v2.celdasMarca.single;

      final dedo = await mantener(tester, fila + 1, columna + 1);

      expect(
        find.text(
          'La zona verde 2: hay 2 zonas de este color y cada una puntúa '
          'aparte.',
        ),
        findsOneWidget,
      );
      await dedo.up();
      await tester.pump();
    });

    testWidgets('Mantener presionado no coloca el número', (tester) async {
      await abrirTableroCasiLleno(tester, [(1, 3)]);
      await lanzarDados(tester);
      await tester.tap(find.byKey(const Key('anchor-option-1')));
      await tester.pumpAndSettle();

      final dedo = await tester.startGesture(
        tester.getCenter(find.byKey(const Key('candidate-cell-4-7'))),
      );
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
      await dedo.up();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('movement-summary')), findsNothing);
      expect(find.byKey(const Key('candidate-cell-4-7')), findsOneWidget);
    });

    testWidgets('Un toque normal sigue eligiendo la celda', (tester) async {
      await abrirTableroCasiLleno(tester, [(1, 3)]);
      await lanzarDados(tester);
      await tester.tap(find.byKey(const Key('anchor-option-1')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('candidate-cell-4-7')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('movement-summary')), findsOneWidget);
    });
  });

  group('Widgets: explicación de las zonas en las reglas', () {
    Future<void> mostrar(WidgetTester tester, Mapa mapa) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PanelReglas(
                reglas: LeyendaReglas(mapa).reglas,
                explicaciones: MarcasZonas(mapa).explicaciones,
              ),
            ),
          ),
        ),
      );
    }

    Future<void> tocarZonas(WidgetTester tester) async {
      await tester.ensureVisible(find.byKey(const Key('zonas-toggle')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('zonas-toggle')));
      await tester.pumpAndSettle();
    }

    IconData flecha(WidgetTester tester) =>
        tester.widget<Icon>(find.byKey(const Key('zonas-chevron'))).icon!;

    testWidgets('Empieza cerrada, pero con las marcas a la vista', (
      tester,
    ) async {
      await mostrar(tester, mapaCuatro);

      expect(find.text('Zonas del mapa'), findsOneWidget);
      expect(flecha(tester), Icons.expand_more);
      expect(find.byKey(const Key('zonas-rojo')), findsNothing);
      expect(find.text(PanelReglas.ayudaResaltar), findsNothing);
      for (final texto in ['A1', 'R1', 'R2', 'V1', 'Az1', 'N↑', 'N↓']) {
        expect(
          find.descendant(
            of: find.byKey(const Key('zonas-toggle')),
            matching: find.text(texto),
          ),
          findsOneWidget,
          reason: texto,
        );
      }
    });

    testWidgets('Un toque la abre y otro la cierra', (tester) async {
      await mostrar(tester, mapaUno);

      await tocarZonas(tester);
      expect(flecha(tester), Icons.expand_less);
      expect(find.byKey(const Key('zonas-amarillo')), findsOneWidget);

      await tocarZonas(tester);
      expect(flecha(tester), Icons.expand_more);
      expect(find.byKey(const Key('zonas-amarillo')), findsNothing);
    });

    testWidgets('Abierta explica cada color con sus marcas al lado', (
      tester,
    ) async {
      await mostrar(tester, mapaCuatro);
      await tocarZonas(tester);

      final rojo = find.byKey(const Key('zonas-rojo'));
      expect(rojo, findsOneWidget);
      for (final texto in ['R1', 'R2']) {
        expect(
          find.descendant(of: rojo, matching: find.text(texto)),
          findsOneWidget,
        );
      }
      expect(
        find.descendant(
          of: rojo,
          matching: find.text(
            'R1 (2 pedazos) y R2 (2 pedazos): 2 zonas distintas; cada una se '
            'llena y puntúa aparte.',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.text('A1: una sola zona en 6 pedazos; cuentan juntos.'),
        findsOneWidget,
      );
    });

    testWidgets('Abierta dice cómo ver una zona entera', (tester) async {
      await mostrar(tester, mapaUno);
      await tocarZonas(tester);

      expect(find.text(PanelReglas.ayudaResaltar), findsOneWidget);
    });

    testWidgets('Sin explicaciones no hay apartado de zonas', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PanelReglas(reglas: LeyendaReglas(mapaUno).reglas),
          ),
        ),
      );

      expect(find.byKey(const Key('zonas-toggle')), findsNothing);
      expect(find.text('Zonas del mapa'), findsNothing);
    });

    testWidgets('En el tablero aparecen las explicaciones del mapa', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TableroPage(
            mapa: mapaUno,
            sonidoDados: SonidoFalso(),
            sonidoVictoria: SonidoFalso(),
          ),
        ),
      );
      await tocarZonas(tester);

      for (final explicacion in MarcasZonas(mapaUno).explicaciones) {
        expect(
          find.byKey(Key('zonas-${explicacion.tipo.name}')),
          findsOneWidget,
        );
      }
    });
  });
}
