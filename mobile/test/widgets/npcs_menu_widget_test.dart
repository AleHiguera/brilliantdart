// Prueba de widgets: los personajitos que pasean y saludan en el menú, solo
// después de iniciar sesión.

import 'dart:convert';

import 'package:brilliant_mobile/main.dart';
import 'package:brilliant_mobile/npcs_menu.dart';
import 'package:brilliant_mobile/paseo_npc.dart';
import 'package:brilliant_mobile/pintores_npc.dart';
import 'package:brilliant_mobile/servicio_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

ServicioAuth auth({bool conSesion = true}) {
  final servicio = ServicioAuth(
    servidor: 'https://servidor:8443',
    cliente: MockClient(
      (_) async => http.Response.bytes(
        utf8.encode(jsonEncode({'ok': true, 'mensaje': '.', 'elo': 0})),
        200,
      ),
    ),
  );
  if (conSesion) {
    servicio.sesion = const Sesion(usuario: 'ana', nombre: 'Ana', token: 't');
  }
  return servicio;
}

/// Los personajitos solos, en una franja de [ancho].
Future<void> franja(
  WidgetTester tester, {
  double ancho = 300,
  bool reducirMovimiento = false,
}) => tester.pumpWidget(
  MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reducirMovimiento),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: SizedBox(width: ancho, child: const NpcsMenu()),
      ),
    ),
  ),
);

