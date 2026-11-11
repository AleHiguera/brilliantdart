// Prueba de widgets: el cuadro de reglas junto al tablero, con un cuadro del
// color de cada zona y el signo de su regla.

import 'package:brilliantdart/catalogo_mapas.dart';
import 'package:brilliantdart/leyenda_reglas.dart';
import 'package:brilliantdart/mapa.dart';
import 'package:brilliantdart/mapa_cuatro.dart';
import 'package:brilliantdart/mapa_uno.dart';
import 'package:brilliantdart/tipoo.dart';
import 'package:brilliant_mobile/colores_zonas.dart';
import 'package:brilliant_mobile/main.dart';
import 'package:brilliant_mobile/panel_reglas.dart';
import 'package:brilliant_mobile/tabla_puntuacion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

Future<void> abrir(WidgetTester tester, Mapa mapa) async {
  await tester.pumpWidget(
    MaterialApp(
      home: TableroPage(
        mapa: mapa,
        sonidoVictoria: SonidoFalso(),
        sonidoDados: SonidoFalso(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder cuadro(TipoZona tipo, String simbolo) =>
    find.byKey(Key('regla-${tipo.name}-$simbolo'));

Color colorDe(WidgetTester tester, Finder finder) =>
    (tester
                .widget<Container>(
                  find
                      .descendant(of: finder, matching: find.byType(Container))
                      .first,
                )
                .decoration!
            as BoxDecoration)
        .color!;

void main() {
  group('Widgets: cuadro de reglas', () {
    testWidgets('Se ve mientras se ponen los números iniciales', (
      tester,
    ) async {
      await abrir(tester, mapaUno);

      expect(find.text('Comenzar'), findsOneWidget);
      expect(find.byKey(const Key('reglas')), findsOneWidget);
      expect(find.text('Reglas'), findsOneWidget);
    });

    for (final mapa in mapasDisponibles) {
      testWidgets('Mapa ${mapa.numero}: un cuadro por cada regla del mapa', (
        tester,
      ) async {
        await abrir(tester, mapa);

        final reglas = LeyendaReglas(mapa).reglas;
        expect(find.byType(CuadroRegla), findsNWidgets(reglas.length));
        for (final regla in reglas) {
          final finder = cuadro(regla.tipo, regla.simbolo);
          expect(finder, findsOneWidget, reason: regla.tipo.name);
          expect(
            find.descendant(of: finder, matching: find.text(regla.simbolo)),
            findsOneWidget,
          );
          expect(colorDe(tester, finder), coloresZonas[regla.tipo]);
        }
      });
    }

    testWidgets('Los signos de cada color', (tester) async {
      await abrir(tester, mapaCuatro);

      expect(cuadro(TipoZona.amarillo, '≠'), findsOneWidget);
      expect(cuadro(TipoZona.morado, 'XO'), findsOneWidget);
      expect(cuadro(TipoZona.verde, '?'), findsOneWidget);
      expect(cuadro(TipoZona.azul, '='), findsOneWidget);
    });

    testWidgets('El gris lleva un igual', (tester) async {
      final conGris = mapasDisponibles.firstWhere(
        (mapa) => mapa.tiposPresentes.contains(TipoZona.gris),
      );
      await abrir(tester, conGris);

      expect(cuadro(TipoZona.gris, '='), findsOneWidget);
      expect(
        colorDe(tester, cuadro(TipoZona.gris, '=')),
        coloresZonas[TipoZona.gris],
      );
    });

    testWidgets('Mapa 4: naranja de arriba 4-6 y de abajo 1-3, en ese orden', (
      tester,
    ) async {
      await abrir(tester, mapaCuatro);

      final arriba = cuadro(TipoZona.naranja, '4-6');
      final abajo = cuadro(TipoZona.naranja, '1-3');
      expect(arriba, findsOneWidget);
      expect(abajo, findsOneWidget);
      expect(colorDe(tester, arriba), coloresZonas[TipoZona.naranja]);
      // En orden de lectura: antes en la misma fila, o en una fila de arriba.
      final (deArriba, deAbajo) = (
        tester.getTopLeft(arriba),
        tester.getTopLeft(abajo),
      );
      expect(
        deArriba.dy < deAbajo.dy ||
            (deArriba.dy == deAbajo.dy && deArriba.dx < deAbajo.dx),
        isTrue,
        reason: '4-6 en $deArriba, 1-3 en $deAbajo',
      );
    });

    testWidgets('Al dejar el dedo encima se lee la regla', (tester) async {
      await abrir(tester, mapaCuatro);

      for (final regla in LeyendaReglas(mapaCuatro).reglas) {
        expect(find.byTooltip(PanelReglas.explicacion(regla)), findsWidgets);
      }
    });

    testWidgets('Sigue al jugar, sin quitar lo que ya había', (tester) async {
      await abrirTableroCasiLleno(tester, const [(1, 3)]);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('reglas')), findsOneWidget);
      expect(find.byKey(const Key('turn-panel')), findsOneWidget);
      expect(find.byKey(const Key('roll-dice-button')), findsOneWidget);
      expect(find.byType(TablaPuntuacion), findsOneWidget);
    });

    testWidgets('En pantalla ancha va en la columna de al lado del tablero', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await abrir(tester, mapaUno);

      final (fila, columna) = mapaUno.celdasIniciales.first;
      expect(
        tester.getTopLeft(find.byKey(const Key('reglas'))).dx,
        greaterThan(
          tester.getTopRight(find.byKey(Key('initial-cell-$fila-$columna'))).dx,
        ),
      );
    });

    testWidgets('En el celular va debajo del tablero y cabe', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await abrir(tester, mapaCuatro);

      expect(tester.takeException(), isNull);
      final (fila, columna) = mapaCuatro.celdasIniciales.last;
      await tester.ensureVisible(find.byKey(const Key('reglas')));
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.byKey(const Key('reglas'))).dy,
        greaterThan(
          tester
              .getBottomLeft(find.byKey(Key('initial-cell-$fila-$columna')))
              .dy,
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('Un signo largo cabe en su cuadro', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PanelReglas(
              reglas: [
                (
                  tipo: TipoZona.morado,
                  simbolo: 'XO',
                  regla: 'Dos números',
                  flecha: null,
                ),
                (
                  tipo: TipoZona.naranja,
                  simbolo: '4-6',
                  regla: 'Del 4 al 6',
                  flecha: '↑',
                ),
              ],
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(cuadro(TipoZona.naranja, '4-6')),
        const Size(CuadroRegla.ladoMaximo, CuadroRegla.ladoMaximo),
      );
    });

    testWidgets('El signo se lee: claro sobre colores oscuros', (tester) async {
      await abrir(tester, mapaUno);

      Color colorDelSigno(TipoZona tipo, String simbolo) => tester
          .widget<Text>(
            find.descendant(
              of: cuadro(tipo, simbolo),
              matching: find.text(simbolo),
            ),
          )
          .style!
          .color!;

      expect(colorDelSigno(TipoZona.morado, 'XO'), Colors.white);
      expect(colorDelSigno(TipoZona.amarillo, '≠'), Colors.black87);
    });
  });

  group('Widgets: reglas en una sola fila', () {
    for (final (nombre, tamano) in [
      ('celular chico (320)', const Size(320, 640)),
      ('Samsung Galaxy A55 (360)', const Size(360, 800)),
      ('celular grande (412)', const Size(412, 915)),
      ('pantalla ancha', const Size(1200, 900)),
    ]) {
      for (final mapa in mapasDisponibles) {
        testWidgets('$nombre, Mapa ${mapa.numero}: todos en la misma fila', (
          tester,
        ) async {
          tester.view.physicalSize = tamano;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);

          await abrir(tester, mapa);

          final filas = {
            for (final elemento in find.byType(CuadroRegla).evaluate())
              tester.getTopLeft(find.byWidget(elemento.widget)).dy,
          };
          expect(filas, hasLength(1));
          final lado = tester.getSize(find.byType(CuadroRegla).first).width;
          expect(lado, greaterThanOrEqualTo(CuadroRegla.ladoMinimo));
          expect(lado, lessThanOrEqualTo(CuadroRegla.ladoMaximo));
          expect(tester.takeException(), isNull);
        });
      }
    }

    test('El lado se ajusta al ancho, entre el mínimo y el máximo', () {
      // 7 cuadros de 34 con 6 de separación ocupan 274.
      expect(CuadroRegla.ladoPara(400, 7), CuadroRegla.ladoMaximo);
      expect(CuadroRegla.ladoPara(274, 7), 34);
      expect(CuadroRegla.ladoPara(268, 7), 33);
      expect(CuadroRegla.ladoPara(100, 7), CuadroRegla.ladoMinimo);
      expect(CuadroRegla.ladoPara(300, 0), CuadroRegla.ladoMaximo);
      expect(CuadroRegla.ladoPara(double.infinity, 7), CuadroRegla.ladoMaximo);
    });
  });

  group('Widgets: flechas de los naranjas', () {
    testWidgets('El de arriba lleva ↑ y el de abajo ↓', (tester) async {
      await abrir(tester, mapaCuatro);

      expect(
        find.descendant(
          of: cuadro(TipoZona.naranja, '4-6'),
          matching: find.text('↑'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: cuadro(TipoZona.naranja, '1-3'),
          matching: find.text('↓'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Los demás colores no llevan flecha', (tester) async {
      await abrir(tester, mapaCuatro);

      expect(find.text('↑'), findsOneWidget);
      expect(find.text('↓'), findsOneWidget);
      for (final regla in LeyendaReglas(mapaCuatro).reglas) {
        if (regla.tipo == TipoZona.naranja) continue;
        expect(
          find.byKey(Key('flecha-${regla.tipo.name}-${regla.simbolo}')),
          findsNothing,
        );
      }
    });

    testWidgets(
      'Al dejar el dedo encima dice si es la de arriba o la de abajo',
      (tester) async {
        await abrir(tester, mapaCuatro);

        expect(
          find.byTooltip(RegExp(r'^Zona de arriba: .*4 al 6')),
          findsOneWidget,
        );
        expect(
          find.byTooltip(RegExp(r'^Zona de abajo: .*1 al 3')),
          findsOneWidget,
        );
      },
    );

    testWidgets('La flecha y el rango caben en el cuadro chico', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await abrir(tester, mapaCuatro);

      final cuadroNaranja = tester.getRect(cuadro(TipoZona.naranja, '4-6'));
      for (final texto in ['↑', '4-6']) {
        final rect = tester.getRect(
          find.descendant(
            of: cuadro(TipoZona.naranja, '4-6'),
            matching: find.text(texto),
          ),
        );
        expect(cuadroNaranja.contains(rect.topLeft), isTrue, reason: texto);
        expect(
          cuadroNaranja.inflate(0.5).contains(rect.bottomRight),
          isTrue,
          reason: texto,
        );
      }
      expect(tester.takeException(), isNull);
    });
  });

  group('Widgets: título del historial', () {
    testWidgets('En el celular dice Historial completo, sin cortarse', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await abrirTableroCasiLleno(tester, const [(1, 3)]);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Historial'));
      await tester.pumpAndSettle();

      // Si se corta o no depende de la letra real: la de las pruebas es
      // mucho más ancha. Aquí se revisa el título corto y que nada se desborde.
      expect(find.text('Historial'), findsOneWidget);
      expect(find.text('Historial de dados'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
