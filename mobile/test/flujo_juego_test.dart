import 'dart:math';

import 'package:brilliantdart/bloc_valores_iniciales.dart';
import 'package:brilliantdart/historial_dados.dart';
import 'package:brilliantdart/mapa_uno.dart';
import 'package:brilliantdart/validador_anclas.dart';
import 'package:brilliant_mobile/historial_dados_view.dart';
import 'package:brilliant_mobile/main.dart';
import 'package:brilliant_mobile/panel_lanzamiento_dados.dart';
import 'package:brilliant_mobile/paneles_juego.dart';
import 'package:brilliant_mobile/sonidos.dart';
import 'package:brilliant_mobile/tabla_puntuacion.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        sonidoVictoria: SonidoFalso(),
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
        matching: find.byWidgetPredicate((widget) =>
            widget.key is ValueKey<String> &&
            (widget.key! as ValueKey<String>)
                .value
                .startsWith('map-preview-cell-')),
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
      expect(
        find.descendant(
          of: find.byKey(const Key('movement-summary')),
          matching: find.text('Ancla: 1'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('El resumen del movimiento nunca muestra coordenadas',
        (tester) async {
      await abrirTableroCasiLleno(tester, [(1, 3)]);
      await lanzarDados(tester);
      await tester.tap(find.byKey(const Key('anchor-option-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('candidate-cell-4-7')));
      await tester.pumpAndSettle();

      final textos = tester
          .widgetList<Text>(find.descendant(
            of: find.byKey(const Key('movement-summary')),
            matching: find.byType(Text),
          ))
          .map((texto) => texto.data ?? '')
          .toList();
      expect(textos, isNotEmpty);
      for (final texto in textos) {
        expect(texto, isNot(contains('Posición')));
        expect(texto, isNot(matches(RegExp(r'\(\d+, \d+\)'))));
      }
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
      comprobarFilaHistorial(tester, 1, (1, 3), accion: '1 ancla → coloca 3');
    });
  });

  group('Diseño de las pantallas', () {
    double opacidadNumero(WidgetTester tester, int numero) => tester
        .widget<AnimatedOpacity>(find.byKey(Key('setup-number-$numero')))
        .opacity;

    Future<void> elegirInicial(
      WidgetTester tester,
      String celda,
      int numero,
    ) async {
      await tester.tap(find.byKey(Key('initial-cell-$celda')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('initial-value-$numero')));
      await tester.pumpAndSettle();
    }

    testWidgets('La selección de mapa explica cómo se juega', (tester) async {
      await tester.pumpWidget(const BrilliantApp());
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('how-to-play')),
        200,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );

      expect(find.byKey(const Key('how-to-play')), findsOneWidget);
      expect(find.text('Cómo se juega'), findsOneWidget);
      expect(find.text('Disponible'), findsOneWidget);
      expect(find.text('Muy pronto podrás jugarlo.'), findsNWidgets(2));
      final textosMapa1 = tester
          .widgetList<Text>(find.descendant(
            of: find.byKey(const Key('map-choice-1')),
            matching: find.byType(Text),
          ))
          .map((texto) => texto.data)
          .toList();
      expect(textosMapa1, ['Mapa 1', 'Disponible']);
    });

    testWidgets('Los números usados se encienden en la preparación',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: TableroPage()));

      for (var numero = 1; numero <= 6; numero++) {
        expect(opacidadNumero(tester, numero), lessThan(1));
      }

      await elegirInicial(tester, '1-3', 4);

      expect(opacidadNumero(tester, 4), 1);
      expect(opacidadNumero(tester, 1), lessThan(1));
      expect(find.text('1/6'), findsOneWidget);
      expect(
        find.text('Toca las celdas con + y usa cada número una vez.'),
        findsOneWidget,
      );
    });

    testWidgets('Con los seis números aparece el mensaje de listo',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: TableroPage()));

      const celdas = ['1-3', '2-6', '4-2', '4-5', '6-3', '7-5'];
      for (var i = 0; i < celdas.length; i++) {
        await elegirInicial(tester, celdas[i], i + 1);
      }

      expect(find.text('¡Listo! Ya puedes comenzar la partida.'), findsOneWidget);
      for (var numero = 1; numero <= 6; numero++) {
        expect(opacidadNumero(tester, numero), 1);
      }
    });

    testWidgets('El diálogo marca el número actual y los que están en uso',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: TableroPage()));
      await elegirInicial(tester, '1-3', 2);
      await elegirInicial(tester, '2-6', 5);

      await tester.tap(find.byKey(const Key('initial-cell-1-3')));
      await tester.pumpAndSettle();

      expect(find.text('Elige un número'), findsOneWidget);
      Finder etiqueta(int numero, String texto) => find.descendant(
            of: find.byKey(Key('initial-value-$numero')),
            matching: find.text(texto),
          );
      expect(etiqueta(2, 'Actual'), findsOneWidget);
      expect(etiqueta(5, 'En uso'), findsOneWidget);
      expect(etiqueta(1, 'Libre'), findsOneWidget);
      expect(find.byType(DadoMini), findsWidgets);
    });

    testWidgets('El número de turno avanza al terminar cada turno',
        (tester) async {
      await abrirTableroCasiLleno(tester, [(4, 6), (1, 3)]);
      Finder turno(int n) => find.text('Turno $n');

      expect(turno(1), findsOneWidget);
      await lanzarDados(tester);
      expect(turno(1), findsOneWidget);

      await tester.tap(find.byKey(const Key('pass-turn-button')));
      await tester.pumpAndSettle();
      expect(turno(2), findsOneWidget);
    });

    testWidgets('Cada opción de ancla muestra sus dos dados', (tester) async {
      await abrirTableroCasiLleno(tester, [(1, 3)]);
      await lanzarDados(tester);

      for (final (ancla, numero) in [(1, 3), (3, 1)]) {
        final dados = tester
            .widgetList<DadoMini>(find.descendant(
              of: find.byKey(Key('anchor-option-$ancla')),
              matching: find.byType(DadoMini),
            ))
            .map((dado) => dado.valor)
            .toList();
        expect(dados, [ancla, numero]);
      }
    });

    testWidgets('En pantalla ancha el turno va a la derecha del tablero',
        (tester) async {
      tester.view.physicalSize = const Size(1000, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await abrirTableroCasiLleno(tester, [(1, 3)]);

      final tablero = tester.getRect(find.byType(GridView).first);
      final turno = tester.getRect(find.byKey(const Key('turn-panel')));
      final puntuacion = tester.getRect(find.byKey(const Key('score-table')));

      expect(turno.left, greaterThanOrEqualTo(tablero.right));
      expect(puntuacion.top, greaterThan(turno.bottom));
      expect(tablero.height, greaterThan(700 * 0.8));
    });

    testWidgets('En un celular el tablero no se encoge al elegir movimiento',
        (tester) async {
      tester.view.physicalSize = const Size(400, 860);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await abrirTableroCasiLleno(tester, [(1, 3)]);
      final antes = tester.getRect(find.byType(GridView).first);

      await lanzarDados(tester);
      await tester.tap(find.byKey(const Key('anchor-option-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('candidate-cell-4-7')));
      await tester.pumpAndSettle();

      final despues = tester.getRect(find.byType(GridView).first);
      expect(despues.height, greaterThanOrEqualTo(antes.height * 0.95));
      expect(despues.height, greaterThan(860 * 0.4));

      final confirmar =
          tester.getRect(find.byKey(const Key('confirm-move-button')));
      expect(confirmar.bottom, lessThanOrEqualTo(860));
      expect(confirmar.top, greaterThan(despues.bottom));
    });

    testWidgets('La tarjeta de fin queda entera a la vista en un celular',
        (tester) async {
      tester.view.physicalSize = const Size(400, 860);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await abrirTableroCasiLleno(tester, [(1, 3)]);
      await jugarUltimaCelda(tester);
      await tester.tap(find.text('Aceptar'));
      await tester.pumpAndSettle();

      final tablero = tester.getRect(find.byType(GridView).first);
      final fin = tester.getRect(find.byKey(const Key('game-finished-panel')));
      expect(fin.top, greaterThanOrEqualTo(tablero.bottom));
      expect(fin.bottom, lessThanOrEqualTo(860));
      expect(find.byKey(const Key('perfect-score')), findsOneWidget);
    });

    testWidgets('Sin puntuación perfecta no aparece el mensaje especial',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PanelFinPartida(puntos: 40, onNuevaPartida: () {}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Has puntuado 40 puntos'), findsOneWidget);
      expect(find.byKey(const Key('perfect-score')), findsNothing);
    });
  });

  group('Diseño de las tablas', () {
    Color? fondoFila(WidgetTester tester, String color) =>
        (tester.widget<AnimatedContainer>(find.byKey(Key('score-row-$color')))
                .decoration as BoxDecoration?)
            ?.color;

    double? avance(WidgetTester tester) => tester
        .widget<LinearProgressIndicator>(
            find.byKey(const Key('score-progress')))
        .value;

    testWidgets('La barra de progreso va de 0 a 54 puntos', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TablaPuntuacion(tablero: MapaUno.crearTablero()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(avance(tester), 0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TablaPuntuacion(tablero: tableroCasiLleno())),
        ),
      );
      await tester.pumpAndSettle();
      expect(avance(tester), closeTo(50 / 54, 0.001));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TablaPuntuacion(tablero: tableroCompleto())),
        ),
      );
      await tester.pumpAndSettle();
      expect(avance(tester), 1);
    });

    testWidgets('Solo se tiñen los colores con todas sus zonas completas',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TablaPuntuacion(tablero: tableroCasiLleno())),
        ),
      );
      await tester.pumpAndSettle();

      expect(fondoFila(tester, 'verde'), Colors.white);
      for (final color in ['azul', 'rojo', 'morado', 'amarillo']) {
        expect(fondoFila(tester, color), isNot(Colors.white), reason: color);
      }
    });

    testWidgets('El lanzamiento más reciente va arriba y resaltado',
        (tester) async {
      final historial = HistorialDados()
        ..registrarLanzamiento(1, 2)
        ..registrarLanzamiento(3, 4)
        ..registrarLanzamiento(5, 6);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HistorialDadosView(historial: historial, maxAlturaFilas: 300),
          ),
        ),
      );

      Color bordeFila(int numero) => (tester
              .widget<Container>(find.byKey(Key('dice-history-row-$numero')))
              .decoration as BoxDecoration)
          .border!
          .top
          .color;
      double alturaFila(int numero) =>
          tester.getTopLeft(find.byKey(Key('dice-history-row-$numero'))).dy;

      expect(alturaFila(3), lessThan(alturaFila(2)));
      expect(alturaFila(2), lessThan(alturaFila(1)));
      expect(bordeFila(3), Colors.black);
      expect(bordeFila(2), Colors.transparent);
      expect(bordeFila(1), Colors.transparent);
      expect(
        tester.widget<Text>(find.byKey(const Key('dice-history-count'))).data,
        '3',
      );
    });

    testWidgets('Cada tipo de acción tiene su propia etiqueta', (tester) async {
      final historial = HistorialDados()
        ..registrarLanzamiento(1, 2)
        ..registrarLanzamiento(3, 4)
        ..registrarLanzamiento(5, 6)
        ..registrarLanzamiento(6, 6);
      historial
        ..registrarAccion(1, '1 ancla → coloca 2')
        ..registrarAccion(2, 'Movimiento inválido')
        ..registrarAccion(3, 'Turno pasado');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HistorialDadosView(historial: historial, maxAlturaFilas: 400),
          ),
        ),
      );

      const iconos = {
        1: Icons.check,
        2: Icons.block,
        3: Icons.skip_next,
        4: Icons.hourglass_empty,
      };
      for (final MapEntry(key: numero, value: icono) in iconos.entries) {
        expect(
          find.descendant(
            of: find.byKey(Key('dice-history-action-$numero')),
            matching: find.byIcon(icono),
          ),
          findsOneWidget,
          reason: 'Lanzamiento $numero',
        );
      }
      comprobarFilaHistorial(tester, 4, (6, 6));
    });

    testWidgets('Los dados del historial se dibujan con puntos',
        (tester) async {
      final historial = HistorialDados()..registrarLanzamiento(3, 5);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: HistorialDadosView(historial: historial)),
        ),
      );

      expect(find.byType(DadoMini), findsNWidgets(2));
      expect(
        find.descendant(
          of: find.byKey(const Key('dice-history-row-1')),
          matching: find.text('3'),
        ),
        findsNothing,
      );
      comprobarFilaHistorial(tester, 1, (3, 5));
    });

    testWidgets('En un celular las tablas caben con un historial largo',
        (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final dados = DadosFijos([(1, 3)]);
      for (var i = 0; i < 8; i++) {
        dados.historial
          ..registrarLanzamiento(i % 6 + 1, 6 - i % 6)
          ..registrarAccion(i + 1, 'Movimiento inválido');
      }
      await tester.pumpWidget(
        MaterialApp(
          home: TableroPage(
            dados: dados,
            tablero: tableroCasiLleno(),
            sonidoVictoria: SonidoFalso(),
            sonidoDados: SonidoFalso(),
          ),
        ),
      );
      await tester.tap(find.text('Comenzar'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('dice-history')), findsOneWidget);
      expect(find.byKey(const Key('score-table')), findsOneWidget);
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
      final sonido = SonidoFalso();
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
