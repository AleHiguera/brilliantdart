import 'dart:math';

import 'package:brilliantdart/bloc_valores_iniciales.dart';
import 'package:brilliantdart/mapa_uno.dart';
import 'package:brilliantdart/validador_anclas.dart';
import 'package:brilliant_mobile/main.dart';
import 'package:brilliant_mobile/panel_lanzamiento_dados.dart';
import 'package:brilliant_mobile/sonidos.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {

  group('Sonidos', () {
    Widget panelConSonido(
      Sonido sonido, {
      required List<(int, int)> lanzamientos,
      bool partidaFinalizada = false,
      VoidCallback? onPasarTurno,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PanelLanzamientoDados(
              dados: DadosFijos(lanzamientos),
              validadorAnclas: ValidadorAnclas(MapaUno.crearTablero()),
              onOpcionAnclaChanged: (_) {},
              onPasarTurno: onPasarTurno ?? () {},
              onHistorialActualizado: () {},
              partidaFinalizada: partidaFinalizada,
              sonidoDados: sonido,
            ),
          ),
        ),
      );
    }

    testWidgets('Los archivos de sonido vienen incluidos en la app',
        (tester) async {
      for (final ruta in [Sonido.dados, Sonido.victoria]) {
        final datos = await rootBundle.load('assets/$ruta');

        expect(datos.lengthInBytes, greaterThan(44), reason: ruta);
        expect(
          String.fromCharCodes(datos.buffer.asUint8List(8, 4)),
          'WAVE',
          reason: ruta,
        );
      }
    });

    test('SonidoAsset recuerda qué archivo debe sonar', () {
      expect(SonidoAsset(Sonido.dados).ruta, 'sonidos/dados.wav');
      expect(SonidoAsset(Sonido.victoria).ruta, 'sonidos/victoria.wav');
    });

    testWidgets('Los dados suenan al empezar a lanzarlos', (tester) async {
      final sonido = SonidoFalso();
      await tester.pumpWidget(
        panelConSonido(sonido, lanzamientos: [(1, 2)]),
      );
      expect(sonido.reproducciones, 0);

      await tester.tap(find.byKey(const Key('roll-dice-button')));
      await tester.pump();
      expect(find.text('Lanzando dados...'), findsOneWidget);
      expect(sonido.reproducciones, 1);

      await tester.pump(const Duration(milliseconds: 1300));
      await tester.pumpAndSettle();
      expect(sonido.reproducciones, 1);
    });

    testWidgets('Los dados suenan una vez por cada lanzamiento',
        (tester) async {
      final sonido = SonidoFalso();
      await tester.pumpWidget(
        panelConSonido(sonido, lanzamientos: [(1, 2), (3, 4), (5, 6)]),
      );

      for (var lanzamiento = 1; lanzamiento <= 3; lanzamiento++) {
        await lanzarDados(tester);
        expect(sonido.reproducciones, lanzamiento);
        await tester.tap(find.byKey(const Key('pass-turn-button')));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('No suenan si el botón está desactivado esperando decisión',
        (tester) async {
      final sonido = SonidoFalso();
      await tester.pumpWidget(
        panelConSonido(sonido, lanzamientos: [(1, 2), (3, 4)]),
      );
      await lanzarDados(tester);

      await tester.tap(find.byKey(const Key('roll-dice-button')));
      await tester.pump(const Duration(milliseconds: 1300));

      expect(sonido.reproducciones, 1);
    });

    testWidgets('No suenan cuando la partida ya terminó', (tester) async {
      final sonido = SonidoFalso();
      await tester.pumpWidget(
        panelConSonido(sonido, lanzamientos: [(1, 2)], partidaFinalizada: true),
      );

      await tester.tap(find.byKey(const Key('roll-dice-button')));
      await tester.pump(const Duration(milliseconds: 1300));

      expect(sonido.reproducciones, 0);
    });

    testWidgets('En el tablero suenan los dados y al final la victoria',
        (tester) async {
      final sonidoDados = SonidoFalso();
      final sonidoVictoria = SonidoFalso();
      await tester.pumpWidget(
        MaterialApp(
          home: TableroPage(
            dados: DadosFijos([(2, 6), (1, 3)]),
            tablero: tableroCasiLleno(),
            sonidoDados: sonidoDados,
            sonidoVictoria: sonidoVictoria,
          ),
        ),
      );
      await tester.tap(find.text('Comenzar'));
      await tester.pump();
      expect(sonidoDados.reproducciones, 0);

      await lanzarDados(tester);
      expect(sonidoDados.reproducciones, 1);
      await tester.tap(find.byKey(const Key('pass-turn-button')));
      await tester.pumpAndSettle();
      expect(sonidoVictoria.reproducciones, 0);

      await jugarUltimaCelda(tester);
      expect(sonidoDados.reproducciones, 2);
      expect(sonidoVictoria.reproducciones, 1);
    });
  });

  group('Partida completa', () {
    testWidgets('Se juega una partida entera solo con los botones',
        (tester) async {
      // Se planea la partida sobre un tablero de prueba con las mismas reglas
      // y luego se reproduce tocando la pantalla como lo haría un jugador.
      final planificado = MapaUno.crearTablero();
      final bloc = BlocValoresIniciales(planificado);
      for (var i = 0; i < 6; i++) {
        final (fila, columna) = BlocValoresIniciales.celdasIniciales[i];
        bloc.colocarValorInicial(fila, columna, i + 1);
      }
      final validador = ValidadorAnclas(planificado);
      final azar = Random(2024);
      final lanzamientos = <(int, int)>[];
      final jugadas = <(int, int, int)?>[];
      // Límite de seguridad: si la partida se atascara, la prueba falla en
      // lugar de quedarse colgada.
      while (!planificado.estaLleno && lanzamientos.length < 500) {
        final dado1 = azar.nextInt(6) + 1;
        final dado2 = azar.nextInt(6) + 1;
        lanzamientos.add((dado1, dado2));
        final posibles = [
          for (final opcion in validador.obtenerOpciones(dado1, dado2))
            for (final movimiento
                in validador.obtenerMovimientosPosibles(opcion))
              (opcion, movimiento.destino),
        ];
        if (posibles.isEmpty) {
          jugadas.add(null);
          continue;
        }
        final (opcion, destino) = posibles[azar.nextInt(posibles.length)];
        jugadas.add((opcion.ancla, destino.x + 1, destino.y + 1));
        planificado.colocarDato(destino.x, destino.y, opcion.numeroAColocar);
      }
      expect(planificado.estaLleno, isTrue,
          reason: 'La partida planeada debe poder terminarse');

      final tablero = MapaUno.crearTablero();
      final sonido = SonidoFalso();
      final dados = DadosFijos(lanzamientos);
      await tester.pumpWidget(
        MaterialApp(
          home: TableroPage(
            dados: dados,
            tablero: tablero,
            sonidoVictoria: sonido,
            sonidoDados: SonidoFalso(),
          ),
        ),
      );

      for (var i = 0; i < 6; i++) {
        final (fila, columna) = BlocValoresIniciales.celdasIniciales[i];
        await tester.tap(find.byKey(Key('initial-cell-$fila-$columna')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(Key('initial-value-${i + 1}')));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Comenzar'));
      await tester.pump();

      var turnosPasados = 0;
      for (final jugada in jugadas) {
        expect(find.byKey(const Key('game-over-dialog')), findsNothing);
        await lanzarDados(tester);

        if (jugada == null) {
          expect(
            find.text('No se puede realizar ningún movimiento'),
            findsOneWidget,
          );
          await tester.tap(find.byKey(const Key('pass-turn-button')));
          await tester.pumpAndSettle();
          turnosPasados++;
          continue;
        }

        final (ancla, fila, columna) = jugada;
        await tester.tap(find.byKey(Key('anchor-option-$ancla')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(Key('candidate-cell-$fila-$columna')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('confirm-move-button')));
        await tester.pumpAndSettle();
      }

      expect(tablero.estaLleno, isTrue);
      expect(tablero.extraerDatos(), planificado.extraerDatos());
      expect(tablero.puntuacionTotal, 54);
      expect(sonido.reproducciones, 1);
      expect(dados.historial.lanzamientos, hasLength(jugadas.length));
      expect(
        dados.historial.lanzamientos
            .where((l) => l.accionRealizada == 'Movimiento inválido'),
        hasLength(turnosPasados),
      );
      expect(
        textoEn('game-over-dialog', 'Has puntuado 54 puntos'),
        findsOneWidget,
      );

      await tester.tap(find.text('Aceptar'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('roll-dice-button')), findsNothing);
      expect(find.byKey(const Key('new-game-button')), findsOneWidget);
    });
  });
}
