import 'package:brilliantdart/mapa_tres.dart';
import 'package:brilliantdart/tipoo.dart';
import 'package:brilliant_mobile/colores_zonas.dart';
import 'package:brilliant_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

/// Color con el que se pinta una celda del tablero en pantalla.
Color colorDeCelda(WidgetTester tester, String clave) => tester
    .widget<Material>(
      find
          .ancestor(of: find.byKey(Key(clave)), matching: find.byType(Material))
          .first,
    )
    .color!;

/// Color de una celda de la vista previa del Mapa 3 en la selección.
Color? colorPrevia(WidgetTester tester, int indice) =>
    (tester
                .widget<DecoratedBox>(
                  find.descendant(
                    of: find.byKey(const Key('map-choice-3')),
                    matching: find.byKey(Key('map-preview-cell-$indice')),
                  ),
                )
                .decoration
            as BoxDecoration)
        .color;

/// Abre el tablero del Mapa 3 sin sonidos reales.
Future<void> abrirMapaTres(WidgetTester tester) => tester.pumpWidget(
  MaterialApp(
    home: TableroPage(
      mapa: mapaTres,
      sonidoVictoria: SonidoFalso(),
      sonidoDados: SonidoFalso(),
    ),
  ),
);

void main() {
  group('Widgets: Mapa 3 en la selección', () {
    testWidgets('El Mapa 3 aparece como disponible', (tester) async {
      await tester.pumpWidget(const BrilliantApp());

      expect(
        find.descendant(
          of: find.byKey(const Key('map-choice-3')),
          matching: find.text('Disponible'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Su vista previa tiene los 49 colores del Mapa 3', (
      tester,
    ) async {
      await tester.pumpWidget(const BrilliantApp());

      for (var indice = 0; indice < 49; indice++) {
        expect(
          colorPrevia(tester, indice),
          coloresZonas[mapaTres.tipoEn(indice ~/ 7, indice % 7)],
        );
      }
    });

    testWidgets('La vista previa empieza en amarillo y tiene gris abajo', (
      tester,
    ) async {
      await tester.pumpWidget(const BrilliantApp());

      expect(colorPrevia(tester, 0), coloresZonas[TipoZona.amarillo]);
      expect(colorPrevia(tester, 45), coloresZonas[TipoZona.gris]);
    });

    testWidgets('Tocar el Mapa 3 abre su tablero vacío', (tester) async {
      await tester.pumpWidget(const BrilliantApp());

      await tester.tap(find.byKey(const Key('map-choice-3')));
      await tester.pumpAndSettle();

      expect(
        tester.widget<TableroPage>(find.byType(TableroPage)).mapa,
        same(mapaTres),
      );
      expect(find.text('0/6'), findsOneWidget);
    });
  });

  group('Widgets: tablero del Mapa 3', () {
    testWidgets('Cada celda se pinta con el color del Mapa 3', (tester) async {
      await abrirMapaTres(tester);

      for (var fila = 1; fila <= 7; fila++) {
        for (var columna = 1; columna <= 7; columna++) {
          final inicial = mapaTres.celdasIniciales.contains((fila, columna));
          final clave = inicial
              ? 'initial-cell-$fila-$columna'
              : 'board-cell-$fila-$columna';
          expect(
            colorDeCelda(tester, clave),
            coloresZonas[mapaTres.tipoEn(fila - 1, columna - 1)],
            reason: 'Celda ($fila, $columna)',
          );
        }
      }
    });

    testWidgets('El gris (7, 4) separa los dos morados de abajo', (
      tester,
    ) async {
      await abrirMapaTres(tester);

      expect(
        colorDeCelda(tester, 'initial-cell-7-3'),
        coloresZonas[TipoZona.morado],
      );
      expect(
        colorDeCelda(tester, 'board-cell-7-4'),
        coloresZonas[TipoZona.gris],
      );
      expect(
        colorDeCelda(tester, 'board-cell-7-5'),
        coloresZonas[TipoZona.morado],
      );
    });

    testWidgets('Sus seis celdas iniciales muestran un +', (tester) async {
      await abrirMapaTres(tester);

      for (final (fila, columna) in mapaTres.celdasIniciales) {
        expect(textoEn('initial-cell-$fila-$columna', '+'), findsOneWidget);
      }
      expect(find.text('+'), findsNWidgets(6));
      expect(find.byKey(const Key('initial-cell-7-3')), findsOneWidget);
      expect(find.byKey(const Key('initial-cell-6-3')), findsNothing);
    });

    testWidgets('Colocar los 6 números iniciales activa Comenzar', (
      tester,
    ) async {
      await abrirMapaTres(tester);

      for (var i = 0; i < 6; i++) {
        final (fila, columna) = mapaTres.celdasIniciales[i];
        await tester.tap(find.byKey(Key('initial-cell-$fila-$columna')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(Key('initial-value-${i + 1}')));
        await tester.pumpAndSettle();
      }

      expect(find.text('6/6'), findsOneWidget);
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNotNull,
      );
    });

    testWidgets('La puntuación cuenta las zonas del Mapa 3', (tester) async {
      await abrirMapaTres(tester);

      const zonas = {
        'amarillo': '0/1',
        'morado': '0/2',
        'gris': '0/1',
        'rojo': '0/2',
        'verde': '0/1',
        'azul': '0/1',
      };
      for (final MapEntry(key: color, value: texto) in zonas.entries) {
        expect(textoEn('score-row-$color', texto), findsOneWidget);
      }
    });
  });

  group('Widgets: partida en el Mapa 3', () {
    Future<void> abrirCasiLleno(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TableroPage(
            mapa: mapaTres,
            dados: DadosFijos([(1, 3)]),
            tablero: tableroCasiLleno(mapa: mapaTres, vacia: (6, 6)),
            sonidoVictoria: SonidoFalso(),
            sonidoDados: SonidoFalso(),
          ),
        ),
      );
      await tester.tap(find.text('Comenzar'));
      await tester.pump();
    }

    testWidgets('A falta de una celda verde lleva 48 puntos', (tester) async {
      await abrirCasiLleno(tester);

      expect(find.text('48 pts'), findsOneWidget);
      expect(textoEn('score-row-morado', '2/2'), findsOneWidget);
      expect(textoEn('score-row-verde', '0/1'), findsOneWidget);
    });

    testWidgets('Llenar la última celda termina con 54 puntos perfectos', (
      tester,
    ) async {
      await abrirCasiLleno(tester);

      await jugarUltimaCelda(tester, celda: '6-6');
      await tester.tap(find.text('Aceptar'));
      await tester.pumpAndSettle();

      expect(find.text('54 pts'), findsOneWidget);
      expect(find.text('Has puntuado 54 puntos'), findsOneWidget);
      expect(find.byKey(const Key('perfect-score')), findsOneWidget);
      expect(find.byKey(const Key('roll-dice-button')), findsNothing);
    });
  });
}
