// Fija las reglas de puntuación de cada mapa tal como están hoy, antes de
// construir la puntuación por orden de llegada del multijugador.
//
// PuntosPorLugar son las listas definidas para cada mapa al crearlo (1.º, 2.º
// y 3.º lugar). El modo individual solo usa el primer número.

import 'package:brilliantdart/catalogo_mapas.dart';
import 'package:brilliantdart/mapa.dart';
import 'package:brilliantdart/region.dart';
import 'package:brilliantdart/tablero.dart';
import 'package:brilliantdart/tipoo.dart';
import 'package:test/test.dart';

typedef PuntosPorLugar = (int, int, int);

class ReglasDeColor {
  const ReglasDeColor(this.puntos, this.zonas);

  /// Puntos para el 1.º, 2.º y 3.º lugar.
  final PuntosPorLugar puntos;

  /// Cuántas celdas tiene cada zona de este color.
  final List<int> zonas;
}

const Map<int, Map<TipoZona, ReglasDeColor>> reglasPorMapa = {
  1: {
    TipoZona.azul: ReglasDeColor((7, 5, 3), [4, 4]),
    TipoZona.rojo: ReglasDeColor((6, 4, 2), [6, 6]),
    TipoZona.verde: ReglasDeColor((4, 3, 2), [6, 6]),
    TipoZona.amarillo: ReglasDeColor((8, 6, 4), [5]),
    TipoZona.morado: ReglasDeColor((6, 4, 2), [6, 6]),
  },
  2: {
    TipoZona.azul: ReglasDeColor((7, 5, 3), [5, 5]),
    TipoZona.rojo: ReglasDeColor((6, 4, 2), [6, 6]),
    TipoZona.verde: ReglasDeColor((4, 3, 2), [5, 5]),
    TipoZona.amarillo: ReglasDeColor((6, 4, 2), [5]),
    TipoZona.morado: ReglasDeColor((6, 4, 2), [5, 5]),
    TipoZona.gris: ReglasDeColor((3, 2, 1), [2]),
  },
  3: {
    TipoZona.azul: ReglasDeColor((7, 5, 3), [5]),
    TipoZona.rojo: ReglasDeColor((6, 4, 2), [6, 6]),
    TipoZona.verde: ReglasDeColor((6, 5, 4), [9]),
    TipoZona.amarillo: ReglasDeColor((7, 5, 3), [6]),
    TipoZona.morado: ReglasDeColor((7, 5, 3), [6, 6]),
    TipoZona.gris: ReglasDeColor((8, 6, 4), [5]),
  },
  4: {
    TipoZona.azul: ReglasDeColor((8, 6, 4), [6]),
    TipoZona.rojo: ReglasDeColor((6, 4, 2), [6, 6]),
    TipoZona.verde: ReglasDeColor((3, 2, 1), [4]),
    TipoZona.amarillo: ReglasDeColor((8, 6, 4), [6]),
    TipoZona.morado: ReglasDeColor((7, 5, 3), [7]),
    TipoZona.naranja: ReglasDeColor((6, 4, 3), [7, 7]),
  },
};

/// Lo que puede sacar un jugador en una partida individual en cada mapa.
const Map<int, int> puntuacionMaximaPorMapa = {1: 54, 2: 55, 3: 54, 4: 50};

/// Números que cumplen la regla de la zona; [valido] en falso rompe la regla
/// en los colores que pueden romperla al estar llenos.
List<int> numerosPara(Region zona, {bool valido = true}) {
  final celdas = zona.tamanoRegion;
  final tipo = zona.tipo;
  return switch (tipo.tipo) {
    TipoZona.azul || TipoZona.gris => [
      for (var i = 0; i < celdas; i++) (!valido && i == 0) ? 2 : 1,
    ],
    TipoZona.rojo ||
    TipoZona.amarillo => [for (var i = 0; i < celdas; i++) valido ? i + 1 : 1],
    TipoZona.verde => List.filled(celdas, 1),
    TipoZona.morado => [
      for (var i = 0; i < celdas; i++) (valido && i == 0) ? 2 : 1,
    ],
    TipoZona.naranja => List.filled(
      celdas,
      valido ? (tipo as TipoNaranja).minimo : 0,
    ),
  };
}

