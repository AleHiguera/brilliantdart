// Prueba de widgets: el apartado «Zonas completadas» y el historial de dados
// que se despliega y se oculta.

import 'package:brilliantdart/historial_dados.dart';
import 'package:brilliantdart/mapa_uno.dart';
import 'package:brilliantdart/nombres_zonas.dart';
import 'package:brilliantdart/puntuacion_multijugador.dart';
import 'package:brilliantdart/registro_zonas.dart';
import 'package:brilliant_mobile/historial_dados_view.dart';
import 'package:brilliant_mobile/main.dart';
import 'package:brilliant_mobile/panel_registro_zonas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

Future<void> mostrarRegistro(
  WidgetTester tester,
  Map<int, Map<String, int>> rondas, {
  String usuario = 'ana',
}) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: PanelRegistroZonas(
          entradas: RegistroZonas(
            PuntuacionMultijugador(mapaUno, rondas),
          ).entradas,
          nombres: NombresZonas(mapaUno),
          usuario: usuario,
        ),
      ),
    ),
  ),
);

void main() {
  final nombres = NombresZonas(mapaUno);

  group('Widgets: zonas completadas', () {
    testWidgets('Sin zonas llenas lo dice', (tester) async {
      await mostrarRegistro(tester, {});

      expect(find.text('Zonas completadas'), findsOneWidget);
      expect(find.byKey(const Key('registro-zonas-vacio')), findsOneWidget);
    });

    testWidgets('Dice quién llenó qué zona, en qué ronda y su lugar', (
      tester,
    ) async {
      await mostrarRegistro(tester, {
        1: {'luis': 1, 'eva': 2},
      });

      expect(find.text('@luis llenó ${nombres.de(1)}'), findsOneWidget);
      expect(find.text('@eva llenó ${nombres.de(1)}'), findsOneWidget);
      expect(textoEn('registro-1-luis', 'Ronda 1'), findsOneWidget);
      expect(textoEn('registro-1-eva', 'Ronda 2'), findsOneWidget);
      expect(textoEn('registro-1-luis', '1.º · 8 pts'), findsOneWidget);
      expect(textoEn('registro-1-eva', '2.º · 6 pts'), findsOneWidget);
    });

    testWidgets('Primero, segundo y tercero; el cuarto ya sin puntos', (
      tester,
    ) async {
      await mostrarRegistro(tester, {
        1: {'ana': 1, 'luis': 2, 'eva': 3, 'leo': 4},
      });

      expect(textoEn('registro-1-ana', '1.º · 8 pts'), findsOneWidget);
      expect(textoEn('registro-1-luis', '2.º · 6 pts'), findsOneWidget);
      expect(textoEn('registro-1-eva', '3.er · 4 pts'), findsOneWidget);
      expect(textoEn('registro-1-leo', '4.º · sin puntos'), findsOneWidget);
    });

    testWidgets('Lo más reciente va arriba', (tester) async {
      await mostrarRegistro(tester, {
        1: {'luis': 1},
        3: {'eva': 3},
      });

      expect(
        tester.getTopLeft(find.byKey(const Key('registro-3-eva'))).dy,
        lessThan(
          tester.getTopLeft(find.byKey(const Key('registro-1-luis'))).dy,
        ),
      );
    });

    testWidgets('Las propias se marcan con (tú)', (tester) async {
      await mostrarRegistro(tester, {
        1: {'ana': 1},
      });

      expect(find.text('@ana (tú) llenó ${nombres.de(1)}'), findsOneWidget);
    });

    testWidgets('Cabe en un celular chico', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await mostrarRegistro(tester, {
        for (var zona = 1; zona <= 9; zona++)
          zona: {'jugador_con_nombre_largo': zona, 'luis': zona + 1},
      });

      expect(tester.takeException(), isNull);
    });
  });

  group('Widgets: historial de dados plegable', () {
    Future<void> tablero(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TableroPage(
            dados: DadosFijos(const [(1, 3), (2, 4)]),
            sonidoDados: SonidoFalso(),
            sonidoVictoria: SonidoFalso(),
            sonidoAplausos: SonidoFalso(),
            sonidoTristeza: SonidoFalso(),
            tablero: tableroCasiLleno(),
          ),
        ),
      );
      await tester.tap(find.text('Comenzar'));
      await tester.pumpAndSettle();
    }

    Future<void> tocarHistorial(WidgetTester tester) async {
      await tester.ensureVisible(find.byKey(const Key('dice-history-toggle')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('dice-history-toggle')));
      await tester.pumpAndSettle();
    }

    testWidgets('En el tablero empieza cerrado', (tester) async {
      await tablero(tester);
      await lanzarDados(tester);

      expect(find.text('Historial'), findsOneWidget);
      expect(find.byKey(const Key('dice-history-list')), findsNothing);
      expect(find.byKey(const Key('dice-history-row-1')), findsNothing);
    });

    testWidgets('Cerrado igual dice cuántos lanzamientos hay', (tester) async {
      await tablero(tester);
      await lanzarDados(tester);

      expect(textoEn('dice-history-toggle', '1'), findsOneWidget);
    });

    testWidgets('Un clic lo despliega y otro lo oculta', (tester) async {
      await tablero(tester);
      await lanzarDados(tester);

      await tocarHistorial(tester);
      expect(find.byKey(const Key('dice-history-row-1')), findsOneWidget);

      await tocarHistorial(tester);
      expect(find.byKey(const Key('dice-history-row-1')), findsNothing);
    });

    testWidgets('La flecha indica si está abierto o cerrado', (tester) async {
      await tablero(tester);
      Icon flecha() =>
          tester.widget<Icon>(find.byKey(const Key('dice-history-chevron')));

      expect(flecha().icon, Icons.expand_more);
      await tocarHistorial(tester);
      expect(flecha().icon, Icons.expand_less);
    });

    testWidgets('Fuera del tablero se puede mostrar abierto desde el inicio', (
      tester,
    ) async {
      final historial = HistorialDados()..registrarLanzamiento(1, 3);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: HistorialDadosView(historial: historial)),
        ),
      );

      expect(find.byKey(const Key('dice-history-row-1')), findsOneWidget);
    });
  });
}
