import 'dart:math';

import 'package:brilliantdart/bloc_valores_iniciales.dart';
import 'package:brilliantdart/dados.dart';
import 'package:brilliantdart/mapa_uno.dart';
import 'package:brilliantdart/tablero.dart';
import 'package:brilliantdart/tipoo.dart';
import 'package:brilliant_mobile/sonido_victoria.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mapa uno con todas sus zonas completadas de forma válida excepto la celda
/// verde (4, 7), que queda vacía para la última jugada.
Tablero tableroCasiLleno() {
  final tablero = MapaUno.crearTablero();
  final bloc = BlocValoresIniciales(tablero);
  for (var i = 0; i < BlocValoresIniciales.celdasIniciales.length; i++) {
    final (fila, columna) = BlocValoresIniciales.celdasIniciales[i];
    bloc.colocarValorInicial(fila, columna, i + 1);
  }

  for (final region in tablero.regiones) {
    final existentes = region.obtenerValores();
    final vacias = region.coordenadas
        .where((celda) => celda.valor == null && !(celda.x == 3 && celda.y == 6))
        .toList();

    for (var indice = 0; indice < vacias.length; indice++) {
      final numero = switch (region.tipo.tipo) {
        TipoZona.azul => existentes.isEmpty ? 2 : existentes.first,
        TipoZona.rojo || TipoZona.amarillo => [1, 2, 3, 4, 5, 6]
            .where((valor) => !existentes.contains(valor))
            .elementAt(indice),
        TipoZona.verde => 1,
        TipoZona.morado => existentes.isEmpty
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

class SonidoVictoriaFalso extends SonidoVictoria {
  int reproducciones = 0;

  @override
  Future<void> reproducir() async => reproducciones++;
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
