import 'dart:math';
import 'package:brilliantdart/bloc_valores_iniciales.dart';
import 'package:brilliantdart/mapa_uno.dart';
import 'package:brilliantdart/validador_anclas.dart';
import 'package:brilliant_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  group('Widgets: partida completa', () {
    testWidgets('Se juega una partida entera solo con los botones', (
      tester,
    ) async {
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
            for (final movimiento in validador.obtenerMovimientosPosibles(
              opcion,
            ))
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
      expect(
        planificado.estaLleno,
        isTrue,
        reason: 'La partida planeada debe poder terminarse',
      );

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
        dados.historial.lanzamientos.where(
          (l) => l.accionRealizada == 'Movimiento inválido',
        ),
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
