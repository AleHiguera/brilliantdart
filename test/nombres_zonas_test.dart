// Prueba unitaria: cómo se nombra cada zona en los avisos de la partida.

import 'package:brilliantdart/catalogo_mapas.dart';
import 'package:brilliantdart/mapa_cuatro.dart';
import 'package:brilliantdart/mapa_uno.dart';
import 'package:brilliantdart/nombres_zonas.dart';
import 'package:brilliantdart/tipoo.dart';
import 'package:test/test.dart';

void main() {
  group('Nombres de zonas', () {
    for (final mapa in mapasDisponibles) {
      test('Mapa ${mapa.numero}: cada zona se nombra con su color', () {
        final nombres = NombresZonas(mapa);
        for (final region in mapa.crearTablero().regiones) {
          expect(
            nombres.de(region.id),
            startsWith('la zona ${NombresZonas.colores[region.tipo.tipo]}'),
            reason: 'zona ${region.id}',
          );
        }
      });
    }

    test('Mapa 4: los naranjas dicen si son el de arriba o el de abajo', () {
      final nombres = NombresZonas(mapaCuatro);
      final naranjas = {
        for (final region in mapaCuatro.crearTablero().regiones)
          if (region.tipo case TipoNaranja(:final minimo))
            minimo: nombres.de(region.id),
      };

      expect(naranjas, {
        4: 'la zona naranja de arriba',
        1: 'la zona naranja de abajo',
      });
    });

    test('Los demás colores no llevan arriba ni abajo', () {
      for (final mapa in mapasDisponibles) {
        final nombres = NombresZonas(mapa);
        for (final region in mapa.crearTablero().regiones) {
          if (region.tipo.tipo == TipoZona.naranja) continue;
          expect(nombres.de(region.id), isNot(contains('arriba')));
          expect(nombres.de(region.id), isNot(contains('abajo')));
        }
      }
    });

    test('Un número que no es del mapa se dice «una zona»', () {
      expect(NombresZonas(mapaCuatro).de(999), 'una zona');
    });

    test('Todos los colores tienen nombre', () {
      expect(NombresZonas.colores.keys.toSet(), TipoZona.values.toSet());
    });
  });

  group('Zonas del mismo color', () {
    test('Mapa 1: las dos verdes se distinguen como verde 1 y verde 2', () {
      final verdes = [
        for (final region in mapaUno.crearTablero().regiones)
          if (region.tipo.tipo == TipoZona.verde) region.id,
      ];
      final nombres = NombresZonas(mapaUno);

      expect(verdes, hasLength(2));
      expect(nombres.de(verdes[0]), 'la zona verde 1');
      expect(nombres.de(verdes[1]), 'la zona verde 2');
    });

    test('En todos los mapas, cada zona tiene un nombre distinto', () {
      for (final mapa in mapasDisponibles) {
        final nombres = NombresZonas(mapa);
        final todos = [
          for (final region in mapa.crearTablero().regiones)
            nombres.de(region.id),
        ];
        expect(
          todos.toSet(),
          hasLength(todos.length),
          reason: 'Mapa ${mapa.numero}',
        );
      }
    });

    test('Un color con una sola zona no lleva número', () {
      for (final mapa in mapasDisponibles) {
        final regiones = mapa.crearTablero().regiones;
        final nombres = NombresZonas(mapa);
        for (final region in regiones) {
          final mismas = regiones.where(
            (otra) => otra.tipo.tipo == region.tipo.tipo,
          );
          if (mismas.length == 1) {
            expect(
              nombres.de(region.id),
              'la zona ${NombresZonas.colores[region.tipo.tipo]}',
            );
          }
        }
      }
    });
  });
}
