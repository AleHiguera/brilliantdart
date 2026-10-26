import 'package:brilliantdart/mapa.dart';
import 'package:brilliantdart/mapa_cuatro.dart';
import 'package:brilliantdart/mapa_dos.dart';
import 'package:brilliantdart/mapa_tres.dart';
import 'package:brilliantdart/mapa_uno.dart';
import 'package:brilliant_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

/// Tamaños de pantalla de celulares comunes (ancho × alto en puntos).
const celulares = {
  'celular chico (320×568)': Size(320, 568),
  'celular Android común (360×740)': Size(360, 740),
  'iPhone (390×844)': Size(390, 844),
  'celular grande (430×932)': Size(430, 932),
};

/// Lo mínimo que debe medir cada celda para tocarla con el dedo. En los
/// celulares actuales es 44 o más (Google recomienda 48); en el más chico,
/// que es muy bajito, el tablero se achica a unos 33.
double celdaMinima(Size pantalla) => pantalla.width >= 360 ? 44 : 32;

const mapas = <Mapa>[mapaUno, mapaDos, mapaTres, mapaCuatro];

/// Números iniciales válidos para cada mapa (el Mapa 4 tiene naranjas).
List<int> valoresIniciales(Mapa mapa) =>
    mapa == mapaCuatro ? const [6, 2, 3, 4, 5, 1] : const [1, 2, 3, 4, 5, 6];

void usarPantalla(WidgetTester tester, Size tamano) {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Nada se sale de la pantalla por los lados.
void comprobarAncho(WidgetTester tester, Finder finder, Size pantalla) {
  final rect = tester.getRect(finder);
  expect(rect.left, greaterThanOrEqualTo(0));
  expect(rect.right, lessThanOrEqualTo(pantalla.width));
}

void main() {
  // Si algo no cabe, Flutter marca un error de "overflow" y la prueba falla.
  for (final MapEntry(key: nombre, value: pantalla) in celulares.entries) {
    group('Widgets: en un $nombre', () {
      testWidgets('La selección muestra los 4 mapas al bajar', (tester) async {
        usarPantalla(tester, pantalla);
        await tester.pumpWidget(const BrilliantApp());
        await tester.pumpAndSettle();

        for (var numero = 1; numero <= 4; numero++) {
          final tarjeta = find.byKey(Key('map-choice-$numero'));
          await tester.ensureVisible(tarjeta);
          await tester.pumpAndSettle();
          comprobarAncho(tester, tarjeta, pantalla);
        }
      });

      for (final mapa in mapas) {
        testWidgets('Mapa ${mapa.numero}: el tablero cabe a lo ancho', (
          tester,
        ) async {
          usarPantalla(tester, pantalla);
          await tester.pumpWidget(
            MaterialApp(
              home: TableroPage(
                mapa: mapa,
                sonidoVictoria: SonidoFalso(),
                sonidoDados: SonidoFalso(),
              ),
            ),
          );
          await tester.pumpAndSettle();

          final tablero = find.byType(GridView).first;
          comprobarAncho(tester, tablero, pantalla);
          final rect = tester.getRect(tablero);
          // Las celdas se pueden tocar con el dedo.
          expect(rect.width / 7, greaterThanOrEqualTo(celdaMinima(pantalla)));
          expect(rect.bottom, lessThanOrEqualTo(pantalla.height));
        });

        testWidgets('Mapa ${mapa.numero}: el selector de números cabe', (
          tester,
        ) async {
          usarPantalla(tester, pantalla);
          await tester.pumpWidget(
            MaterialApp(
              home: TableroPage(
                mapa: mapa,
                sonidoVictoria: SonidoFalso(),
                sonidoDados: SonidoFalso(),
              ),
            ),
          );
          final (fila, columna) = mapa.celdasIniciales.first;

          await tester.tap(find.byKey(Key('initial-cell-$fila-$columna')));
          await tester.pumpAndSettle();

          final dialogo = find.byType(SimpleDialog);
          comprobarAncho(tester, dialogo, pantalla);
          for (var numero = 1; numero <= 6; numero++) {
            final opcion = find.byKey(Key('initial-value-$numero'));
            comprobarAncho(tester, opcion, pantalla);
            expect(
              tester.getRect(opcion).bottom,
              lessThanOrEqualTo(pantalla.height),
            );
          }
        });

        testWidgets('Mapa ${mapa.numero}: se prepara y empieza a jugar', (
          tester,
        ) async {
          usarPantalla(tester, pantalla);
          await tester.pumpWidget(
            MaterialApp(
              home: TableroPage(
                mapa: mapa,
                dados: DadosFijos([(1, 2)]),
                sonidoVictoria: SonidoFalso(),
                sonidoDados: SonidoFalso(),
              ),
            ),
          );
          final valores = valoresIniciales(mapa);

          for (var i = 0; i < 6; i++) {
            final (fila, columna) = mapa.celdasIniciales[i];
            await tester.tap(find.byKey(Key('initial-cell-$fila-$columna')));
            await tester.pumpAndSettle();
            await tester.tap(find.byKey(Key('initial-value-${valores[i]}')));
            await tester.pumpAndSettle();
          }
          final comenzar = find.text('Comenzar');
          await tester.ensureVisible(comenzar);
          await tester.pumpAndSettle();
          await tester.tap(comenzar);
          await tester.pumpAndSettle();

          final lanzar = find.byKey(const Key('roll-dice-button'));
          await tester.ensureVisible(lanzar);
          await tester.pumpAndSettle();
          comprobarAncho(tester, lanzar, pantalla);
          await lanzarDados(tester);
          comprobarAncho(tester, find.byType(GridView).first, pantalla);
        });
      }
    });
  }
}
