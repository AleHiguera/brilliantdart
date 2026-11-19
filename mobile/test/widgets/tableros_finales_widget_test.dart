// Prueba de widgets: los tableros de todos al terminar la partida, con su
// lugar, sus puntos y sus números sobre los colores del mapa.

import 'package:brilliantdart/catalogo_mapas.dart';
import 'package:brilliantdart/clasificacion.dart';
import 'package:brilliantdart/mapa_uno.dart';
import 'package:brilliant_mobile/colores_zonas.dart';
import 'package:brilliant_mobile/panel_fin_compartido.dart';
import 'package:brilliant_mobile/tableros_finales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final deAna = '3${'0' * 47}6';
  final deLuis = '1${'0' * 48}';
  final deEva = '0' * 49;

  List<Puesto> puestos = const [
    (lugar: 1, jugador: 'luis', puntos: 20, salio: false),
    (lugar: 2, jugador: 'ana', puntos: 12, salio: false),
    (lugar: 3, jugador: 'sol', puntos: 5, salio: true),
  ];

  Future<void> mostrar(
    WidgetTester tester,
    Map<String, String> tableros, {
    double ancho = 400,
  }) async {
    tester.view.physicalSize = Size(ancho, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TablerosFinales(
              mapa: mapaUno,
              tableros: tableros,
              puestos: puestos,
              usuario: 'ana',
            ),
          ),
        ),
      ),
    );
  }

  Finder en(String jugador, String texto) => find.descendant(
    of: find.byKey(Key('tablero-final-$jugador')),
    matching: find.text(texto),
  );

  group('Widgets: tableros al final', () {
    testWidgets('Cada tablero dice de quién es, su lugar y sus puntos', (
      tester,
    ) async {
      await mostrar(tester, {'ana': deAna, 'luis': deLuis});

      expect(en('luis', '@luis'), findsOneWidget);
      expect(en('luis', '1.º lugar · 20 pts'), findsOneWidget);
      expect(en('ana', '@ana (tú)'), findsOneWidget);
      expect(en('ana', '2.º lugar · 12 pts'), findsOneWidget);
    });

    testWidgets('Quien ganó lleva el trofeo y va primero', (tester) async {
      await mostrar(tester, {'ana': deAna, 'luis': deLuis});

      expect(
        find.descendant(
          of: find.byKey(const Key('tablero-final-luis')),
          matching: find.byIcon(Icons.emoji_events),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('tablero-final-ana')),
          matching: find.byIcon(Icons.emoji_events),
        ),
        findsNothing,
      );
      expect(
        tester.getTopLeft(find.byKey(const Key('tablero-final-luis'))).dx,
        lessThan(
          tester.getTopLeft(find.byKey(const Key('tablero-final-ana'))).dx,
        ),
      );
    });

    testWidgets('Quien abandonó también aparece, marcado y al final', (
      tester,
    ) async {
      await mostrar(tester, {
        'eva': deEva,
        'ana': deAna,
        'sol': deEva,
        'luis': deLuis,
      });

      // sol salió con puntos: sigue en su lugar de la clasificación.
      expect(en('sol', 'Abandonó · 5 pts'), findsOneWidget);
      // eva salió sin puntos: no está en la clasificación y va al final.
      expect(en('eva', 'Abandonó · 0 pts'), findsOneWidget);
      final orden = ['luis', 'ana', 'sol', 'eva']
          .map((j) => tester.getTopLeft(find.byKey(Key('tablero-final-$j'))))
          .toList();
      for (var i = 1; i < orden.length; i++) {
        final antes = orden[i - 1];
        final despues = orden[i];
        expect(
          despues.dy > antes.dy ||
              (despues.dy == antes.dy && despues.dx > antes.dx),
          isTrue,
          reason: 'el tablero $i va después del ${i - 1}',
        );
      }
    });

    testWidgets('Solo aparecen los tableros que llegaron', (tester) async {
      await mostrar(tester, {'luis': deLuis});

      expect(find.byKey(const Key('tablero-final-luis')), findsOneWidget);
      expect(find.byKey(const Key('tablero-final-ana')), findsNothing);
    });

    testWidgets('Sin tableros no se muestra nada', (tester) async {
      await mostrar(tester, {});

      expect(find.byKey(const Key('tableros-finales')), findsNothing);
    });

    testWidgets('En el celular van dos por fila; en pantalla ancha, tres', (
      tester,
    ) async {
      final tres = {'ana': deAna, 'luis': deLuis, 'sol': deEva};

      await mostrar(tester, tres, ancho: 360);
      expect(
        tester.getTopLeft(find.byKey(const Key('tablero-final-sol'))).dy,
        greaterThan(
          tester.getTopLeft(find.byKey(const Key('tablero-final-luis'))).dy,
        ),
      );

      await mostrar(tester, tres, ancho: 700);
      expect(
        tester.getTopLeft(find.byKey(const Key('tablero-final-sol'))).dy,
        tester.getTopLeft(find.byKey(const Key('tablero-final-luis'))).dy,
      );
    });
  });

  group('Widgets: tablero pequeño', () {
    Future<void> dibujar(WidgetTester tester, String texto) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 210,
              child: TableroMini(
                mapa: mapaUno,
                numeros: [
                  for (final c in texto.split(''))
                    c == '0' ? null : int.parse(c),
                ],
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('Muestra cada número y deja vacías las demás', (tester) async {
      await dibujar(tester, deAna);

      expect(find.text('3'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
      expect(find.byType(Text), findsNWidgets(2));
    });

    testWidgets('Cada celda lleva el color del mapa', (tester) async {
      await dibujar(tester, deEva);

      final colores = tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .map((caja) => (caja.decoration as BoxDecoration).color)
          .where((color) => coloresZonas.containsValue(color))
          .toList();
      expect(colores, hasLength(49));
      for (var i = 0; i < 49; i++) {
        expect(colores[i], coloresZonas[mapaUno.tipoEn(i ~/ 7, i % 7)]);
      }
    });

    testWidgets('Es cuadrado', (tester) async {
      await dibujar(tester, deEva);

      final tamano = tester.getSize(find.byType(TableroMini));
      expect(tamano.width, tamano.height);
    });
  });

  group('Widgets: tableros finales en cada mapa', () {
    for (final mapa in mapasDisponibles) {
      testWidgets('Mapa ${mapa.numero}: colores y números de ese mapa', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(360, 1400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        // Cada jugador con un número distinto en la primera celda.
        final tableros = {
          for (final (i, j) in [
            'ana',
            'luis',
            'eva',
            'sol',
            'leo',
            'mia',
          ].indexed)
            j: '${i + 1}${'0' * 48}',
        };
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: TablerosFinales(
                  mapa: mapa,
                  tableros: tableros,
                  puestos: [
                    for (final (i, j) in tableros.keys.indexed)
                      (lugar: i + 1, jugador: j, puntos: 10 - i, salio: false),
                  ],
                  usuario: 'ana',
                ),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        for (final (i, jugador) in tableros.keys.indexed) {
          final tarjeta = find.byKey(Key('tablero-final-$jugador'));
          expect(tarjeta, findsOneWidget);
          expect(
            find.descendant(of: tarjeta, matching: find.text('${i + 1}')),
            findsOneWidget,
          );
          final colores = tester
              .widgetList<DecoratedBox>(
                find.descendant(
                  of: tarjeta,
                  matching: find.byType(DecoratedBox),
                ),
              )
              .map((caja) => (caja.decoration as BoxDecoration).color)
              .where(coloresZonas.containsValue)
              .toList();
          expect(colores, [
            for (var c = 0; c < 49; c++)
              coloresZonas[mapa.tipoEn(c ~/ 7, c % 7)],
          ]);
        }
      });
    }
  });

  group('Widgets: pantalla final con tableros', () {
    Future<void> panel(
      WidgetTester tester, {
      Map<String, String> tableros = const {},
      bool conMapa = true,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PanelFinCompartido(
                ganadores: const ['luis'],
                usuario: 'ana',
                puntos: const {'luis': 20, 'ana': 12},
                jugadores: const ['ana', 'luis'],
                meta: 20,
                onVolver: () {},
                mapa: conMapa ? mapaUno : null,
                tablerosFinales: tableros,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('Sigue diciendo quién ganó y permite volver al menú', (
      tester,
    ) async {
      await panel(tester, tableros: {'ana': deAna, 'luis': deLuis});

      expect(find.byKey(const Key('fin-titulo')), findsOneWidget);
      expect(find.byKey(const Key('fin-volver')), findsOneWidget);
      expect(find.byKey(const Key('tableros-finales')), findsOneWidget);
    });

    testWidgets('Los tableros usan los lugares de la clasificación', (
      tester,
    ) async {
      await panel(tester, tableros: {'ana': deAna, 'luis': deLuis});

      expect(en('luis', '1.º lugar · 20 pts'), findsOneWidget);
      expect(en('ana', '2.º lugar · 12 pts'), findsOneWidget);
    });

    testWidgets('Sin tableros o sin mapa, no hay apartado de tableros', (
      tester,
    ) async {
      await panel(tester);
      expect(find.byKey(const Key('tableros-finales')), findsNothing);

      await panel(tester, tableros: {'ana': deAna}, conMapa: false);
      expect(find.byKey(const Key('tableros-finales')), findsNothing);
    });
  });
}