void llenar(Tablero tablero, Region zona, {bool valido = true}) {
  final numeros = numerosPara(zona, valido: valido);
  for (var i = 0; i < numeros.length; i++) {
    final celda = zona.coordenadas[i];
    tablero.colocarDato(celda.x, celda.y, numeros[i]);
  }
}

List<Region> zonasDe(Tablero tablero, TipoZona color) =>
    tablero.regiones.where((zona) => zona.tipo.tipo == color).toList();

void main() {
  group('Reglas de puntuación: los mapas', () {
    test('Hay cuatro mapas y todos están descritos aquí', () {
      expect(mapasDisponibles.map((mapa) => mapa.numero), [1, 2, 3, 4]);
      expect(reglasPorMapa.keys, [1, 2, 3, 4]);
    });

    test('El rojo vale lo mismo en todos los mapas', () {
      for (final reglas in reglasPorMapa.values) {
        expect(reglas[TipoZona.rojo]!.puntos, (6, 4, 2));
      }
    });
  });

  for (final Mapa mapa in mapasDisponibles) {
    final reglas = reglasPorMapa[mapa.numero]!;

    group('Reglas de puntuación: Mapa ${mapa.numero}', () {
      test('Tiene justo estos colores', () {
        expect(mapa.tiposPresentes.toSet(), reglas.keys.toSet());
      });

      test('Cada color tiene sus zonas con estos tamaños', () {
        final tablero = mapa.crearTablero();
        reglas.forEach((color, regla) {
          expect(
            zonasDe(tablero, color).map((zona) => zona.tamanoRegion),
            regla.zonas,
            reason: color.name,
          );
        });
      });

      test('Las zonas cubren todo el tablero sin repetir celdas', () {
        final tablero = mapa.crearTablero();
        final celdas = [
          for (final zona in tablero.regiones)
            for (final celda in zona.coordenadas) (celda.x, celda.y),
        ];
        expect(celdas, hasLength(49));
        expect(celdas.toSet(), hasLength(49));
      });

      test('Una zona completa suma el primer número de su color', () {
        reglas.forEach((color, regla) {
          final tablero = mapa.crearTablero();
          llenar(tablero, zonasDe(tablero, color).first);
          expect(tablero.puntuacionTotal, regla.puntos.$1, reason: color.name);
        });
      });

      test('El total del mapa es la suma de todas sus zonas', () {
        var esperado = 0;
        reglas.forEach((_, regla) {
          esperado += regla.puntos.$1 * regla.zonas.length;
        });
        expect(esperado, puntuacionMaximaPorMapa[mapa.numero]);
        expect(mapa.crearTablero().puntuacionMaxima, esperado);
      });

      test('Toda zona se puede completar según su regla', () {
        final tablero = mapa.crearTablero();
        for (final zona in tablero.regiones) {
          llenar(tablero, zona);
          expect(zona.completado, isTrue, reason: zona.tipo.color);
        }
      });

      test('Una zona con una celda vacía no está completa ni suma', () {
        final tablero = mapa.crearTablero();
        for (final zona in tablero.regiones) {
          llenar(tablero, zona);
          final ultima = zona.coordenadas.last;
          tablero.colocarDato(ultima.x, ultima.y, null);
          expect(zona.completado, isFalse, reason: zona.tipo.color);
        }
        expect(tablero.puntuacionTotal, 0);
      });

      test('Una zona llena que rompe su regla no está completa', () {
        final tablero = mapa.crearTablero();
        for (final zona in tablero.regiones) {
          // Al verde le vale cualquier combinación: no se puede romper.
          if (zona.tipo.tipo == TipoZona.verde) continue;
          llenar(tablero, zona, valido: false);
          expect(zona.completado, isFalse, reason: zona.tipo.color);
        }
      });

      test('Partida individual: el tablero completo da los puntos de hoy', () {
        final tablero = mapa.crearTablero();
        for (final zona in tablero.regiones) {
          llenar(tablero, zona);
        }
        expect(tablero.estaLleno, isTrue);
        expect(tablero.puntuacionTotal, puntuacionMaximaPorMapa[mapa.numero]);
      });

      test('Partida individual: cada color suma lo de sus zonas', () {
        final tablero = mapa.crearTablero();
        for (final zona in tablero.regiones) {
          llenar(tablero, zona);
        }
        reglas.forEach((color, regla) {
          expect(
            tablero.puntuacionPorTipo(color),
            regla.puntos.$1 * regla.zonas.length,
            reason: color.name,
          );
          expect(tablero.zonasCompletadasPorTipo(color), regla.zonas.length);
        });
      });
    });
  }

  group('Reglas de puntuación: reglas para completar cada color', () {
    const casos = <(TipoZona, List<int>, List<int>)>[
      (TipoZona.azul, [3, 3, 3], [3, 3, 4]),
      (TipoZona.gris, [5, 5], [5, 6]),
      (TipoZona.rojo, [1, 2, 3], [1, 2, 2]),
      (TipoZona.amarillo, [1, 2, 3], [1, 1, 3]),
      (TipoZona.morado, [1, 2, 2], [2, 2, 2]),
      (TipoZona.morado, [1, 2, 2], [1, 2, 3]),
    ];

    for (final (color, bien, mal) in casos) {
      test('${color.name}: $bien cumple y $mal no', () {
        final tipo = Tipo(
          tipo: color,
          color: color.name,
          regla: '',
          puntuacion: 1,
        );
        expect(tipo.validarMovimiento(bien), isTrue);
        expect(tipo.validarMovimiento(mal), isFalse);
      });
    }

    test('verde: cualquier combinación cumple', () {
      final tipo = Tipo(
        tipo: TipoZona.verde,
        color: 'Verde',
        regla: '',
        puntuacion: 1,
      );
      expect(tipo.validarMovimiento([1, 1, 1]), isTrue);
      expect(tipo.validarMovimiento([1, 2, 6]), isTrue);
    });

    test('naranja del Mapa 4: arriba del 4 al 6, abajo del 1 al 3', () {
      final naranjas = zonasDe(mapaNumero(4).crearTablero(), TipoZona.naranja);
      final arriba = naranjas[0].tipo;
      final abajo = naranjas[1].tipo;

      expect(arriba.validarMovimiento([4, 5, 6, 4]), isTrue);
      expect(arriba.validarMovimiento([3, 5, 6, 4]), isFalse);
      expect(abajo.validarMovimiento([1, 2, 3, 1]), isTrue);
      expect(abajo.validarMovimiento([4, 2, 3, 1]), isFalse);
    });
  });

  group('Reglas de puntuación: lugares en multijugador', () {
    test('Cada zona de cada mapa tiene su lista completa de puntos', () {
      for (final mapa in mapasDisponibles) {
        final reglas = reglasPorMapa[mapa.numero]!;
        for (final zona in mapa.crearTablero().regiones) {
          final puntos = reglas[zona.tipo.tipo]!.puntos;
          final tipo = zona.tipo;
          final nombre = 'Mapa ${mapa.numero}, ${tipo.color}';
          expect(tipo.calcularPuntuacion(1), puntos.$1, reason: nombre);
          expect(tipo.calcularPuntuacion(2), puntos.$2, reason: nombre);
          expect(tipo.calcularPuntuacion(3), puntos.$3, reason: nombre);
          expect(tipo.puntuacion, puntos.$1, reason: nombre);
        }
      }
    });

    test('Del cuarto lugar en adelante no se ganan puntos', () {
      for (final mapa in mapasDisponibles) {
        for (final zona in mapa.crearTablero().regiones) {
          for (final lugar in [4, 5, 6]) {
            expect(zona.tipo.puntosDeLugar(lugar), 0);
          }
        }
      }
    });

    test('No existe un lugar antes del primero', () {
      final tipo = mapaNumero(1).crearTablero().regiones.first.tipo;

      expect(() => tipo.puntosDeLugar(0), throwsArgumentError);
    });

    test('Sin lista propia se usan los puntos del color', () {
      final tipo = Tipo(
        tipo: TipoZona.azul,
        color: 'Azul',
        regla: '',
        puntuacion: 7,
      );

      expect(tipo.puntuaciones, {1: 7, 2: 5, 3: 3});
    });
  });
}
