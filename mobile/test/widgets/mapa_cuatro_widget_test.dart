import 'package:brilliantdart/mapa_cuatro.dart';
import 'package:brilliantdart/tablero.dart';
import 'package:brilliantdart/tipoo.dart';
import 'package:brilliant_mobile/colores_zonas.dart';
import 'package:brilliant_mobile/main.dart';
import 'package:brilliant_mobile/paneles_juego.dart';
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

/// Baja en la selección hasta que se ve la tarjeta del Mapa 4.
Future<void> verTarjetaMapaCuatro(WidgetTester tester) async {
  await tester.pumpWidget(const BrilliantApp());
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    find.byKey(const Key('map-choice-4')),
    200,
    scrollable: find
        .descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.pumpAndSettle();
}

/// Abre el tablero del Mapa 4 sin sonidos reales.
Future<void> abrirMapaCuatro(WidgetTester tester, {Tablero? tablero}) =>
    tester.pumpWidget(
      MaterialApp(
        home: TableroPage(
          mapa: mapaCuatro,
          tablero: tablero,
          sonidoVictoria: SonidoFalso(),
          sonidoDados: SonidoFalso(),
        ),
      ),
    );

/// Si el botón de un número del selector se puede tocar.
bool sePuedeElegir(WidgetTester tester, int numero) =>
    tester.widget<InkWell>(find.byKey(Key('initial-value-$numero'))).onTap !=
    null;

