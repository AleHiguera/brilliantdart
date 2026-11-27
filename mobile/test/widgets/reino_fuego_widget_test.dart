// Prueba de widgets: el Mapa 2 convertido en el Reino del Fuego (nombre,
// fondo, brasas, colores de fuego y la llama de los números iniciales), sin
// cambiar el juego.

import 'package:brilliant_mobile/chispas_subiendo.dart';
import 'package:brilliant_mobile/colores_zonas.dart';
import 'package:brilliant_mobile/copo_progreso.dart';
import 'package:brilliant_mobile/decoraciones.dart';
import 'package:brilliant_mobile/llama_progreso.dart';
import 'package:brilliant_mobile/main.dart';
import 'package:brilliant_mobile/nieve_cayendo.dart';
import 'package:brilliant_mobile/paneles_juego.dart';
import 'package:brilliant_mobile/tarjetas_sala.dart';
import 'package:brilliant_mobile/tema_mapa.dart';
import 'package:brilliantdart/mapa_dos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

Future<void> menu(WidgetTester tester) async {
  await tester.pumpWidget(const BrilliantApp());
  await tester.pumpAndSettle();
}

Future<void> reinoDelFuego(WidgetTester tester) async {
  await menu(tester);
  await tester.ensureVisible(find.byKey(const Key('map-option-2')));
  await tester.tap(find.byKey(const Key('map-option-2')));
  await tester.pumpAndSettle();
}

