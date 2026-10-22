import 'package:brilliantdart/mapa_dos.dart';
import 'package:brilliantdart/mapa_uno.dart';
import 'package:brilliantdart/tipoo.dart';
import 'package:brilliant_mobile/colores_zonas.dart';
import 'package:brilliant_mobile/main.dart';
import 'package:brilliant_mobile/paneles_juego.dart';
import 'package:brilliant_mobile/tabla_puntuacion.dart';
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

/// Abre el tablero del Mapa 2 sin sonidos reales.
Future<void> abrirMapaDos(WidgetTester tester) => tester.pumpWidget(
  MaterialApp(
    home: TableroPage(
      mapa: mapaDos,
      sonidoVictoria: SonidoFalso(),
      sonidoDados: SonidoFalso(),
    ),
  ),
);

void main() {
  group('Widgets: Mapa 2 en la selección', () {
    testWidgets('El Mapa 2 aparece como disponible', (tester) async {
      await tester.pumpWidget(const BrilliantApp());

      expect(
        find.descendant(
          of: find.byKey(const Key('map-choice-2')),
          matching: find.text('Disponible'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('map-choice-2')),
          matching: find.text('Muy pronto podrás jugarlo.'),
        ),
        findsNothing,
      );
    });

    testWidgets('Su vista previa tiene las 49 celdas del Mapa 2', (
      tester,
    ) async {
      await tester.pumpWidget(const BrilliantApp());

      for (var indice = 0; indice < 49; indice++) {
        final celda = find.descendant(
          of: find.byKey(const Key('map-choice-2')),
          matching: find.byKey(Key('map-preview-cell-$indice')),
        );
        expect(celda, findsOneWidget);
        final decoracion =
            tester.widget<DecoratedBox>(celda).decoration as BoxDecoration;
        expect(
          decoracion.color,
          coloresZonas[mapaDos.tipoEn(indice ~/ 7, indice % 7)],
        );
      }
    });

    testWidgets('La vista previa del Mapa 2 muestra los grises', (
      tester,
    ) async {
      await tester.pumpWidget(const BrilliantApp());

      for (final indice in [3, 45]) {
        final celda = find.descendant(
          of: find.byKey(const Key('map-choice-2')),
          matching: find.byKey(Key('map-preview-cell-$indice')),
        );
        final decoracion =
            tester.widget<DecoratedBox>(celda).decoration as BoxDecoration;
        expect(decoracion.color, coloresZonas[TipoZona.gris]);
      }
    });

    testWidgets('Las vistas previas del Mapa 1 y del Mapa 2 son distintas', (
      tester,
    ) async {
      await tester.pumpWidget(const BrilliantApp());

      Color? colorPrevia(int mapa, int indice) =>
          (tester
                      .widget<DecoratedBox>(
                        find.descendant(
                          of: find.byKey(Key('map-choice-$mapa')),
                          matching: find.byKey(Key('map-preview-cell-$indice')),
                        ),
                      )
                      .decoration
                  as BoxDecoration)
              .color;

      expect(colorPrevia(1, 0), coloresZonas[TipoZona.amarillo]);
      expect(colorPrevia(2, 0), coloresZonas[TipoZona.morado]);
    });

    testWidgets('Tocar el Mapa 2 abre su tablero', (tester) async {
      await tester.pumpWidget(const BrilliantApp());

      await tester.tap(find.byKey(const Key('map-choice-2')));
      await tester.pumpAndSettle();

      final pagina = tester.widget<TableroPage>(find.byType(TableroPage));
      expect(pagina.mapa, same(mapaDos));
      expect(find.text('0/6'), findsOneWidget);
    });

    testWidgets('Tocar el Mapa 1 sigue abriendo el Mapa 1', (tester) async {
      await tester.pumpWidget(const BrilliantApp());

      await tester.tap(find.byKey(const Key('map-choice-1')));
      await tester.pumpAndSettle();

      final pagina = tester.widget<TableroPage>(find.byType(TableroPage));
      expect(pagina.mapa, same(mapaUno));
    });
  });

  group('Widgets: tablero del Mapa 2', () {
    test('Si no se indica mapa, se juega el Mapa 1', () {
      expect(const TableroPage().mapa, same(mapaUno));
    });

    testWidgets('Cada celda se pinta con el color del Mapa 2', (tester) async {
      await abrirMapaDos(tester);

      for (var fila = 1; fila <= 7; fila++) {
        for (var columna = 1; columna <= 7; columna++) {
          final inicial = mapaDos.celdasIniciales.contains((fila, columna));
          final clave = inicial
              ? 'initial-cell-$fila-$columna'
              : 'board-cell-$fila-$columna';
          expect(
            colorDeCelda(tester, clave),
            coloresZonas[mapaDos.tipoEn(fila - 1, columna - 1)],
            reason: 'Celda ($fila, $columna)',
          );
        }
      }
    });

    testWidgets('Las celdas (1, 4) y (7, 4) se ven grises', (tester) async {
      await abrirMapaDos(tester);

      expect(
        colorDeCelda(tester, 'board-cell-1-4'),
        coloresZonas[TipoZona.gris],
      );
      expect(
        colorDeCelda(tester, 'board-cell-7-4'),
        coloresZonas[TipoZona.gris],
      );
    });

    testWidgets('Sus seis celdas iniciales muestran un +', (tester) async {
      await abrirMapaDos(tester);

      for (final (fila, columna) in mapaDos.celdasIniciales) {
        expect(textoEn('initial-cell-$fila-$columna', '+'), findsOneWidget);
      }
      expect(find.text('+'), findsNWidgets(6));
    });

    testWidgets('Las celdas iniciales del Mapa 1 aquí son celdas normales', (
      tester,
    ) async {
      await abrirMapaDos(tester);

      expect(find.byKey(const Key('initial-cell-1-3')), findsNothing);
      expect(find.byKey(const Key('initial-cell-6-5')), findsNothing);
      expect(find.byKey(const Key('initial-cell-7-5')), findsOneWidget);
      expect(find.byKey(const Key('board-cell-1-3')), findsOneWidget);

      await tester.tap(find.byKey(const Key('board-cell-1-3')));
      await tester.pumpAndSettle();
      expect(find.byType(SimpleDialog), findsNothing);
    });

    testWidgets('Colocar los 6 números iniciales activa Comenzar', (
      tester,
    ) async {
      await abrirMapaDos(tester);

      for (var i = 0; i < 6; i++) {
        final (fila, columna) = mapaDos.celdasIniciales[i];
        await tester.tap(find.byKey(Key('initial-cell-$fila-$columna')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(Key('initial-value-${i + 1}')));
        await tester.pumpAndSettle();
        expect(
          textoEn('initial-cell-$fila-$columna', '${i + 1}'),
          findsOneWidget,
        );
      }

      expect(find.text('6/6'), findsOneWidget);
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNotNull,
      );
    });

    testWidgets('La puntuación muestra la fila Gris y todos sus colores', (
      tester,
    ) async {
      await abrirMapaDos(tester);

      expect(textoEn('score-row-gris', 'Gris'), findsOneWidget);
      expect(textoEn('score-row-gris', '0/1'), findsOneWidget);
      expect(textoEn('score-row-amarillo', '0/1'), findsOneWidget);
      for (final color in ['morado', 'verde', 'azul', 'rojo']) {
        expect(textoEn('score-row-$color', '0/2'), findsOneWidget);
      }
    });

    testWidgets('La tabla de un Mapa 2 completo suma 55 puntos', (
      tester,
    ) async {
      final tablero = tableroCasiLleno(mapa: mapaDos, vacia: (3, 7))
        ..colocarDato(2, 6, 3);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TablaPuntuacion(tablero: tablero)),
        ),
      );

      const esperado = {
        'morado': ('2/2', '12'),
        'gris': ('1/1', '3'),
        'verde': ('2/2', '8'),
        'amarillo': ('1/1', '6'),
        'rojo': ('2/2', '12'),
        'azul': ('2/2', '14'),
      };
      for (final MapEntry(key: color, value: (hechas, puntos))
          in esperado.entries) {
        expect(textoEn('score-row-$color', hechas), findsOneWidget);
        expect(textoEn('score-row-$color', puntos), findsOneWidget);
      }
      expect(find.text('55 pts'), findsOneWidget);
    });
  });

  group('Widgets: partida en el Mapa 2', () {
    Future<void> abrirCasiLleno(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TableroPage(
            mapa: mapaDos,
            dados: DadosFijos([(1, 3)]),
            tablero: tableroCasiLleno(mapa: mapaDos, vacia: (3, 7)),
            sonidoVictoria: SonidoFalso(),
            sonidoDados: SonidoFalso(),
          ),
        ),
      );
      await tester.tap(find.text('Comenzar'));
      await tester.pump();
    }

    testWidgets('A falta de una celda verde lleva 51 puntos', (tester) async {
      await abrirCasiLleno(tester);

      expect(find.text('51 pts'), findsOneWidget);
      expect(textoEn('score-row-verde', '1/2'), findsOneWidget);
    });

    testWidgets('Llenar la última celda termina con 55 puntos perfectos', (
      tester,
    ) async {
      await abrirCasiLleno(tester);

      await jugarUltimaCelda(tester, celda: '3-7');
      await tester.tap(find.text('Aceptar'));
      await tester.pumpAndSettle();

      expect(find.text('55 pts'), findsOneWidget);
      expect(find.text('Has puntuado 55 puntos'), findsOneWidget);
      expect(find.byKey(const Key('perfect-score')), findsOneWidget);
      expect(find.byKey(const Key('roll-dice-button')), findsNothing);
    });
  });

  group('Widgets: puntuación perfecta según el mapa', () {
    Future<void> mostrarFin(WidgetTester tester, int puntos, int maximo) =>
        tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: PanelFinPartida(
                  puntos: puntos,
                  maximo: maximo,
                  onNuevaPartida: () {},
                ),
              ),
            ),
          ),
        );

    testWidgets('55 de 55 es perfecto', (tester) async {
      await mostrarFin(tester, 55, 55);

      expect(find.byKey(const Key('perfect-score')), findsOneWidget);
    });

    testWidgets('54 de 55 ya no es perfecto en el Mapa 2', (tester) async {
      await mostrarFin(tester, 54, 55);

      expect(find.text('Has puntuado 54 puntos'), findsOneWidget);
      expect(find.byKey(const Key('perfect-score')), findsNothing);
    });

    testWidgets('54 de 54 sigue siendo perfecto en el Mapa 1', (tester) async {
      await mostrarFin(tester, 54, 54);

      expect(find.byKey(const Key('perfect-score')), findsOneWidget);
    });
  });
}