void main() {
  group('Widgets: Mapa 4 en la selección', () {
    testWidgets('El Mapa 4 aparece como disponible', (tester) async {
      await verTarjetaMapaCuatro(tester);

      expect(
        find.descendant(
          of: find.byKey(const Key('map-choice-4')),
          matching: find.text('Disponible'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Su vista previa tiene los colores del Mapa 4', (tester) async {
      await verTarjetaMapaCuatro(tester);

      for (var indice = 0; indice < 49; indice++) {
        final decoracion =
            tester
                    .widget<DecoratedBox>(
                      find.descendant(
                        of: find.byKey(const Key('map-choice-4')),
                        matching: find.byKey(Key('map-preview-cell-$indice')),
                      ),
                    )
                    .decoration
                as BoxDecoration;
        expect(
          decoracion.color,
          coloresZonas[mapaCuatro.tipoEn(indice ~/ 7, indice % 7)],
        );
      }
    });

    testWidgets('Tocar el Mapa 4 abre su tablero', (tester) async {
      await verTarjetaMapaCuatro(tester);

      await tester.tap(find.byKey(const Key('map-choice-4')));
      await tester.pumpAndSettle();

      expect(
        tester.widget<TableroPage>(find.byType(TableroPage)).mapa,
        same(mapaCuatro),
      );
    });
  });

  group('Widgets: tablero del Mapa 4', () {
    testWidgets('Cada celda se pinta con el color del Mapa 4', (tester) async {
      await abrirMapaCuatro(tester);

      for (var fila = 1; fila <= 7; fila++) {
        for (var columna = 1; columna <= 7; columna++) {
          final inicial = mapaCuatro.celdasIniciales.contains((fila, columna));
          expect(
            colorDeCelda(
              tester,
              inicial
                  ? 'initial-cell-$fila-$columna'
                  : 'board-cell-$fila-$columna',
            ),
            coloresZonas[mapaCuatro.tipoEn(fila - 1, columna - 1)],
            reason: 'Celda ($fila, $columna)',
          );
        }
      }
    });

    testWidgets('Las filas 1 y 7 se ven naranjas', (tester) async {
      await abrirMapaCuatro(tester);

      expect(
        colorDeCelda(tester, 'board-cell-1-1'),
        coloresZonas[TipoZona.naranja],
      );
      expect(
        colorDeCelda(tester, 'board-cell-7-7'),
        coloresZonas[TipoZona.naranja],
      );
    });

    testWidgets('Sus seis celdas iniciales muestran un +', (tester) async {
      await abrirMapaCuatro(tester);

      for (final (fila, columna) in mapaCuatro.celdasIniciales) {
        expect(textoEn('initial-cell-$fila-$columna', '+'), findsOneWidget);
      }
    });

    testWidgets('La puntuación muestra dos zonas naranjas y no tiene gris', (
      tester,
    ) async {
      await abrirMapaCuatro(tester);

      expect(textoEn('score-row-naranja', 'Naranja'), findsOneWidget);
      expect(textoEn('score-row-naranja', '0/2'), findsOneWidget);
      expect(find.byKey(const Key('score-row-gris')), findsNothing);
    });
  });

  group('Widgets: números iniciales en el naranja', () {
    testWidgets('En la (1, 5) solo se pueden elegir 4, 5 y 6', (tester) async {
      await abrirMapaCuatro(tester);

      await tester.tap(find.byKey(const Key('initial-cell-1-5')));
      await tester.pumpAndSettle();

      for (final numero in [4, 5, 6]) {
        expect(sePuedeElegir(tester, numero), isTrue);
      }
      for (final numero in [1, 2, 3]) {
        expect(sePuedeElegir(tester, numero), isFalse);
        expect(textoEn('initial-value-$numero', 'No va aquí'), findsOneWidget);
      }
    });

    testWidgets('En la (7, 2) solo se pueden elegir 1, 2 y 3', (tester) async {
      await abrirMapaCuatro(tester);

      await tester.tap(find.byKey(const Key('initial-cell-7-2')));
      await tester.pumpAndSettle();

      for (final numero in [1, 2, 3]) {
        expect(sePuedeElegir(tester, numero), isTrue);
      }
      for (final numero in [4, 5, 6]) {
        expect(sePuedeElegir(tester, numero), isFalse);
      }
    });

    testWidgets('Tocar un número no permitido no coloca nada', (tester) async {
      await abrirMapaCuatro(tester);

      await tester.tap(find.byKey(const Key('initial-cell-1-5')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('initial-value-2')));
      await tester.pumpAndSettle();

      expect(find.byType(SimpleDialog), findsOneWidget);
      expect(find.text('0/6'), findsOneWidget);
    });

    testWidgets('Elegir un número permitido sí lo coloca', (tester) async {
      await abrirMapaCuatro(tester);

      await tester.tap(find.byKey(const Key('initial-cell-1-5')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('initial-value-6')));
      await tester.pumpAndSettle();

      expect(textoEn('initial-cell-1-5', '6'), findsOneWidget);
      expect(find.text('1/6'), findsOneWidget);
    });

    testWidgets('En una celda no naranja se pueden elegir los 6', (
      tester,
    ) async {
      await abrirMapaCuatro(tester);

      await tester.tap(find.byKey(const Key('initial-cell-3-3')));
      await tester.pumpAndSettle();

      for (var numero = 1; numero <= 6; numero++) {
        expect(sePuedeElegir(tester, numero), isTrue);
      }
    });

    testWidgets('Colocar los 6 respetando los rangos activa Comenzar', (
      tester,
    ) async {
      await abrirMapaCuatro(tester);
      const valores = [6, 2, 3, 4, 5, 1];

      for (var i = 0; i < 6; i++) {
        final (fila, columna) = mapaCuatro.celdasIniciales[i];
        await tester.tap(find.byKey(Key('initial-cell-$fila-$columna')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(Key('initial-value-${valores[i]}')));
        await tester.pumpAndSettle();
      }

      expect(find.text('6/6'), findsOneWidget);
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNotNull,
      );
    });

    testWidgets('El selector sin rango deja elegir los 6 (otros mapas)', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SelectorValorInicial(valorActual: null, valoresColocados: {}),
          ),
        ),
      );

      for (var numero = 1; numero <= 6; numero++) {
        expect(sePuedeElegir(tester, numero), isTrue);
        expect(textoEn('initial-value-$numero', 'Libre'), findsOneWidget);
      }
    });
  });

  group('Widgets: partida en el Mapa 4', () {
    testWidgets('A falta de un verde lleva 47 y al llenarlo llega a 50', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TableroPage(
            mapa: mapaCuatro,
            dados: DadosFijos([(1, 3)]),
            tablero: tableroCasiLleno(
              mapa: mapaCuatro,
              vacia: (2, 4),
              valoresIniciales: [6, 2, 3, 4, 5, 1],
            ),
            sonidoVictoria: SonidoFalso(),
            sonidoDados: SonidoFalso(),
          ),
        ),
      );
      await tester.tap(find.text('Comenzar'));
      await tester.pump();

      expect(find.text('47 pts'), findsOneWidget);

      await jugarUltimaCelda(tester, celda: '2-4');
      await tester.tap(find.text('Aceptar'));
      await tester.pumpAndSettle();

      expect(find.text('50 pts'), findsOneWidget);
      expect(find.text('Has puntuado 50 puntos'), findsOneWidget);
      expect(find.byKey(const Key('perfect-score')), findsOneWidget);
    });
  });
}