Future<void> tablero(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: TableroPage(
        mapa: mapaDos,
        dados: DadosFijos([(1, 6)]),
        sonidoDados: SonidoFalso(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

BoxDecoration decoracion(WidgetTester tester, Finder finder) =>
    tester.widget<Container>(finder).decoration! as BoxDecoration;

void main() {
  group('Widgets: Reino del Fuego en el menú', () {
    testWidgets('El Mapa 2 se llama Reino del Fuego', (tester) async {
      await menu(tester);

      expect(
        tester.widget<Text>(find.byKey(const Key('map-name-2'))).data,
        'Reino del Fuego',
      );
    });

    testWidgets('Abajo dice Mapa 2 con una llamita naranja', (tester) async {
      await menu(tester);

      expect(
        tester.widget<Text>(find.byKey(const Key('map-number-2'))).data,
        'Mapa 2',
      );
      final icono = tester.widget<Icon>(find.byKey(const Key('map-icon-2')));
      expect(icono.icon, Icons.local_fire_department);
      expect(icono.color, ColoresFuego.naranja);
    });

    testWidgets('Su tarjeta y su flecha son de fuego', (tester) async {
      await menu(tester);

      expect(
        decoracion(tester, find.byKey(const Key('map-card-2'))).gradient,
        TemaMapa.reinoDelFuego.tarjetaDestacada,
      );
      expect(
        decoracion(tester, find.byKey(const Key('map-arrow-2'))).gradient,
        TemaMapa.reinoDelFuego.botonRedondo,
      );
    });

    testWidgets('Cada reino tiene su dibujito: copo y llama', (tester) async {
      await menu(tester);

      expect(
        tester.widget<Icon>(find.byKey(const Key('map-icon-1'))).icon,
        Icons.ac_unit,
      );
      expect(find.byKey(const Key('map-icon-3')), findsNothing);
    });
  });

  group('Widgets: el tablero del Reino del Fuego', () {
    testWidgets('Arriba dice Reino del Fuego', (tester) async {
      await reinoDelFuego(tester);

      expect(
        find.descendant(
          of: find.byType(AppBar).last,
          matching: find.text('Reino del Fuego'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Tiene de fondo el volcán', (tester) async {
      await reinoDelFuego(tester);

      final imagen = tester.widget<Image>(
        find.descendant(
          of: find.byKey(const Key('fondo-mapa')),
          matching: find.byKey(const Key('fondo-imagen')),
        ),
      );
      expect(
        (imagen.image as AssetImage).assetName,
        'assets/imagenes/fondo_reino_fuego.jpg',
      );
    });

    testWidgets('Suben brasas detrás del tablero, no nieve', (tester) async {
      await reinoDelFuego(tester);

      expect(find.byType(ChispasSubiendo), findsOneWidget);
      expect(find.byType(NieveCayendo), findsNothing);
      final capas = tester.widget<Stack>(
        find
            .descendant(
              of: find.byKey(const Key('fondo-mapa')),
              matching: find.byType(Stack),
            )
            .at(1),
      );
      expect(capas.children.last, isA<Scaffold>());
    });

    testWidgets('La barra de arriba es de fuego', (tester) async {
      await reinoDelFuego(tester);

      final barra = tester.widget<DecoratedBox>(
        find.byKey(const Key('fondo-barra')).last,
      );
      expect(
        (barra.decoration as BoxDecoration).gradient,
        TemaMapa.reinoDelFuego.barra,
      );
    });

    testWidgets('Los paneles son crema de brasa con borde naranja', (
      tester,
    ) async {
      await tablero(tester);

      final panel = decoracion(tester, find.byKey(const Key('setup-panel')));
      expect(panel.color, ColoresFuego.tarjeta);
      expect((panel.border! as Border).top.color, ColoresFuego.borde);
    });

    testWidgets('El botón desactivado también va en tono de fuego', (
      tester,
    ) async {
      await tablero(tester);

      final boton = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(
        boton.style!.backgroundColor!.resolve({WidgetState.disabled}),
        ColoresFuego.borde,
      );
    });

    testWidgets('Los colores del tablero no cambian', (tester) async {
      await tablero(tester);

      for (final (fila, columna) in [(0, 0), (0, 3), (3, 3), (6, 6)]) {
        expect(
          TableroPage.colorEn(fila, columna, mapa: mapaDos),
          coloresZonas[mapaDos.tipoEn(fila, columna)],
        );
      }
      expect(find.byType(GridView), findsOneWidget);
    });
  });

  group('Widgets: la llama de los números iniciales', () {
    testWidgets('En el Reino del Fuego es una llama, no un círculo', (
      tester,
    ) async {
      await tablero(tester);

      expect(find.byType(LlamaProgresoIniciales), findsOneWidget);
      expect(find.byType(RuedaProgresoIniciales), findsNothing);
      expect(find.byType(CopoProgresoIniciales), findsNothing);
      expect(find.text('0/6'), findsOneWidget);
    });

    testWidgets('Cuenta los números como antes', (tester) async {
      await tablero(tester);
      final celda = mapaDos.celdasIniciales.first;

      await tester.tap(find.byKey(Key('initial-cell-${celda.$1}-${celda.$2}')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('initial-value-4')));
      await tester.pumpAndSettle();

      expect(find.text('1/6'), findsOneWidget);
      final pintor =
          tester
                  .widget<CustomPaint>(find.byKey(const Key('llama-progreso')))
                  .painter!
              as PintorLlamaProgreso;
      expect(pintor.avance, 1);
    });

    testWidgets('Dice lo mismo a un lector de pantalla', (tester) async {
      await tablero(tester);

      expect(
        tester
            .widget<Semantics>(find.byKey(const Key('initial-progress')))
            .properties
            .label,
        '0 de 6 números iniciales colocados',
      );
    });

    testWidgets('Se dibuja sin errores vacía, a medias y llena', (
      tester,
    ) async {
      for (final cantidad in [0, 3, 6]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: LlamaProgresoIniciales(cantidad: cantidad)),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('$cantidad/6'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('Widgets: el nombre en las salas', () {
    testWidgets('La tarjeta del mapa en la sala dice Reino del Fuego', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: TarjetaMapa(mapa: mapaDos)),
        ),
      );

      expect(
        tester.widget<Text>(find.byKey(const Key('sala-mapa'))).data,
        'Reino del Fuego',
      );
    });
  });

  group('Widgets: brasas', () {
    setUp(() => Decoraciones.animadas = true);
    tearDown(() => Decoraciones.animadas = false);

    Future<void> brasas(
      WidgetTester tester, {
      bool reducirMovimiento = false,
    }) => tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reducirMovimiento),
          child: const SizedBox(
            width: 300,
            height: 400,
            child: ChispasSubiendo(),
          ),
        ),
      ),
    );

    PintorChispas pintor(WidgetTester tester) =>
        tester.widget<CustomPaint>(find.byKey(const Key('brasas'))).painter!
            as PintorChispas;

    testWidgets('Suben con el tiempo', (tester) async {
      await brasas(tester);
      final chispa = pintor(tester).chispas.first..y = 0.8;
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(chispa.y, lessThan(0.8));
    });

    testWidgets('Con «reducir movimiento» se quedan quietas', (tester) async {
      await brasas(tester, reducirMovimiento: true);
      final antes = pintor(tester).chispas.first.y;
      await tester.pump(const Duration(seconds: 1));

      expect(pintor(tester).chispas.first.y, antes);
    });

    testWidgets('Los toques pasan a través de las brasas', (tester) async {
      var tocado = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Stack(
            children: [
              Positioned.fill(child: GestureDetector(onTap: () => tocado++)),
              const Positioned.fill(child: ChispasSubiendo()),
            ],
          ),
        ),
      );
      await tester.tapAt(const Offset(100, 100));

      expect(tocado, 1);
    });

    testWidgets('Se dibujan sin errores mientras suben', (tester) async {
      await brasas(tester);
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      expect(tester.binding.transientCallbackCount, 0);
    });
  });
}
