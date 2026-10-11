import 'dart:math';

import 'package:brilliantdart/bloc_valores_iniciales.dart';
import 'package:brilliantdart/historial_dados.dart';
import 'package:brilliantdart/mapa_uno.dart';
import 'package:brilliantdart/validador_anclas.dart';
import 'package:brilliant_mobile/historial_dados_view.dart';
import 'package:brilliant_mobile/main.dart';
import 'package:brilliant_mobile/panel_lanzamiento_dados.dart';
import 'package:brilliant_mobile/tabla_puntuacion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

Future<void> lanzarDados(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('roll-dice-button')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1300));
  await tester.pumpAndSettle();
}

Future<void> abrirTableroCasiLleno(
  WidgetTester tester,
  List<(int, int)> lanzamientos,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: TableroPage(
        dados: DadosFijos(lanzamientos),
        tablero: tableroCasiLleno(),
        sonidoVictoria: SonidoVictoriaFalso(),
      ),
    ),
  );
  await tester.tap(find.text('Comenzar'));
  await tester.pump();
}

Finder textoEn(String clave, String texto) => find.descendant(
      of: find.byKey(Key(clave)),
      matching: find.text(texto),
    );

void main() {
  group('Selección de mapa', () {
    testWidgets('Los mapas bloqueados no abren ningún tablero', (tester) async {
      await tester.pumpWidget(const BrilliantApp());

      await tester.tap(find.byKey(const Key('map-choice-2')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('map-choice-3')));
      await tester.pumpAndSettle();

      expect(find.text('Elige tu mapa'), findsOneWidget);
      expect(find.byType(TableroPage), findsNothing);
    });

    testWidgets('La vista previa del mapa 1 tiene las 49 celdas',
        (tester) async {
      await tester.pumpWidget(const BrilliantApp());

      final vistaPrevia = find.descendant(
        of: find.byKey(const Key('map-choice-1')),
        matching: find.byType(DecoratedBox),
      );
      expect(vistaPrevia, findsNWidgets(49));
    });
  });

  group('Preparación de la partida', () {
    testWidgets('Antes de comenzar solo se pueden tocar las celdas iniciales',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: TableroPage()));

      await tester.tap(find.byKey(const Key('board-cell-1-1')));
      await tester.pumpAndSettle();
      expect(find.byType(SimpleDialog), findsNothing);

      await tester.tap(find.byKey(const Key('initial-cell-1-3')));
      await tester.pumpAndSettle();
      expect(find.byType(SimpleDialog), findsOneWidget);
    });

    testWidgets('Las seis celdas iniciales muestran un +', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: TableroPage()));

      for (final (fila, columna) in BlocValoresIniciales.celdasIniciales) {
        expect(textoEn('initial-cell-$fila-$columna', '+'), findsOneWidget);
      }
      expect(find.text('+'), findsNWidgets(6));
    });

    testWidgets('Vaciar una celda inicial actualiza el progreso',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: TableroPage()));

      await tester.tap(find.byKey(const Key('initial-cell-1-3')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('initial-value-4')));
      await tester.pumpAndSettle();
      expect(find.text('1/6'), findsOneWidget);
      expect(textoEn('initial-cell-1-3', '4'), findsOneWidget);

      await tester.tap(find.byKey(const Key('initial-cell-1-3')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('clear-initial-value')));
      await tester.pumpAndSettle();
      expect(find.text('0/6'), findsOneWidget);
      expect(textoEn('initial-cell-1-3', '+'), findsOneWidget);
    });

    testWidgets('Comenzar sigue desactivado con solo cinco números',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: TableroPage()));

      for (var i = 0; i < 5; i++) {
        final (fila, columna) = BlocValoresIniciales.celdasIniciales[i];
        await tester.tap(find.byKey(Key('initial-cell-$fila-$columna')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(Key('initial-value-${i + 1}')));
        await tester.pumpAndSettle();
      }

      expect(find.text('5/6'), findsOneWidget);
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull,
      );
      expect(find.byKey(const Key('roll-dice-button')), findsNothing);
    });
  });

  group('Turno de juego', () {
    testWidgets('Una opción cuyo número no está en el tablero sale bloqueada',
        (tester) async {
      final tablero = MapaUno.crearTablero()..colocarDato(3, 3, 2);
      final opcionesElegidas = <OpcionAncla?>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PanelLanzamientoDados(
                dados: DadosFijos([(2, 5)]),
                validadorAnclas: ValidadorAnclas(tablero),
                onOpcionAnclaChanged: opcionesElegidas.add,
                onPasarTurno: () {},
                onHistorialActualizado: () {},
                partidaFinalizada: false,
              ),
            ),
          ),
        ),
      );
      await lanzarDados(tester);
      opcionesElegidas.clear();

      expect(textoEn('anchor-option-5', 'No disponible'), findsOneWidget);
      expect(textoEn('anchor-option-2', 'No disponible'), findsNothing);

      await tester.tap(find.byKey(const Key('anchor-option-5')));
      await tester.pump();
      expect(opcionesElegidas, isEmpty);

      await tester.tap(find.byKey(const Key('anchor-option-2')));
      await tester.pump();
      expect(opcionesElegidas.single?.ancla, 2);
      expect(opcionesElegidas.single?.numeroAColocar, 5);
    });

    testWidgets('Con dados dobles solo aparece una opción', (tester) async {
      await abrirTableroCasiLleno(tester, [(1, 1)]);
      await lanzarDados(tester);

      expect(find.byKey(const Key('anchor-option-1')), findsOneWidget);
      expect(find.text('Ancla: 1  ·  Colocar: 1'), findsOneWidget);
    });

    testWidgets('Avisa cuando la opción elegida no tiene posiciones válidas',
        (tester) async {
      await abrirTableroCasiLleno(tester, [(1, 4)]);
      await lanzarDados(tester);

      await tester.tap(find.byKey(const Key('anchor-option-4')));
      await tester.pumpAndSettle();

      expect(
        find.text('No hay posiciones válidas para esta opción.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('candidate-cell-4-7')), findsNothing);

      await tester.tap(find.byKey(const Key('anchor-option-1')));
      await tester.pumpAndSettle();

      expect(find.text('No hay posiciones válidas para esta opción.'),
          findsNothing);
      expect(find.byKey(const Key('candidate-cell-4-7')), findsOneWidget);
    });

    testWidgets('Pide tocar una celda resaltada y no acepta otras',
        (tester) async {
      await abrirTableroCasiLleno(tester, [(1, 3)]);
      await lanzarDados(tester);
      await tester.tap(find.byKey(const Key('anchor-option-1')));
      await tester.pumpAndSettle();

      expect(
        find.text('Toca una posición resaltada del tablero.'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('board-cell-1-2')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('movement-summary')), findsNothing);

      await tester.tap(find.byKey(const Key('candidate-cell-4-7')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('movement-summary')), findsOneWidget);
      expect(find.text('Número a colocar: 3'), findsOneWidget);
      expect(find.text('Posición: (4, 7)'), findsOneWidget);
    });

    testWidgets('No se puede volver a lanzar sin decidir el turno',
        (tester) async {
      final dados = DadosFijos([(1, 3), (2, 2)]);
      await tester.pumpWidget(
        MaterialApp(
          home: TableroPage(dados: dados, tablero: tableroCasiLleno()),
        ),
      );
      await tester.tap(find.text('Comenzar'));
      await tester.pump();
      await lanzarDados(tester);

      await tester.tap(find.byKey(const Key('roll-dice-button')));
      await tester.pump(const Duration(milliseconds: 1300));

      expect(dados.historial.lanzamientos, hasLength(1));
    });
  });

  group('Puntuación en pantalla', () {
    testWidgets('Un tablero nuevo muestra 0 puntos', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TablaPuntuacion(tablero: MapaUno.crearTablero()),
          ),
        ),
      );

      expect(find.text('0 pts'), findsOneWidget);
      expect(textoEn('score-row-amarillo', '0/1'), findsOneWidget);
      for (final color in ['morado', 'verde', 'azul', 'rojo']) {
        expect(textoEn('score-row-$color', '0/2'), findsOneWidget);
      }
    });

    testWidgets('Un tablero completo muestra los puntos de cada color',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TablaPuntuacion(tablero: tableroCompleto())),
        ),
      );

      const esperado = {
        'morado': ('2/2', '12'),
        'amarillo': ('1/1', '8'),
        'verde': ('2/2', '8'),
        'azul': ('2/2', '14'),
        'rojo': ('2/2', '12'),
      };
      for (final MapEntry(key: color, value: (hechas, puntos))
          in esperado.entries) {
        expect(textoEn('score-row-$color', hechas), findsOneWidget);
        expect(textoEn('score-row-$color', puntos), findsOneWidget);
      }
      expect(find.text('54 pts'), findsOneWidget);
    });

    testWidgets('La tabla se actualiza al completar una zona jugando',
        (tester) async {
      await abrirTableroCasiLleno(tester, [(1, 3)]);

      expect(find.text('50 pts'), findsOneWidget);
      expect(textoEn('score-row-verde', '1/2'), findsOneWidget);

      await jugarUltimaCelda(tester);
      await tester.tap(find.text('Aceptar'));
      await tester.pumpAndSettle();

      expect(find.text('54 pts'), findsOneWidget);
      expect(textoEn('score-row-verde', '2/2'), findsOneWidget);
      expect(textoEn('board-cell-4-7', '3'), findsOneWidget);
      expect(find.text('Acción: 1 ancla → coloca 3'), findsOneWidget);
    });
  });

  group('Historial y pantallas pequeñas', () {
    testWidgets('Un historial vacío dice Sin lanzamientos', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: HistorialDadosView(historial: HistorialDados())),
        ),
      );

      expect(find.text('Sin lanzamientos'), findsOneWidget);
    });

    testWidgets('En un celular el historial aparece debajo del tablero',
        (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await abrirTableroCasiLleno(tester, [(1, 3)]);

      final tablero = tester.getRect(find.byType(GridView));
      final historial = tester.getRect(find.byKey(const Key('dice-history')));
      expect(historial.top, greaterThanOrEqualTo(tablero.bottom));
      expect(find.byKey(const Key('score-table')), findsOneWidget);

      await jugarUltimaCelda(tester);
      expect(find.byKey(const Key('game-over-dialog')), findsOneWidget);
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
      while (!planificado.estaLleno) {
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

      final tablero = MapaUno.crearTablero();
      final sonido = SonidoVictoriaFalso();
      final dados = DadosFijos(lanzamientos);
      await tester.pumpWidget(
        MaterialApp(
          home: TableroPage(
            dados: dados,
            tablero: tablero,
            sonidoVictoria: sonido,
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
