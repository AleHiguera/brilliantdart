// Prueba de widgets: la bocina del tablero silencia y activa los sonidos.

import 'package:brilliant_mobile/control_sonido.dart';
import 'package:brilliant_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  group('Widgets: botón de silencio', () {
    late SonidoFalso dados;
    late SonidoFalso victoria;
    late SonidoFalso aplausos;
    late SonidoFalso tristeza;

    setUp(() {
      dados = SonidoFalso();
      victoria = SonidoFalso();
      aplausos = SonidoFalso();
      tristeza = SonidoFalso();
    });

    Future<void> abrir(
      WidgetTester tester,
      ControlSonido control, {
      bool casiLleno = false,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TableroPage(
            dados: DadosFijos(const [(1, 3)]),
            tablero: casiLleno ? tableroCasiLleno() : null,
            sonidoDados: dados,
            sonidoVictoria: victoria,
            sonidoAplausos: aplausos,
            sonidoTristeza: tristeza,
            controlSonido: control,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> tocarBocina(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('sonido-boton')));
      await tester.pumpAndSettle();
    }

    testWidgets('Está en el tablero y empieza con sonido', (tester) async {
      await abrir(tester, ControlSonido());

      expect(find.byKey(const Key('sonido-boton')), findsOneWidget);
      expect(find.byKey(const Key('sonido-encendido')), findsOneWidget);
      expect(find.byTooltip('Silenciar sonidos'), findsOneWidget);
    });

    testWidgets('Un toque silencia y otro vuelve a activar', (tester) async {
      final control = ControlSonido();
      await abrir(tester, control);

      await tocarBocina(tester);
      expect(control.silenciado, isTrue);
      expect(find.byKey(const Key('sonido-apagado')), findsOneWidget);
      expect(find.byTooltip('Activar sonidos'), findsOneWidget);

      await tocarBocina(tester);
      expect(control.silenciado, isFalse);
      expect(find.byKey(const Key('sonido-encendido')), findsOneWidget);
    });

    testWidgets('En silencio no suenan los dados', (tester) async {
      await abrir(tester, ControlSonido()..silenciar(true), casiLleno: true);
      await tester.tap(find.text('Comenzar'));
      await tester.pumpAndSettle();

      await lanzarDados(tester);

      expect(dados.reproducciones, 0);
    });

    testWidgets('En silencio no suena la victoria', (tester) async {
      await abrir(tester, ControlSonido()..silenciar(true), casiLleno: true);
      await tester.tap(find.text('Comenzar'));
      await tester.pumpAndSettle();

      await jugarUltimaCelda(tester);

      expect(victoria.reproducciones, 0);
      expect(find.byKey(const Key('game-over-dialog')), findsOneWidget);
    });

    testWidgets('En silencio no suenan los aplausos', (tester) async {
      final tablero = tableroCasiLleno()..colocarDato(0, 0, null);
      await tester.pumpWidget(
        MaterialApp(
          home: TableroPage(
            dados: DadosFijos(const [(1, 3)]),
            tablero: tablero,
            sonidoDados: dados,
            sonidoVictoria: victoria,
            sonidoAplausos: aplausos,
            sonidoTristeza: tristeza,
            controlSonido: ControlSonido()..silenciar(true),
          ),
        ),
      );
      await tester.tap(find.text('Comenzar'));
      await tester.pumpAndSettle();

      await jugarUltimaCelda(tester);

      expect(aplausos.reproducciones, 0);
    });

    testWidgets('Con sonido, todo suena como siempre', (tester) async {
      await abrir(tester, ControlSonido(), casiLleno: true);
      await tester.tap(find.text('Comenzar'));
      await tester.pumpAndSettle();

      await jugarUltimaCelda(tester);

      expect(dados.reproducciones, 1);
      expect(victoria.reproducciones, 1);
    });

    testWidgets('Silenciar corta los sonidos que estén sonando', (
      tester,
    ) async {
      await abrir(tester, ControlSonido(), casiLleno: true);
      await tester.tap(find.text('Comenzar'));
      await tester.pumpAndSettle();
      await lanzarDados(tester);
      expect(dados.reproducciones, 1);

      await tocarBocina(tester);

      expect(dados.cortes, 1);
    });

    testWidgets('Sin control propio usa el de toda la app', (tester) async {
      final anterior = ControlSonido.global;
      addTearDown(() => ControlSonido.global = anterior);
      ControlSonido.global = ControlSonido()..silenciar(true);

      await tester.pumpWidget(
        MaterialApp(
          home: TableroPage(sonidoDados: dados, sonidoVictoria: victoria),
        ),
      );

      expect(find.byKey(const Key('sonido-apagado')), findsOneWidget);
    });

    testWidgets('El silencio sigue al volver a abrir el tablero', (
      tester,
    ) async {
      final control = ControlSonido();
      await abrir(tester, control);
      await tocarBocina(tester);

      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await abrir(tester, control);

      expect(find.byKey(const Key('sonido-apagado')), findsOneWidget);
    });
  });
}
