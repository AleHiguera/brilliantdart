// La misma partida simulada con 2, 3, 4, 5 y 6 jugadores, como la juega
// PruebasSalasMultijugador en el servidor:
// - j1 gana el 1.º lugar de la amarilla (8), la azul de arriba (7) y la azul
//   de abajo (7) en las rondas 1, 2 y 3, y la morada (6) en la 4: 22 y luego 28.
// - El jugador i (desde j2) completa la amarilla en la ronda i: 2.º, 3.º...
// - La partida termina al final de la ronda en que j1 llega a la meta.

import 'package:brilliantdart/clasificacion.dart';
import 'package:brilliantdart/mapa_uno.dart';
import 'package:brilliantdart/puntuacion_multijugador.dart';
import 'package:test/test.dart';

/// La meta de la especificación, según cuántos empezaron.
const Map<int, int> metaPorJugadores = {2: 26, 3: 24, 4: 22, 5: 20, 6: 20};

// Mapa 1: zona 1 amarilla, 3 y 9 azules, 4 morada.
const List<int> zonasDeJ1 = [1, 3, 9, 4];
const int amarilla = 1;

/// Ronda en que j1 alcanza la meta: con 22 o 20 le bastan 3 zonas (22).
int rondaFinal(int jugadores) => metaPorJugadores[jugadores]! > 22 ? 4 : 3;

List<String> jugadores(int cantidad) => [
  for (var i = 1; i <= cantidad; i++) 'j$i',
];

/// El registro de zonas tal como queda al terminar la partida.
Map<int, Map<String, int>> registro(int cantidad) {
  final fin = rondaFinal(cantidad);
  final zonas = <int, Map<String, int>>{};
  for (var ronda = 1; ronda <= fin; ronda++) {
    (zonas[zonasDeJ1[ronda - 1]] ??= {})['j1'] = ronda;
  }
  for (var i = 2; i <= cantidad && i <= fin; i++) {
    (zonas[amarilla] ??= {})['j$i'] = i;
  }
  return zonas;
}

void main() {
  for (final cantidad in [2, 3, 4, 5, 6]) {
    group('Partida de $cantidad jugadores', () {
      final meta = metaPorJugadores[cantidad]!;
      final puntos = PuntuacionMultijugador(mapaUno, registro(cantidad)).puntos;
      final clasificacion = Clasificacion(
        puntos: puntos,
        jugadores: jugadores(cantidad),
      );

      test('j1 llega a la meta de $meta justo en la última ronda', () {
        final fin = rondaFinal(cantidad);
        final antes = PuntuacionMultijugador(mapaUno, {
          for (final MapEntry(key: zona, value: rondas) in registro(
            cantidad,
          ).entries)
            zona: {
              for (final MapEntry(key: jugador, value: ronda) in rondas.entries)
                if (ronda < fin) jugador: ronda,
            },
        }).puntos;

        expect(puntos['j1'], greaterThanOrEqualTo(meta));
        expect(antes['j1'], lessThan(meta));
      });

      test('Nadie más llega a la meta', () {
        for (final jugador in jugadores(cantidad).skip(1)) {
          expect(puntos[jugador] ?? 0, lessThan(meta));
        }
      });

      test('El ganador es j1 y los demás van de mayor a menor', () {
        final enOrden = clasificacion.puestos.map((p) => p.puntos).toList();

        expect(clasificacion.puestos.first.jugador, 'j1');
        expect(clasificacion.puestos.where((p) => p.lugar == 1), hasLength(1));
        expect(enOrden, [...enOrden]..sort((a, b) => b.compareTo(a)));
      });

      test('Los empatados comparten el lugar', () {
        for (final puesto in clasificacion.puestos) {
          final mismosPuntos = clasificacion.puestos.where(
            (otro) => otro.puntos == puesto.puntos,
          );
          expect(mismosPuntos.map((p) => p.lugar).toSet(), {puesto.lugar});
        }
      });

      test('Todos están en la clasificación', () {
        expect(
          clasificacion.puestos.map((p) => p.jugador).toSet(),
          jugadores(cantidad).toSet(),
        );
      });
    });
  }

  test('Las clasificaciones esperadas, una por cantidad de jugadores', () {
    List<(int, String, int)> resumen(int cantidad) => [
      for (final puesto in Clasificacion(
        puntos: PuntuacionMultijugador(mapaUno, registro(cantidad)).puntos,
        jugadores: jugadores(cantidad),
      ).puestos)
        (puesto.lugar, puesto.jugador, puesto.puntos),
    ];

    expect(resumen(2), [(1, 'j1', 28), (2, 'j2', 6)]);
    expect(resumen(3), [(1, 'j1', 28), (2, 'j2', 6), (3, 'j3', 4)]);
    expect(resumen(4), [
      (1, 'j1', 22),
      (2, 'j2', 6),
      (3, 'j3', 4),
      (4, 'j4', 0),
    ]);
    // Los que no completaron nada empatan en el último lugar.
    expect(resumen(5), [
      (1, 'j1', 22),
      (2, 'j2', 6),
      (3, 'j3', 4),
      (4, 'j4', 0),
      (4, 'j5', 0),
    ]);
    expect(resumen(6), [
      (1, 'j1', 22),
      (2, 'j2', 6),
      (3, 'j3', 4),
      (4, 'j4', 0),
      (4, 'j5', 0),
      (4, 'j6', 0),
    ]);
  });
}