/// Avanza [segundos] con cuadros de 50 ms, como la pantalla real.
Future<void> pasar(WidgetTester tester, double segundos) async {
  for (var i = 0; i < (segundos * 20).round(); i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

double izquierda(WidgetTester tester, String quien) =>
    tester.getTopLeft(find.byKey(Key('npc-$quien'))).dx;

bool mirandoIzquierda(WidgetTester tester, String quien) => tester
    .widget<Transform>(
      find
          .descendant(
            of: find.byKey(Key('npc-$quien')),
            matching: find.byType(Transform),
          )
          .last,
    )
    .transform
    .storage[0]
    .isNegative;

void main() {
  setUp(() => NpcsMenu.habilitados = true);
  tearDown(() => NpcsMenu.habilitados = false);

  group('Widgets: personajitos, cómo se ven', () {
    testWidgets('Hay un niño y un perrito', (tester) async {
      await franja(tester);

      expect(find.byKey(const Key('npc-nino')), findsOneWidget);
      expect(find.byKey(const Key('npc-perro')), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is PintorNino,
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is PintorPerro,
        ),
        findsOneWidget,
      );
    });

    testWidgets('Son super chiquitos', (tester) async {
      await franja(tester);

      final nino = tester.getSize(
        find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is PintorNino,
        ),
      );
      expect(nino.height, lessThanOrEqualTo(40));
      expect(
        tester.getSize(find.byKey(const Key('npcs-menu'))).height,
        NpcsMenu.alto,
      );
    });

    testWidgets('Los dibujos se pintan sin errores, caminando y saludando', (
      tester,
    ) async {
      for (final saludando in [false, true]) {
        for (final paso in [-1.0, 0.0, 1.0]) {
          await tester.pumpWidget(
            Row(
              textDirection: TextDirection.ltr,
              children: [
                CustomPaint(
                  size: tamanoNino,
                  painter: PintorNino(paso: paso, saludando: saludando),
                ),
                CustomPaint(
                  size: tamanoPerro,
                  painter: PintorPerro(paso: paso, saludando: saludando),
                ),
              ],
            ),
          );
          expect(tester.takeException(), isNull);
        }
      }
    });

    testWidgets('Solo se vuelven a pintar si cambió el paso o el saludo', (
      tester,
    ) async {
      const nino = PintorNino(paso: 0.5, saludando: false);
      expect(
        nino.shouldRepaint(const PintorNino(paso: 0.5, saludando: false)),
        isFalse,
      );
      expect(
        nino.shouldRepaint(const PintorNino(paso: 0.2, saludando: false)),
        isTrue,
      );
      const perro = PintorPerro(paso: 0, saludando: true);
      expect(
        perro.shouldRepaint(const PintorPerro(paso: 0, saludando: false)),
        isTrue,
      );
    });
  });

  group('Widgets: personajitos, caminar y saludar', () {
    testWidgets('Caminan solos con el tiempo', (tester) async {
      await franja(tester);
      final antes = izquierda(tester, 'nino');

      await pasar(tester, 1);
      expect(izquierda(tester, 'nino'), greaterThan(antes));
    });

    testWidgets('Miran hacia donde caminan', (tester) async {
      await franja(tester);
      await pasar(tester, 0.2);

      // El niño empieza a la derecha y el perrito a la izquierda.
      expect(mirandoIzquierda(tester, 'nino'), isFalse);
      expect(mirandoIzquierda(tester, 'perro'), isTrue);
    });

    testWidgets('Al llegar a la orilla se dan la vuelta', (tester) async {
      await franja(tester, ancho: 120);
      await pasar(tester, 4);

      expect(mirandoIzquierda(tester, 'nino'), isTrue);
      expect(izquierda(tester, 'nino'), lessThan(120));
    });

    testWidgets('Después de caminar un rato, el niño dice ¡Hola!', (
      tester,
    ) async {
      await franja(tester, ancho: 1000);
      expect(find.byKey(const Key('npc-saludo-nino')), findsNothing);

      await pasar(tester, 5.2);
      expect(find.byKey(const Key('npc-saludo-nino')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('npc-saludo-nino')),
          matching: find.text(PaseoNpc.saludo),
        ),
        findsOneWidget,
      );
    });

    testWidgets('El saludo dura un momento y luego sigue caminando', (
      tester,
    ) async {
      await franja(tester, ancho: 1000);
      await pasar(tester, 5.2);
      final dondeSaludo = izquierda(tester, 'nino');

      await pasar(tester, 2.5);
      expect(find.byKey(const Key('npc-saludo-nino')), findsNothing);
      await pasar(tester, 0.5);
      expect(izquierda(tester, 'nino'), isNot(dondeSaludo));
    });

    testWidgets('El perrito también saluda, a su ritmo', (tester) async {
      await franja(tester, ancho: 1000);
      await pasar(tester, 6.7);

      expect(find.byKey(const Key('npc-saludo-perro')), findsOneWidget);
    });

    testWidgets('Nunca se salen de la franja', (tester) async {
      await franja(tester, ancho: 200);
      for (var i = 0; i < 30; i++) {
        await pasar(tester, 0.5);
        for (final quien in ['nino', 'perro']) {
          final caja = tester.getRect(find.byKey(Key('npc-$quien')));
          expect(caja.left, greaterThanOrEqualTo(-0.01));
          expect(caja.right, lessThanOrEqualTo(200.01));
        }
      }
    });
  });

  group('Widgets: personajitos, sin estorbar', () {
    testWidgets('Los toques pasan a través de ellos', (tester) async {
      var tocado = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  key: const Key('debajo'),
                  onTap: () => tocado++,
                ),
              ),
              const Align(
                alignment: Alignment.bottomLeft,
                child: SizedBox(width: 300, child: NpcsMenu()),
              ),
            ],
          ),
        ),
      );

      await tester.tapAt(tester.getCenter(find.byKey(const Key('npc-nino'))));
      expect(tocado, 1);
    });

    testWidgets('Con «reducir movimiento» se quedan quietos', (tester) async {
      await franja(tester, reducirMovimiento: true);
      final antes = izquierda(tester, 'nino');

      await pasar(tester, 2);
      expect(izquierda(tester, 'nino'), antes);
    });

    testWidgets('Apagados no se dibujan', (tester) async {
      NpcsMenu.habilitados = false;
      await franja(tester);

      expect(find.byKey(const Key('npcs-menu')), findsNothing);
    });

    testWidgets('Al cerrar la pantalla dejan de moverse sin errores', (
      tester,
    ) async {
      await franja(tester);
      await pasar(tester, 0.5);
      await tester.pumpWidget(const SizedBox());

      expect(tester.takeException(), isNull);
      expect(tester.binding.transientCallbackCount, 0);
    });
  });

  group('Widgets: personajitos en el menú', () {
    testWidgets('Después de iniciar sesión pasean por el menú', (tester) async {
      await tester.pumpWidget(BrilliantApp(auth: auth()));
      await pasar(tester, 1);

      expect(find.byType(NpcsMenu), findsOneWidget);
      final franja = tester.getRect(find.byKey(const Key('npcs-menu')));
      final pantalla = tester.getRect(find.byType(Scaffold).first);
      expect(franja.bottom, closeTo(pantalla.bottom, 1));
    });

    testWidgets('Sin sesión no aparecen', (tester) async {
      await tester.pumpWidget(const BrilliantApp());
      await pasar(tester, 1);

      expect(find.byType(NpcsMenu), findsNothing);
    });

    testWidgets('En la pantalla de iniciar sesión no aparecen', (tester) async {
      await tester.pumpWidget(BrilliantApp(auth: auth(conSesion: false)));
      await pasar(tester, 1);

      expect(find.byType(NpcsMenu), findsNothing);
    });

    testWidgets('Al abrir un mapa ya no se ven (solo en la entrada)', (
      tester,
    ) async {
      await tester.pumpWidget(BrilliantApp(auth: auth()));
      await pasar(tester, 1);
      await tester.tap(find.byKey(const Key('map-option-1')));
      await pasar(tester, 1);

      expect(find.byType(NpcsMenu, skipOffstage: true), findsNothing);
      expect(find.text('Tablero'), findsOneWidget);
    });

    testWidgets('No tapan lo último del menú: la lista deja espacio abajo', (
      tester,
    ) async {
      await tester.pumpWidget(BrilliantApp(auth: auth()));
      await pasar(tester, 1);

      final lista = tester.widget<ListView>(find.byType(ListView).first);
      expect(
        (lista.padding! as EdgeInsets).bottom,
        greaterThanOrEqualTo(NpcsMenu.alto),
      );
    });

    testWidgets('Se puede tocar un mapa aunque pasen por encima', (
      tester,
    ) async {
      await tester.pumpWidget(BrilliantApp(auth: auth()));
      await pasar(tester, 1);
      await tester.tap(find.byKey(const Key('map-option-2')));
      await pasar(tester, 1);

      expect(find.text('Tablero'), findsOneWidget);
    });
  });
}
