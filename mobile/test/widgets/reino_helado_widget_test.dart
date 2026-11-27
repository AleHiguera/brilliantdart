// Prueba de widgets: el Mapa 1 convertido en el Reino Helado (nombre, fondo,
// nieve, colores azules y el copo de los números iniciales), sin cambiar el
// juego.

import 'package:brilliant_mobile/colores_zonas.dart';
import 'package:brilliant_mobile/copo_progreso.dart';
import 'package:brilliant_mobile/decoraciones.dart';
import 'package:brilliant_mobile/fondo_app.dart';
import 'package:brilliant_mobile/main.dart';
import 'package:brilliant_mobile/nieve_cayendo.dart';
import 'package:brilliant_mobile/paleta_atardecer.dart';
import 'package:brilliant_mobile/paneles_juego.dart';
import 'package:brilliant_mobile/pantalla_con_tema.dart';
import 'package:brilliant_mobile/tarjetas_sala.dart';
import 'package:brilliant_mobile/tema_mapa.dart';
import 'package:brilliantdart/mapa.dart';
import 'package:brilliantdart/mapa_tres.dart';
import 'package:brilliantdart/mapa_uno.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

Future<void> menu(WidgetTester tester) async {
  await tester.pumpWidget(const BrilliantApp());
  await tester.pumpAndSettle();
}

Future<void> reinoHelado(WidgetTester tester) async {
  await menu(tester);
  await tester.tap(find.byKey(const Key('map-option-1')));
  await tester.pumpAndSettle();
}

