import 'dart:math';

import 'package:brilliantdart/bloc_valores_iniciales.dart';
import 'package:brilliantdart/dados.dart';
import 'package:brilliantdart/mapa_uno.dart';
import 'package:brilliantdart/tablero.dart';
import 'package:brilliantdart/tipoo.dart';
import 'package:brilliant_mobile/historial_dados_view.dart';
import 'package:brilliant_mobile/main.dart';
import 'package:brilliant_mobile/sonidos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mapa uno con todas sus zonas completadas de forma válida excepto la celda
/// verde (4, 7), que queda vacía para la última jugada.
Tablero tableroCasiLleno() {
  final tablero = mapaUno.crearTablero();
  final bloc = BlocValoresIniciales(
    tablero,
    celdasIniciales: mapaUno.celdasIniciales,
  );
  for (var i = 0; i < mapaUno.celdasIniciales.length; i++) {
    final (fila, columna) = mapaUno.celdasIniciales[i];
    bloc.colocarValorInicial(fila, columna, i + 1);
  }

  for (final region in tablero.regiones) {
    final existentes = region.obtenerValores();
    final vacias = region.coordenadas
        .where(
          (celda) => celda.valor == null && !(celda.x == 3 && celda.y == 6),
        )
        .toList();

    for (var indice = 0; indice < vacias.length; indice++) {
      final numero = switch (region.tipo.tipo) {
        TipoZona.azul => existentes.isEmpty ? 2 : existentes.first,
        TipoZona.rojo || TipoZona.amarillo => [
          1,
          2,
          3,
          4,
          5,
          6,
        ].where((valor) => !existentes.contains(valor)).elementAt(indice),
        TipoZona.verde => 1,
        TipoZona.morado =>
          existentes.isEmpty
              ? (indice == 0 ? 2 : 5)
              : (indice == 0
                    ? (existentes.first == 1 ? 2 : 1)
                    : existentes.first),
      };
      tablero.colocarDato(vacias[indice].x, vacias[indice].y, numero);
    }
  }

  return tablero;
}

/// Lanza (1, 3), usa el 1 como ancla y coloca el 3 en la celda vacía (4, 7).
Future<void> jugarUltimaCelda(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('roll-dice-button')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1300));
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(const Key('anchor-option-1')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('candidate-cell-4-7')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('confirm-move-button')));
  await tester.pumpAndSettle();
}

class SonidoFalso extends Sonido {
  int reproducciones = 0;
  int cierres = 0;

  @override
  Future<void> reproducir() async => reproducciones++;

  @override
  void dispose() => cierres++;
}

class DadosFijos extends Dados {
  DadosFijos(this.resultados) : super(random: Random(1));

  final List<(int, int)> resultados;
  int _lanzamientoActual = 0;

  @override
  (int, int) lanzar() {
    final resultado = resultados[_lanzamientoActual++];
    historial.registrarLanzamiento(resultado.$1, resultado.$2);
    return resultado;
  }
}

/// Mapa uno con todas sus zonas completadas: vale 54 puntos.
Tablero tableroCompleto() => tableroCasiLleno()..colocarDato(3, 6, 3);

/// Comprueba una fila del historial: sus dos dados y su etiqueta de acción
/// ("Pendiente" cuando todavía no se decidió el turno).
void comprobarFilaHistorial(
  WidgetTester tester,
  int numero,
  (int, int) dados, {
  String accion = 'Pendiente',
}) {
  Finder textoEnClave(String clave, String texto) => find.descendant(
    of: find.byKey(Key(clave)),
    matching: find.text(texto),
    matchRoot: true,
  );

  expect(find.byKey(Key('dice-history-row-$numero')), findsOneWidget);
  expect(
    textoEnClave('dice-history-number-$numero', '$numero'),
    findsOneWidget,
  );
  expect(
    tester.widget<DadoMini>(find.byKey(Key('dice-history-die1-$numero'))).valor,
    dados.$1,
  );
  expect(
    tester.widget<DadoMini>(find.byKey(Key('dice-history-die2-$numero'))).valor,
    dados.$2,
  );
  expect(textoEnClave('dice-history-action-$numero', accion), findsOneWidget);
}

/// Toca "Lanzar dados" y espera a que termine la animación.
Future<void> lanzarDados(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('roll-dice-button')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1300));
  await tester.pumpAndSettle();
}

/// Abre el tablero casi lleno con dados fijos y pulsa Comenzar.
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
        sonidoDados: SonidoFalso(),
      ),
    ),
  );
  await tester.tap(find.text('Comenzar'));
  await tester.pump();
}

/// Busca un texto dentro del widget con la clave indicada.
Finder textoEn(String clave, String texto) =>
    find.descendant(of: find.byKey(Key(clave)), matching: find.text(texto));
