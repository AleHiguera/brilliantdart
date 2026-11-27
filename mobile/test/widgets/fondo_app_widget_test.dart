// Prueba de widgets: la imagen de la casa del árbol de fondo en todas las
// pantallas, con el contenido encima y legible.

import 'package:brilliant_mobile/fondo_app.dart';
import 'package:brilliant_mobile/main.dart';
import 'package:brilliant_mobile/servicio_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

ServicioAuth sinSesion() => ServicioAuth(
  servidor: 'https://servidor:8443',
  cliente: MockClient((_) async => http.Response('{}', 200)),
);

void main() {
  group('Widgets: FondoApp', () {
    Future<void> mostrar(WidgetTester tester) => tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: FondoApp(child: Text('contenido', key: Key('contenido'))),
      ),
    );

    testWidgets('Pone la imagen de la casa del árbol', (tester) async {
      await mostrar(tester);

      final imagen = tester.widget<Image>(
        find.byKey(const Key('fondo-imagen')),
      );
      expect((imagen.image as AssetImage).assetName, imagenFondo);
    });

    testWidgets('La imagen cubre todo sin deformarse', (tester) async {
      await mostrar(tester);

      final imagen = tester.widget<Image>(
        find.byKey(const Key('fondo-imagen')),
      );
      expect(imagen.fit, BoxFit.cover);
      expect(
        tester.getSize(find.byKey(const Key('fondo-imagen'))),
        tester.getSize(find.byType(FondoApp)),
      );
    });

    testWidgets('En un celular vertical se centra hacia la casa', (
      tester,
    ) async {
      await mostrar(tester);

      final imagen = tester.widget<Image>(
        find.byKey(const Key('fondo-imagen')),
      );
      expect((imagen.alignment as Alignment).x, greaterThan(0));
    });

    testWidgets('Encima va el velo y encima de todo el contenido', (
      tester,
    ) async {
      await mostrar(tester);

      final capas = tester.widget<Stack>(
        find.descendant(
          of: find.byType(FondoApp),
          matching: find.byType(Stack),
        ),
      );
      expect(capas.children.length, 3);
      expect(capas.children[0].key, const Key('fondo-imagen'));
      expect(capas.children[1].key, const Key('fondo-velo'));
      expect(find.byKey(const Key('contenido')), findsOneWidget);
      final velo = tester.widget<DecoratedBox>(
        find.byKey(const Key('fondo-velo')),
      );
      expect((velo.decoration as BoxDecoration).gradient, veloFondo);
    });

    testWidgets('Mientras carga se ve el color del cielo, no blanco', (
      tester,
    ) async {
      await mostrar(tester);

      final cielo = tester.widget<ColoredBox>(
        find
            .descendant(
              of: find.byKey(const Key('fondo-imagen')),
              matching: find.byType(ColoredBox),
            )
            .first,
      );
      expect(cielo.color, isNot(Colors.white));
    });

    testWidgets('El contenido ocupa toda la pantalla', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: FondoApp(child: SizedBox.expand(key: Key('contenido'))),
        ),
      );

      expect(
        tester.getSize(find.byKey(const Key('contenido'))),
        tester.getSize(find.byType(FondoApp)),
      );
    });
  });

  group('Widgets: el fondo en la app', () {
    testWidgets('El menú tiene la imagen detrás', (tester) async {
      await tester.pumpWidget(const BrilliantApp());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('fondo-imagen')), findsOneWidget);
      expect(
        find.ancestor(
          of: find.byKey(const Key('map-option-1')),
          matching: find.byType(FondoApp),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Las pantallas ya no tienen fondo blanco', (tester) async {
      await tester.pumpWidget(const BrilliantApp());
      await tester.pumpAndSettle();

      final tema = Theme.of(tester.element(find.byType(Scaffold).first));
      expect(tema.scaffoldBackgroundColor, Colors.transparent);
      final pantalla = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(pantalla.backgroundColor, isNull);
    });

    testWidgets('La barra de arriba lleva el degradado de atardecer', (
      tester,
    ) async {
      await tester.pumpWidget(const BrilliantApp());
      await tester.pumpAndSettle();

      final barra = tester.widget<AppBar>(find.byType(AppBar));
      expect(barra.backgroundColor, Colors.transparent);
      expect(barra.flexibleSpace, isA<FondoBarra>());
    });

    testWidgets('Al abrir un mapa, el tablero también tiene el fondo', (
      tester,
    ) async {
      await tester.pumpWidget(const BrilliantApp());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('map-option-2')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('fondo-imagen')), findsOneWidget);
      expect(
        tester.widget<AppBar>(find.byType(AppBar).last).flexibleSpace,
        isA<FondoBarra>(),
      );
    });

    testWidgets('El inicio de sesión tiene el fondo y campos blancos', (
      tester,
    ) async {
      await tester.pumpWidget(BrilliantApp(auth: sinSesion()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('fondo-imagen')), findsOneWidget);
      final campo = tester.widget<InputDecorator>(
        find.byType(InputDecorator).first,
      );
      expect(campo.decoration.filled, isTrue);
      expect(campo.decoration.fillColor, rellenoCampo);
    });

    testWidgets('Solo hay un fondo aunque se abran varias pantallas', (
      tester,
    ) async {
      await tester.pumpWidget(const BrilliantApp());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('map-option-2')));
      await tester.pumpAndSettle();

      expect(find.byType(FondoApp), findsOneWidget);
    });
  });
}
