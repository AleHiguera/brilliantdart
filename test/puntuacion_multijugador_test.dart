import 'package:brilliantdart/catalogo_mapas.dart';
import 'package:brilliantdart/mapa.dart';
import 'package:brilliantdart/mapa_uno.dart';
import 'package:brilliantdart/puntuacion_multijugador.dart';
import 'package:brilliantdart/tipoo.dart';
import 'package:test/test.dart';

/// Los números de las zonas de ese color, en el orden del tablero.
List<int> zonasDe(Mapa mapa, TipoZona color) => [
  for (final zona in mapa.crearTablero().regiones)
    if (zona.tipo.tipo == color) zona.id,
];

void main() {
  final amarilla = zonasDe(mapaUno, TipoZona.amarillo).single;
  final verdes = zonasDe(mapaUno, TipoZona.verde);

  group('Puntuación multijugador: orden de finalización', () {
    test('Zona amarilla del Mapa 1: 8, 6, 4 y el cuarto lugar 0', () {
      final partida = PuntuacionMultijugador(mapaUno, {
        amarilla: {'ana': 2, 'luis': 4, 'eva': 6, 'sol': 8},
      });

      expect(partida.puntos, {'ana': 8, 'luis': 6, 'eva': 4, 'sol': 0});
    });

    test('Sin zonas completadas nadie tiene puntos', () {
      expect(PuntuacionMultijugador(mapaUno, const {}).puntos, isEmpty);
    });

    test('Agotados los lugares, ningún otro gana puntos por esa zona', () {
      final partida = PuntuacionMultijugador(mapaUno, {
        amarilla: {'a': 1, 'b': 2, 'c': 3, 'd': 4, 'e': 5, 'f': 6},
      });

      expect(partida.puntos, {'a': 8, 'b': 6, 'c': 4, 'd': 0, 'e': 0, 'f': 0});
    });

    test('Cada color de cada mapa usa sus propios puntos', () {
      const esperados = {
        1: {TipoZona.amarillo: (8, 6, 4), TipoZona.verde: (4, 3, 2)},
        2: {TipoZona.amarillo: (6, 4, 2), TipoZona.gris: (3, 2, 1)},
        3: {TipoZona.gris: (8, 6, 4), TipoZona.verde: (6, 5, 4)},
        4: {TipoZona.azul: (8, 6, 4), TipoZona.naranja: (6, 4, 3)},
      };

      esperados.forEach((numero, colores) {
        final mapa = mapaNumero(numero);
        colores.forEach((color, puntos) {
          final partida = PuntuacionMultijugador(mapa, {
            zonasDe(mapa, color).first: {'a': 1, 'b': 2, 'c': 3},
          });
          expect(partida.puntos, {
            'a': puntos.$1,
            'b': puntos.$2,
            'c': puntos.$3,
          }, reason: 'Mapa $numero, ${color.name}');
        });
      });
    });
  });

  group('Puntuación multijugador: empates', () {
    test('Dos empatados reciben los puntos completos', () {
      final partida = PuntuacionMultijugador(mapaUno, {
        amarilla: {'ana': 3, 'luis': 3},
      });

      expect(partida.puntos, {'ana': 8, 'luis': 8});
    });

    test('Tras un empate, el siguiente recibe el lugar inmediato', () {
      final partida = PuntuacionMultijugador(mapaUno, {
        amarilla: {'ana': 3, 'luis': 3, 'eva': 5, 'sol': 7},
      });

      expect(partida.puntos, {'ana': 8, 'luis': 8, 'eva': 6, 'sol': 4});
    });

    test('Pueden empatar 3 o 4 jugadores', () {
      expect(
        PuntuacionMultijugador(mapaUno, {
          amarilla: {'a': 3, 'b': 3, 'c': 3},
        }).puntos,
        {'a': 8, 'b': 8, 'c': 8},
      );
      expect(
        PuntuacionMultijugador(mapaUno, {
          amarilla: {'a': 3, 'b': 3, 'c': 3, 'd': 3, 'e': 9},
        }).puntos,
        {'a': 8, 'b': 8, 'c': 8, 'd': 8, 'e': 6},
      );
    });

    test('Un cuarto jugador aún gana si los empates dejaron lugares', () {
      final partida = PuntuacionMultijugador(mapaUno, {
        amarilla: {'a': 1, 'b': 1, 'c': 2, 'd': 3},
      });

      expect(partida.puntos['d'], 4);
    });
  });

  group('Puntuación multijugador: cada zona tiene su registro', () {
    test('Llenar los lugares de un verde no ocupa los del otro', () {
      final partida = PuntuacionMultijugador(mapaUno, {
        verdes[0]: {'ana': 1, 'luis': 2, 'eva': 3, 'sol': 4},
        verdes[1]: {'sol': 9},
      });

      expect(partida.zonas[verdes[0]]!.puntos['sol'], 0);
      expect(partida.zonas[verdes[1]]!.puntos['sol'], 4);
    });

    test('Un jugador suma los puntos de todas sus zonas', () {
      final partida = PuntuacionMultijugador(mapaUno, {
        verdes[0]: {'ana': 1, 'luis': 2},
        verdes[1]: {'luis': 3, 'ana': 4},
        amarilla: {'ana': 5},
      });

      expect(partida.puntos, {'ana': 4 + 3 + 8, 'luis': 3 + 4});
    });

    test('Colores distintos no comparten lugares', () {
      final azul = zonasDe(mapaUno, TipoZona.azul).first;
      final partida = PuntuacionMultijugador(mapaUno, {
        amarilla: {'ana': 1},
        azul: {'luis': 8},
      });

      expect(partida.puntos, {'ana': 8, 'luis': 7});
    });

    test('Una zona que el mapa no tiene no reparte puntos', () {
      expect(
        PuntuacionMultijugador(mapaUno, {
          999: {'ana': 1},
        }).puntos,
        isEmpty,
      );
    });
  });

  group('Puntuación multijugador: quien sale de la partida', () {
    // El registro del servidor conserva a quien se fue, y por eso sigue contando.
    test('Su lugar queda ocupado y nadie sube', () {
      final partida = PuntuacionMultijugador(mapaUno, {
        amarilla: {'ana-que-salio': 1, 'luis': 2},
      });

      expect(partida.puntos['luis'], 6);
    });
  });

  group('Puntuación multijugador: números de zona', () {
    test('Son los mismos en todos los tableros de un mapa', () {
      for (final mapa in mapasDisponibles) {
        final uno = mapa.crearTablero().regiones;
        final otro = mapa.crearTablero().regiones;

        expect(uno.map((zona) => zona.id), otro.map((zona) => zona.id));
        for (var i = 0; i < uno.length; i++) {
          expect(
            uno[i].coordenadas.map((celda) => (celda.x, celda.y)),
            otro[i].coordenadas.map((celda) => (celda.x, celda.y)),
          );
        }
      }
    });

    test('Van del 1 al total de zonas, sin repetirse', () {
      for (final mapa in mapasDisponibles) {
        final ids = mapa
            .crearTablero()
            .regiones
            .map((zona) => zona.id)
            .toList();

        expect(ids.toSet(), hasLength(ids.length));
        expect(ids.reduce((a, b) => a < b ? a : b), greaterThanOrEqualTo(1));
        expect(ids.reduce((a, b) => a > b ? a : b), lessThanOrEqualTo(49));
      }
    });

    test('El tablero dice qué zona completó un movimiento', () {
      final tablero = mapaUno.crearTablero();
      final zona = tablero.regiones.firstWhere(
        (region) => region.tipo.tipo == TipoZona.azul,
      );
      final celdas = zona.coordenadas;

      for (final celda in celdas.take(celdas.length - 1)) {
        tablero.colocarDato(celda.x, celda.y, 3);
        expect(tablero.zonaCompletadaEn(celda.x, celda.y), isNull);
      }
      tablero.colocarDato(celdas.last.x, celdas.last.y, 3);

      expect(tablero.zonaCompletadaEn(celdas.last.x, celdas.last.y), zona.id);
    });
  });
}