Future<void> tablero(WidgetTester tester, {Mapa mapa = mapaUno}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: TableroPage(
        mapa: mapa,
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
  group('Widgets: Reino Helado en el menú', () {
    testWidgets('El Mapa 1 se llama Reino Helado', (tester) async {
      await menu(tester);

      expect(
        find.descendant(
          of: find.byKey(const Key('map-option-1')),
          matching: find.text('Reino Helado'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Abajo sigue diciendo que es el Mapa 1, con un copito', (
      tester,
    ) async {
      await menu(tester);

      expect(find.byKey(const Key('map-number-1')), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('map-number-1'))).data,
        'Mapa 1',
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('map-option-1')),
          matching: find.byIcon(Icons.ac_unit),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Los demás mapas siguen con su nombre y sin copito', (
      tester,
    ) async {
      await menu(tester);

      for (final n in [3, 4]) {
        await tester.ensureVisible(find.byKey(Key('map-option-$n')));
        expect(
          tester.widget<Text>(find.byKey(Key('map-name-$n'))).data,
          'Mapa $n',
        );
        expect(find.byKey(Key('map-number-$n')), findsNothing);
      }
      expect(find.byIcon(Icons.ac_unit), findsOneWidget);
    });

    testWidgets('Su tarjeta es azul hielo y las demás de atardecer', (
      tester,
    ) async {
      await menu(tester);

      final helado = decoracion(tester, find.byKey(const Key('map-card-1')));
      expect(helado.gradient, TemaMapa.reinoHelado.tarjetaDestacada);
      expect(
        decoracion(tester, find.byKey(const Key('map-arrow-1'))).gradient,
        TemaMapa.reinoHelado.botonRedondo,
      );
      expect(
        decoracion(tester, find.byKey(const Key('map-card-3'))).gradient,
        PaletaAtardecer.tarjetaDestacada,
      );
    });

    testWidgets('Para un lector de pantalla también se llama Reino Helado', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await menu(tester);

      expect(find.bySemanticsLabel(RegExp('Reino Helado')), findsWidgets);
      semantica.dispose();
    });
  });

  group('Widgets: el tablero del Reino Helado', () {
    testWidgets('Arriba dice Reino Helado', (tester) async {
      await reinoHelado(tester);

      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Reino Helado'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Tiene de fondo las montañas de hielo', (tester) async {
      await reinoHelado(tester);

      final fondo = find.byKey(const Key('fondo-mapa'));
      expect(fondo, findsOneWidget);
      final imagen = tester.widget<Image>(
        find.descendant(
          of: fondo,
          matching: find.byKey(const Key('fondo-imagen')),
        ),
      );
      expect(
        (imagen.image as AssetImage).assetName,
        TemaMapa.reinoHelado.imagenFondo,
      );
    });

    testWidgets('El fondo del Reino Helado tapa la casa del árbol', (
      tester,
    ) async {
      await reinoHelado(tester);

      final mapa = tester.getRect(find.byKey(const Key('fondo-mapa')));
      final pantalla = tester.getRect(find.byType(Scaffold).last);
      expect(mapa.contains(pantalla.topLeft), isTrue);
      expect(mapa.size, pantalla.size);
    });

    testWidgets('Caen copitos de nieve detrás del tablero', (tester) async {
      await reinoHelado(tester);

      expect(find.byType(NieveCayendo), findsOneWidget);
      // La nieve va debajo de la pantalla del juego, no encima.
      final capas = tester.widget<Stack>(
        find
            .descendant(
              of: find.byKey(const Key('fondo-mapa')),
              matching: find.byType(Stack),
            )
            .at(1),
      );
      expect(capas.children.first, isA<Positioned>());
      expect(capas.children.last, isA<Scaffold>());
    });

    testWidgets('La barra de arriba es azul hielo', (tester) async {
      await reinoHelado(tester);

      final barra = tester.widget<DecoratedBox>(
        find.byKey(const Key('fondo-barra')).last,
      );
      expect(
        (barra.decoration as BoxDecoration).gradient,
        TemaMapa.reinoHelado.barra,
      );
    });

    testWidgets('Los paneles son blanco hielo', (tester) async {
      await tablero(tester);

      final panel = decoracion(tester, find.byKey(const Key('setup-panel')));
      expect(panel.color, ColoresHielo.tarjeta);
      expect((panel.border! as Border).top.color, ColoresHielo.borde);
    });

    testWidgets('El botón desactivado también va en azul', (tester) async {
      await tablero(tester);

      final boton = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(
        boton.style!.backgroundColor!.resolve({WidgetState.disabled}),
        ColoresHielo.borde,
      );
    });

    testWidgets('Los colores del tablero no cambian', (tester) async {
      await tablero(tester);

      for (final (fila, columna) in [(0, 0), (0, 1), (3, 3), (6, 6)]) {
        expect(
          TableroPage.colorEn(fila, columna),
          coloresZonas[mapaUno.tipoEn(fila, columna)],
        );
      }
      expect(find.byType(GridView), findsOneWidget);
    });
  });

  group('Widgets: el copo de los números iniciales', () {
    testWidgets('En el Reino Helado es un copo de nieve, no un círculo', (
      tester,
    ) async {
      await tablero(tester);

      expect(find.byType(CopoProgresoIniciales), findsOneWidget);
      expect(find.byType(RuedaProgresoIniciales), findsNothing);
      expect(find.text('0/6'), findsOneWidget);
    });

    testWidgets('Cuenta los números como antes', (tester) async {
      await tablero(tester);

      await tester.tap(find.byKey(const Key('initial-cell-1-3')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('initial-value-4')));
      await tester.pumpAndSettle();

      expect(find.text('1/6'), findsOneWidget);
      final pintor =
          tester
                  .widget<CustomPaint>(find.byKey(const Key('copo-progreso')))
                  .painter!
              as PintorCopoProgreso;
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

    testWidgets('En los demás mapas sigue la rueda de siempre', (tester) async {
      await tablero(tester, mapa: mapaTres);

      expect(find.byType(RuedaProgresoIniciales), findsOneWidget);
      expect(find.byType(CopoProgresoIniciales), findsNothing);
    });
  });

  group('Widgets: los demás mapas no cambian', () {
    testWidgets('Sin fondo propio, sin nieve y con título Tablero', (
      tester,
    ) async {
      await menu(tester);
      await tester.tap(find.byKey(const Key('map-option-3')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('fondo-mapa')), findsNothing);
      expect(find.byType(NieveCayendo), findsNothing);
      expect(find.text('Tablero'), findsOneWidget);
    });

    testWidgets('Sus paneles siguen en crema de atardecer', (tester) async {
      await tablero(tester, mapa: mapaTres);

      final panel = decoracion(tester, find.byKey(const Key('setup-panel')));
      expect(panel.color, colorTarjeta);
    });
  });

  group('Widgets: el nombre en las salas', () {
    testWidgets('La tarjeta del mapa en la sala dice Reino Helado', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: TarjetaMapa(mapa: mapaUno)),
        ),
      );

      expect(
        tester.widget<Text>(find.byKey(const Key('sala-mapa'))).data,
        'Reino Helado',
      );
    });

    testWidgets('Las demás salas dicen Mapa N', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: TarjetaMapa(mapa: mapaTres)),
        ),
      );

      expect(
        tester.widget<Text>(find.byKey(const Key('sala-mapa'))).data,
        'Mapa 3',
      );
    });
  });

  group('Widgets: nieve', () {
    setUp(() => Decoraciones.animadas = true);
    tearDown(() => Decoraciones.animadas = false);

    Future<void> nieve(WidgetTester tester, {bool reducirMovimiento = false}) =>
        tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(disableAnimations: reducirMovimiento),
              child: const SizedBox(
                width: 300,
                height: 400,
                child: NieveCayendo(),
              ),
            ),
          ),
        );

    PintorNieve pintor(WidgetTester tester) =>
        tester.widget<CustomPaint>(find.byKey(const Key('nieve'))).painter!
            as PintorNieve;

    testWidgets('Los copos caen con el tiempo', (tester) async {
      await nieve(tester);
      final antes = pintor(tester).copos.first.y;
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(pintor(tester).copos.first.y, greaterThan(antes));
    });

    testWidgets('Con «reducir movimiento» se quedan quietos', (tester) async {
      await nieve(tester, reducirMovimiento: true);
      final antes = pintor(tester).copos.first.y;
      await tester.pump(const Duration(seconds: 1));

      expect(pintor(tester).copos.first.y, antes);
    });

    testWidgets('Los toques pasan a través de la nieve', (tester) async {
      var tocado = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Stack(
            children: [
              Positioned.fill(child: GestureDetector(onTap: () => tocado++)),
              const Positioned.fill(child: NieveCayendo()),
            ],
          ),
        ),
      );
      await tester.tapAt(const Offset(100, 100));

      expect(tocado, 1);
    });

    testWidgets('Se dibuja sin errores mientras cae', (tester) async {
      await nieve(tester);
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      expect(tester.binding.transientCallbackCount, 0);
    });
  });

  group('Widgets: PantallaConTema', () {
    testWidgets('Sin fondo propio solo pasa el tema', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PantallaConTema(
            tema: TemaMapa.de(3),
            child: Builder(
              builder: (context) => Text(TemaMapa.maybeOf(context)!.nombre),
            ),
          ),
        ),
      );

      expect(find.text('Mapa 3'), findsOneWidget);
      expect(find.byType(FondoApp), findsNothing);
    });

    testWidgets('Fuera de un mapa no hay tema', (tester) async {
      TemaMapa? tema = TemaMapa.reinoHelado;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            tema = TemaMapa.maybeOf(context);
            return const SizedBox();
          },
        ),
      );

      expect(tema, isNull);
    });
  });
}
