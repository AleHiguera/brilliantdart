// Prueba de widgets: la animación de mi ELO al terminar la partida (monedas
// si subió, personajito triste si bajó, nada si quedó igual).

import 'package:brilliant_mobile/celebracion_elo.dart';
import 'package:brilliant_mobile/datos_sala.dart';
import 'package:brilliant_mobile/decoraciones.dart';
import 'package:brilliant_mobile/panel_fin_compartido.dart';
import 'package:brilliant_mobile/pintores_npc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const ResultadoEloJugador gane = (
  lugar: 1,
  antes: 1000,
  cambio: 16,
  despues: 1016,
);
const ResultadoEloJugador perdi = (
  lugar: 2,
  antes: 40,
  cambio: -8,
  despues: 32,
);
const ResultadoEloJugador igual = (
  lugar: 1,
  antes: 500,
  cambio: 0,
  despues: 500,
);

Future<void> mostrar(
  WidgetTester tester,
  ResultadoEloJugador resultado, {
  bool reducirMovimiento = false,
}) => tester.pumpWidget(
  MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reducirMovimiento),
      child: Scaffold(
        body: Center(child: CelebracionElo(resultado: resultado)),
      ),
    ),
  ),
);

/// El número que se ve en el contador.
String contador(WidgetTester tester) => tester
    .widget<Text>(find.byKey(const Key('elo-contador')))
    .textSpan!
    .toPlainText()
    .replaceAll('ELO ', '');

double saltoDelCambio(WidgetTester tester) => tester
    .widget<Transform>(
      find
          .ancestor(
            of: find.byKey(const Key('elo-cambio-animado')),
            matching: find.byType(Transform),
          )
          .first,
    )
    .transform
    .storage[0];

