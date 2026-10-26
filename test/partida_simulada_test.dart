import 'dart:math';

import 'package:test/test.dart';

import 'package:brilliantdart/bloc_valores_iniciales.dart';
import 'package:brilliantdart/dados.dart';
import 'package:brilliantdart/mapa_uno.dart';
import 'package:brilliantdart/region.dart';
import 'package:brilliantdart/tablero.dart';
import 'package:brilliantdart/tipoo.dart';
import 'package:brilliantdart/validador_anclas.dart';

/// Resultado de jugar una partida completa de forma automática.
class ResultadoPartida {
  ResultadoPartida(this.tablero, this.dados, this.jugadas);

  final Tablero tablero;
  final Dados dados;
  final int jugadas;
}

/// Comprueba que cada zona cumple la regla de su color con los números que
/// tiene ahora (aunque todavía no esté llena).
void verificarReglas(Tablero tablero) {
  for (final zona in tablero.regiones) {
    final valores = zona.obtenerValores();
    final distintos = valores.toSet().length;
    final llena = valores.length == zona.coordenadas.length;
    final motivo = 'Zona ${zona.id} (${zona.tipo.color}): $valores';

    switch (zona.tipo.tipo) {
      case TipoZona.azul || TipoZona.gris:
        expect(distintos, lessThanOrEqualTo(1), reason: motivo);
      case TipoZona.rojo || TipoZona.amarillo:
        expect(distintos, valores.length, reason: motivo);
      case TipoZona.morado:
        expect(distintos, lessThanOrEqualTo(2), reason: motivo);
        if (llena) expect(distintos, 2, reason: motivo);
      case TipoZona.verde:
        break;
      case TipoZona.naranja:
        expect(zona.tipo.validarMovimiento(valores), isTrue, reason: motivo);
    }

    expect(zona.completado, llena, reason: motivo);
  }
}

int puntosEsperados(Tablero tablero) => tablero.regiones
    .where((Region zona) => zona.completado)
    .fold(0, (total, zona) => total + zona.tipo.puntuacion);

/// Juega una partida como lo haría la app: coloca los 6 iniciales, lanza los
/// dados y elige al azar uno de los movimientos válidos. Tras cada jugada
/// verifica todas las reglas.
ResultadoPartida jugarPartida(int semilla) {
  final azar = Random(semilla);
  final tablero = mapaUno.crearTablero();
  final bloc = BlocValoresIniciales(
    tablero,
    celdasIniciales: mapaUno.celdasIniciales,
  );
  final validador = ValidadorAnclas(tablero);
  final dados = Dados(random: Random(semilla * 31 + 7));

  final iniciales = [1, 2, 3, 4, 5, 6]..shuffle(azar);
  for (var i = 0; i < iniciales.length; i++) {
    final (fila, columna) = mapaUno.celdasIniciales[i];
    bloc.colocarValorInicial(fila, columna, iniciales[i]);
  }
  bloc.iniciarPartida();

  var jugadas = 0;
  var turnosSinMovimiento = 0;
  while (!tablero.estaLleno && turnosSinMovimiento < 200) {
    final (dado1, dado2) = dados.lanzar();
    final numeroLanzamiento =
        dados.historial.lanzamientos.last.numeroLanzamiento;
    final posibles = [
      for (final opcion in validador.obtenerOpciones(dado1, dado2))
        for (final movimiento in validador.obtenerMovimientosPosibles(opcion))
          (opcion, movimiento),
    ];

    if (posibles.isEmpty) {
      dados.historial.registrarAccion(numeroLanzamiento, 'Movimiento inválido');
      turnosSinMovimiento++;
      continue;
    }

    turnosSinMovimiento = 0;
    final (opcion, movimiento) = posibles[azar.nextInt(posibles.length)];
    final destino = movimiento.destino;

    expect(destino.valor, isNull);
    expect(movimiento.ancla.valor, opcion.ancla);
    expect(
      (movimiento.ancla.x - destino.x).abs() +
          (movimiento.ancla.y - destino.y).abs(),
      1,
      reason: 'El destino debe estar junto al ancla',
    );
    expect(
      [(dado1, dado2), (dado2, dado1)],
      contains((opcion.ancla, opcion.numeroAColocar)),
      reason: 'El ancla y el número a colocar deben salir de los dados',
    );

    final puntosAntes = tablero.puntuacionTotal;
    tablero.colocarDato(destino.x, destino.y, opcion.numeroAColocar);
    dados.historial.registrarAccion(
      numeroLanzamiento,
      '${opcion.ancla} ancla → coloca ${opcion.numeroAColocar}',
    );
    jugadas++;

    verificarReglas(tablero);
    expect(tablero.puntuacionTotal, puntosEsperados(tablero));
    expect(tablero.puntuacionTotal, greaterThanOrEqualTo(puntosAntes));
    expect(tablero.puntuacionTotal, lessThanOrEqualTo(54));
    expect(bloc.obtenerValoresIniciales(), iniciales);
  }

  return ResultadoPartida(tablero, dados, jugadas);
}

void main() {
  group('Partidas simuladas', () {
    test('100 partidas al azar nunca rompen ninguna regla', () {
      for (var semilla = 1; semilla <= 100; semilla++) {
        final resultado = jugarPartida(semilla);

        expect(resultado.jugadas, greaterThan(0), reason: 'Semilla $semilla');
        expect(
          resultado.dados.historial.lanzamientos.every(
            (lanzamiento) => lanzamiento.accionRealizada != null,
          ),
          isTrue,
          reason: 'Cada lanzamiento debe quedar con su acción en el historial',
        );
      }
    });

    test('Una partida con el tablero lleno siempre suma 54 puntos', () {
      var partidasLlenas = 0;
      for (var semilla = 1; semilla <= 100; semilla++) {
        final resultado = jugarPartida(semilla);
        if (!resultado.tablero.estaLleno) continue;

        partidasLlenas++;
        expect(resultado.tablero.puntuacionTotal, 54);
        expect(resultado.jugadas, 49 - 6);
        for (final zona in resultado.tablero.regiones) {
          expect(zona.completado, isTrue);
        }
      }

      expect(
        partidasLlenas,
        greaterThan(0),
        reason: 'Al menos una partida simulada debe llenar el tablero',
      );
    });

    test('La misma semilla juega exactamente la misma partida', () {
      final primera = jugarPartida(42);
      final segunda = jugarPartida(42);

      expect(primera.jugadas, segunda.jugadas);
      expect(primera.tablero.extraerDatos(), segunda.tablero.extraerDatos());
      expect(primera.tablero.puntuacionTotal, segunda.tablero.puntuacionTotal);
    });
  });
}
