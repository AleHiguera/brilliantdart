import 'package:test/test.dart';

import 'package:brilliantdart/mapa_uno.dart';
import 'package:brilliantdart/tipoo.dart';
import 'package:brilliantdart/validador_anclas.dart';

void main() {
  group('Mapa uno', () {
    test('Registra zonas para las 49 celdas del tablero', () {
      final tablero = mapaUno.crearTablero();
      final posiciones = tablero.regiones
          .expand((region) => region.coordenadas)
          .map((celda) => (celda.x, celda.y))
          .toList();

      expect(posiciones, hasLength(49));
      expect(posiciones.toSet(), hasLength(49));
    });

    test('Aplica la regla roja y registra el número colocado como ancla', () {
      final tablero = mapaUno.crearTablero();
      final ancla = tablero.obtenerCelda(3, 1);
      ancla.valor = 5;

      expect(tablero.puedeColocarDato(2, 1, 5), isFalse);
      expect(tablero.puedeColocarDato(2, 1, 4), isTrue);

      tablero.colocarDato(2, 1, 4);
      expect(tablero.valoresColocados, contains(4));
      expect(ValidadorAnclas(tablero).puedeSerAncla(4), isTrue);
    });

    test('Los amarillos comparten la regla de no repetir', () {
      final tablero = mapaUno.crearTablero();
      final ancla = tablero.obtenerCelda(0, 0);
      ancla.valor = 3;

      expect(tablero.puedeColocarDato(3, 3, 3), isFalse);
      expect(tablero.puedeColocarDato(3, 3, 4), isTrue);
    });

    test('La ultima casilla morada debe completar dos numeros diferentes', () {
      final tablero = mapaUno.crearTablero();
      final zonaMorada = tablero.regiones.firstWhere(
        (region) =>
            region.tipo.tipo == TipoZona.morado && region.tamanoRegion == 6,
      );
      for (final celda in zonaMorada.coordenadas.take(5)) {
        celda.valor = 2;
      }
      final ultimaCelda = zonaMorada.coordenadas.last;

      expect(
        tablero.puedeColocarDato(ultimaCelda.x, ultimaCelda.y, 2),
        isFalse,
      );
      expect(tablero.puedeColocarDato(ultimaCelda.x, ultimaCelda.y, 3), isTrue);
      expect(ultimaCelda.valor, isNull);
    });

    test('El mapa conserva el tipo de zona esperado en las celdas', () {
      final tablero = mapaUno.crearTablero();
      final roja = tablero.regiones.singleWhere(
        (region) => region.contieneCoordenada(3, 1),
      );
      final azul = tablero.regiones.singleWhere(
        (region) => region.contieneCoordenada(0, 2),
      );

      expect(roja.tipo.tipo, TipoZona.rojo);
      expect(azul.tipo.tipo, TipoZona.azul);
    });

    test('Suma 54 puntos al completar cada zona una sola vez', () {
      final tablero = mapaUno.crearTablero();

      expect(tablero.puntuacionTotal, 0);

      for (final region in tablero.regiones) {
        for (var indice = 0; indice < region.coordenadas.length; indice++) {
          final numero = switch (region.tipo.tipo) {
            TipoZona.azul => 2,
            TipoZona.rojo || TipoZona.amarillo => indice + 1,
            TipoZona.verde => indice % 3 + 1,
            TipoZona.morado => indice == 0 ? 2 : 5,
          };
          final celda = region.coordenadas[indice];
          tablero.colocarDato(celda.x, celda.y, numero);
        }
      }

      expect(tablero.puntuacionTotal, 54);
      expect(tablero.puntuacionPorTipo(TipoZona.morado), 12);
      expect(tablero.puntuacionPorTipo(TipoZona.amarillo), 8);
      expect(tablero.puntuacionPorTipo(TipoZona.verde), 8);
      expect(tablero.puntuacionPorTipo(TipoZona.azul), 14);
      expect(tablero.puntuacionPorTipo(TipoZona.rojo), 12);

      final ultimaZona = tablero.regiones.last;
      final ultimaCelda = ultimaZona.coordenadas.last;
      tablero.colocarDato(ultimaCelda.x, ultimaCelda.y, ultimaCelda.valor);

      expect(tablero.puntuacionTotal, 54);
    });

    test(
      'Tiene 9 zonas: 2 azules, 2 rojas, 2 verdes, 2 moradas y 1 amarilla',
      () {
        final tablero = mapaUno.crearTablero();
        int cuantas(TipoZona tipo) =>
            tablero.regiones.where((zona) => zona.tipo.tipo == tipo).length;

        expect(tablero.regiones, hasLength(9));
        expect(cuantas(TipoZona.azul), 2);
        expect(cuantas(TipoZona.rojo), 2);
        expect(cuantas(TipoZona.verde), 2);
        expect(cuantas(TipoZona.morado), 2);
        expect(cuantas(TipoZona.amarillo), 1);
      },
    );

    test('La zona amarilla une las cuatro esquinas y el centro', () {
      final tablero = mapaUno.crearTablero();
      final amarilla = tablero.regiones.singleWhere(
        (zona) => zona.tipo.tipo == TipoZona.amarillo,
      );

      expect(amarilla.coordenadas.map((celda) => (celda.x, celda.y)).toSet(), {
        (0, 0),
        (0, 6),
        (3, 3),
        (6, 0),
        (6, 6),
      });
    });

    test('Cada zona es un bloque de celdas vecinas del mismo color', () {
      final tablero = mapaUno.crearTablero();

      for (final zona in tablero.regiones) {
        for (final celda in zona.coordenadas) {
          expect(mapaUno.tiposPorCelda[celda.x][celda.y], zona.tipo.tipo);
        }
        if (zona.tipo.tipo == TipoZona.amarillo) continue;

        final posiciones = zona.coordenadas
            .map((celda) => (celda.x, celda.y))
            .toSet();
        final alcanzadas = {posiciones.first};
        final pendientes = [posiciones.first];
        while (pendientes.isNotEmpty) {
          final (fila, columna) = pendientes.removeLast();
          for (final vecina in [
            (fila - 1, columna),
            (fila + 1, columna),
            (fila, columna - 1),
            (fila, columna + 1),
          ]) {
            if (posiciones.contains(vecina) && alcanzadas.add(vecina)) {
              pendientes.add(vecina);
            }
          }
        }
        expect(alcanzadas, posiciones, reason: 'Zona ${zona.id}');
      }
    });

    test('Los puntos de cada color son amarillo 8, verde 4, morado 6, '
        'azul 7 y rojo 6', () {
      final tablero = mapaUno.crearTablero();
      const esperados = {
        TipoZona.amarillo: 8,
        TipoZona.verde: 4,
        TipoZona.morado: 6,
        TipoZona.azul: 7,
        TipoZona.rojo: 6,
      };

      for (final zona in tablero.regiones) {
        expect(zona.tipo.puntuacion, esperados[zona.tipo.tipo]);
        expect(zona.tipo.calcularPuntuacion(1), zona.tipo.puntuacion);
      }
    });

    test('Ninguna celda inicial está en la zona amarilla', () {
      for (final (fila, columna) in mapaUno.celdasIniciales) {
        expect(
          mapaUno.tiposPorCelda[fila - 1][columna - 1],
          isNot(TipoZona.amarillo),
        );
      }
    });

    test('Cada tablero creado es independiente', () {
      final primero = mapaUno.crearTablero();
      final segundo = mapaUno.crearTablero();

      primero.colocarDato(0, 0, 5);

      expect(segundo.obtenerCelda(0, 0).valor, isNull);
    });
  });
}