Future<void> pasar(WidgetTester tester, int milisegundos) async {
  for (var t = 0; t < milisegundos; t += 50) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  setUp(() => Decoraciones.animadas = true);
  tearDown(() => Decoraciones.animadas = false);

  group('Widgets: gané ELO', () {
    testWidgets('Dice que gané ELO, en una tarjeta dorada', (tester) async {
      await mostrar(tester, gane);

      expect(find.byKey(const Key('elo-subio')), findsOneWidget);
      expect(find.text('¡Ganaste ELO!'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is PintorMoneda,
        ),
        findsOneWidget,
      );
    });

    testWidgets('El número empieza en el ELO de antes', (tester) async {
      await mostrar(tester, gane);

      expect(contador(tester), '1000');
    });

    testWidgets('Va subiendo de a poco', (tester) async {
      await mostrar(tester, gane);
      await pasar(tester, 500);

      final valor = int.parse(contador(tester));
      expect(valor, greaterThan(1000));
      expect(valor, lessThan(1016));
    });

    testWidgets('Termina en el ELO nuevo', (tester) async {
      await mostrar(tester, gane);
      await pasar(tester, 2000);

      expect(contador(tester), '1016');
    });

    testWidgets('Brotan monedas que se mueven', (tester) async {
      await mostrar(tester, gane);
      await pasar(tester, 100);
      final pintor =
          tester.widget<CustomPaint>(find.byKey(const Key('monedas'))).painter!
              as PintorLluviaMonedas;
      final antes = pintor.monedas.first.y;
      await pasar(tester, 200);

      expect(pintor.monedas.length, 12);
      expect(pintor.monedas.first.y, isNot(antes));
    });

    testWidgets('El +16 salta al terminar de contar', (tester) async {
      await mostrar(tester, gane);
      expect(saltoDelCambio(tester), 0);

      await pasar(tester, 2200);
      expect(saltoDelCambio(tester), closeTo(1, 0.01));
      expect(
        find.descendant(
          of: find.byKey(const Key('elo-cambio-animado')),
          matching: find.text('+16'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('La animación termina sola', (tester) async {
      await mostrar(tester, gane);
      await pasar(tester, 4000);

      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Las monedas no estorban los toques', (tester) async {
      await mostrar(tester, gane);
      await pasar(tester, 100);

      expect(
        find.ancestor(
          of: find.byKey(const Key('monedas')),
          matching: find.byType(IgnorePointer),
        ),
        findsWidgets,
      );
    });
  });

  group('Widgets: perdí ELO', () {
    testWidgets('Sale el personajito triste bajo su nubecita', (tester) async {
      await mostrar(tester, perdi);

      expect(find.byKey(const Key('elo-bajo')), findsOneWidget);
      expect(find.text('Perdiste ELO'), findsOneWidget);
      expect(find.byKey(const Key('monito-triste')), findsOneWidget);
      final nino =
          tester
                  .widget<CustomPaint>(
                    find.byWidgetPredicate(
                      (w) => w is CustomPaint && w.painter is PintorNino,
                    ),
                  )
                  .painter!
              as PintorNino;
      expect(nino.triste, isTrue);
      expect(
        find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is PintorNubeTriste,
        ),
        findsOneWidget,
      );
    });

    testWidgets('No salen monedas', (tester) async {
      await mostrar(tester, perdi);
      await pasar(tester, 300);

      expect(find.byKey(const Key('monedas')), findsNothing);
      expect(find.text('¡Ganaste ELO!'), findsNothing);
    });

    testWidgets('El número baja contando', (tester) async {
      await mostrar(tester, perdi);
      expect(contador(tester), '40');

      await pasar(tester, 500);
      final valor = int.parse(contador(tester));
      expect(valor, lessThan(40));
      expect(valor, greaterThan(32));

      await pasar(tester, 2000);
      expect(contador(tester), '32');
    });

    testWidgets('Al final dice −8 en rojo', (tester) async {
      await mostrar(tester, perdi);
      await pasar(tester, 2500);

      final texto = tester.widget<Text>(
        find.descendant(
          of: find.byKey(const Key('elo-cambio-animado')),
          matching: find.text('−8'),
        ),
      );
      expect(texto.style!.color, const Color(0xFFB3261E));
    });
  });

  group('Widgets: quedé igual', () {
    testWidgets('No pasa nada: no se muestra', (tester) async {
      await mostrar(tester, igual);
      await pasar(tester, 500);

      expect(find.byKey(const Key('elo-subio')), findsNothing);
      expect(find.byKey(const Key('elo-bajo')), findsNothing);
      expect(find.byKey(const Key('elo-contador')), findsNothing);
    });
  });

  group('Widgets: sin animación', () {
    testWidgets('Con «reducir movimiento» se ve directo cómo quedó', (
      tester,
    ) async {
      await mostrar(tester, gane, reducirMovimiento: true);

      expect(contador(tester), '1016');
      expect(saltoDelCambio(tester), closeTo(1, 0.01));
      expect(find.byKey(const Key('monedas')), findsNothing);
      await pasar(tester, 1000);
      expect(contador(tester), '1016');
    });

    testWidgets('Con los adornos apagados también', (tester) async {
      Decoraciones.animadas = false;
      await mostrar(tester, perdi);

      expect(contador(tester), '32');
      expect(find.byKey(const Key('monito-triste')), findsOneWidget);
    });
  });

  group('Widgets: en la pantalla final', () {
    Future<void> fin(
      WidgetTester tester,
      Map<String, ResultadoEloJugador> resultados,
    ) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PanelFinCompartido(
              ganadores: const ['ana'],
              usuario: 'ana',
              puntos: const {'ana': 8, 'luis': 3},
              jugadores: const ['ana', 'luis'],
              meta: 26,
              onVolver: () {},
              resultadosElo: resultados,
            ),
          ),
        ),
      ),
    );

    testWidgets('Sale mi animación arriba de la tabla', (tester) async {
      await fin(tester, {
        'ana': gane,
        'luis': (lugar: 2, antes: 1000, cambio: -16, despues: 984),
      });

      expect(find.byKey(const Key('celebracion-elo')), findsOneWidget);
      expect(
        tester.getTopLeft(find.byKey(const Key('celebracion-elo'))).dy,
        lessThan(tester.getTopLeft(find.byKey(const Key('clasificacion'))).dy),
      );
    });

    testWidgets('Es la mía, no la de otro jugador', (tester) async {
      await fin(tester, {'ana': perdi, 'luis': gane});

      expect(find.byKey(const Key('elo-bajo')), findsOneWidget);
      expect(find.byKey(const Key('elo-subio')), findsNothing);
    });

    testWidgets('Sin mi resultado de ELO no sale', (tester) async {
      await fin(tester, {'luis': gane});

      expect(find.byKey(const Key('celebracion-elo')), findsNothing);
    });

    testWidgets('La tabla con el ELO de todos sigue igual', (tester) async {
      await fin(tester, {
        'ana': gane,
        'luis': (lugar: 2, antes: 1000, cambio: -16, despues: 984),
      });

      expect(find.byKey(const Key('elo-ana')), findsOneWidget);
      expect(find.byKey(const Key('elo-luis')), findsOneWidget);
    });
  });
}
