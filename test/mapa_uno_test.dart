import 'package:test/test.dart';

import 'package:brilliantdart/mapa_uno.dart';
import 'package:brilliantdart/tipoo.dart';
import 'package:brilliantdart/validador_anclas.dart';

void main() {
  group('Mapa uno', () {
    test('Registra zonas para las 49 celdas del tablero', () {
      final tablero = MapaUno.crearTablero();
      final posiciones = tablero.regiones
          .expand((region) => region.coordenadas)
          .map((celda) => (celda.x, celda.y))
          .toList();

      expect(posiciones, hasLength(49));
      expect(posiciones.toSet(), hasLength(49));
    });

    test('Aplica la regla roja y registra el número colocado como ancla', () {
      final tablero = MapaUno.crearTablero();
      final ancla = tablero.obtenerCelda(3, 1);
      ancla.valor = 5;

      expect(tablero.puedeColocarDato(2, 1, 5), isFalse);
      expect(tablero.puedeColocarDato(2, 1, 4), isTrue);

      tablero.colocarDato(2, 1, 4);
      expect(tablero.valoresColocados, contains(4));
      expect(ValidadorAnclas(tablero).puedeSerAncla(4), isTrue);
    });

    test('Los amarillos comparten la regla de no repetir', () {
      final tablero = MapaUno.crearTablero();
      final ancla = tablero.obtenerCelda(0, 0);
      ancla.valor = 3;

      expect(tablero.puedeColocarDato(3, 3, 3), isFalse);
      expect(tablero.puedeColocarDato(3, 3, 4), isTrue);
    });

    test('La ultima casilla morada debe completar dos numeros diferentes', () {
      final tablero = MapaUno.crearTablero();
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
      expect(
        tablero.puedeColocarDato(ultimaCelda.x, ultimaCelda.y, 3),
        isTrue,
      );
      expect(ultimaCelda.valor, isNull);
    });

    test('El mapa conserva el tipo de zona esperado en las celdas', () {
      final tablero = MapaUno.crearTablero();
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
      final tablero = MapaUno.crearTablero();

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
  });
}