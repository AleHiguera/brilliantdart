// Prueba de widgets: las tarjetas y barras con la paleta de atardecer, en vez
// del blanco con bordes negros.

import 'package:brilliant_mobile/colores_zonas.dart';
import 'package:brilliant_mobile/fondo_app.dart';
import 'package:brilliant_mobile/main.dart';
import 'package:brilliant_mobile/paleta_atardecer.dart';
import 'package:brilliant_mobile/servicio_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

ServicioAuth sinSesion() => ServicioAuth(
  servidor: 'https://servidor:8443',
  cliente: MockClient((_) async => http.Response('{}', 200)),
);

BoxDecoration decoracion(WidgetTester tester, String clave) =>
    tester.widget<Container>(find.byKey(Key(clave))).decoration!
        as BoxDecoration;

Future<void> menu(WidgetTester tester) async {
  await tester.pumpWidget(const BrilliantApp());
  await tester.pumpAndSettle();
}

void main() {
  group('Widgets: tarjetas de los mapas', () {
    testWidgets('Van en degradado crema, no en blanco', (tester) async {
      await menu(tester);

      final tarjeta = decoracion(tester, 'map-card-1');
      expect(tarjeta.gradient, PaletaAtardecer.tarjetaDestacada);
      expect(tarjeta.color, isNull);
    });

    testWidgets('Ya no tienen el borde negro: lo tienen durazno', (
      tester,
    ) async {
      await menu(tester);

      for (var n = 1; n <= 4; n++) {
        await tester.ensureVisible(find.byKey(Key('map-card-$n')));
        final borde = decoracion(tester, 'map-card-$n').border! as Border;
        expect(borde.top.color, PaletaAtardecer.borde);
        expect(borde.top.color, isNot(Colors.black));
      }
    });

    testWidgets('Tienen esquinas más redondas y sombra cálida', (tester) async {
      await menu(tester);

      final tarjeta = decoracion(tester, 'map-card-1');
      expect(tarjeta.borderRadius, BorderRadius.circular(16));
      expect(tarjeta.boxShadow!.single.color, PaletaAtardecer.sombra);
    });

    testWidgets('La flecha es terracota en vez de negra', (tester) async {
      await menu(tester);

      final flecha = decoracion(tester, 'map-arrow-1');
      expect(flecha.gradient, PaletaAtardecer.botonRedondo);
      expect(flecha.color, isNull);
    });

    testWidgets('Se siguen pudiendo tocar para abrir el mapa', (tester) async {
      await menu(tester);
      await tester.tap(find.byKey(const Key('map-option-1')));
      await tester.pumpAndSettle();

      expect(find.text('Tablero'), findsOneWidget);
    });

    testWidgets('El fondo de la tarjeta deja que el toque se vea', (
      tester,
    ) async {
      await menu(tester);

      final material = tester.widget<Material>(
        find
            .ancestor(
              of: find.byKey(const Key('map-choice-1')),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(material.color, Colors.transparent);
    });
  });

  group('Widgets: tarjetas del menú', () {
    testWidgets('Multijugador, Salón y demás usan la tarjeta crema', (
      tester,
    ) async {
      await menu(tester);
      await tester.scrollUntilVisible(
        find.byKey(const Key('how-to-play')),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      final tarjeta = tester.widget<Container>(
        find.byKey(const Key('how-to-play')),
      );
      final fondo = (tarjeta.decoration! as BoxDecoration).color;
      expect(fondo, colorTarjeta);
      expect(fondo, isNot(Colors.white));
    });
  });

  group('Widgets: barras de arriba', () {
    Future<void> comprobarBarra(WidgetTester tester) async {
      final barra = tester.widget<AppBar>(find.byType(AppBar).last);
      expect(barra.backgroundColor, Colors.transparent);
      expect(barra.flexibleSpace, isA<FondoBarra>());
      expect(find.byKey(const Key('fondo-barra')), findsWidgets);
    }

    testWidgets('En el menú', (tester) async {
      await menu(tester);
      await comprobarBarra(tester);
    });

    testWidgets('En el tablero', (tester) async {
      await menu(tester);
      await tester.tap(find.byKey(const Key('map-option-1')));
      await tester.pumpAndSettle();
      await comprobarBarra(tester);
    });

    testWidgets('En el inicio de sesión y al crear cuenta', (tester) async {
      await tester.pumpWidget(BrilliantApp(auth: sinSesion()));
      await tester.pumpAndSettle();
      await comprobarBarra(tester);

      await tester.tap(find.textContaining('Crear cuenta'));
      await tester.pumpAndSettle();
      expect(find.text('Crear cuenta'), findsWidgets);
      await comprobarBarra(tester);
    });

    testWidgets('El degradado y la línea suave de la barra', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: FondoBarra(),
        ),
      );

      final fondo = tester.widget<DecoratedBox>(
        find.byKey(const Key('fondo-barra')),
      );
      final decoracion = fondo.decoration as BoxDecoration;
      expect(decoracion.gradient, PaletaAtardecer.barra);
      expect(
        (decoracion.border! as Border).bottom.color,
        PaletaAtardecer.lineaBarra,
      );
    });

    testWidgets('Al desplazar, la barra no se tiñe', (tester) async {
      await menu(tester);

      final tema = Theme.of(tester.element(find.byType(AppBar)));
      expect(tema.appBarTheme.scrolledUnderElevation, 0);
      expect(tema.appBarTheme.surfaceTintColor, Colors.transparent);
    });
  });
}
