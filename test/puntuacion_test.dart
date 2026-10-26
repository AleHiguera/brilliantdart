import 'package:test/test.dart';

import 'package:brilliantdart/mapa_dos.dart';
import 'package:brilliantdart/mapa_uno.dart';
import 'package:brilliantdart/region.dart';
import 'package:brilliantdart/tablero.dart';
import 'package:brilliantdart/tipoo.dart';

void main() {
  /// Llena una zona respetando la regla de su color.
  void completarZona(Tablero tablero, Region zona, {bool dejarUna = false}) {
    final total = zona.coordenadas.length - (dejarUna ? 1 : 0);
    for (var indice = 0; indice < total; indice++) {
      final numero = switch (zona.tipo.tipo) {
        TipoZona.azul || TipoZona.gris => 2,
        TipoZona.rojo || TipoZona.amarillo => indice + 1,
        TipoZona.verde => 6,
        TipoZona.naranja => (zona.tipo as TipoNaranja).minimo,
        TipoZona.morado => indice == 0 ? 2 : 5,
      };
      final celda = zona.coordenadas[indice];
      tablero.colocarDato(celda.x, celda.y, numero);
    }
  }

  Region primeraZona(Tablero tablero, TipoZona tipo) =>
      tablero.regiones.firstWhere((zona) => zona.tipo.tipo == tipo);

  group('Puntuación del tablero', () {
    test('Un tablero nuevo tiene 0 puntos en todos los colores', () {
      final tablero = mapaUno.crearTablero();

      expect(tablero.puntuacionTotal, 0);
      for (final tipo in TipoZona.values) {
        expect(tablero.puntuacionPorTipo(tipo), 0);
        expect(tablero.zonasCompletadasPorTipo(tipo), 0);
      }
    });

    const puntosPorColor = {
      TipoZona.amarillo: 8,
      TipoZona.verde: 4,
      TipoZona.morado: 6,
      TipoZona.azul: 7,
      TipoZona.rojo: 6,
    };

    for (final MapEntry(key: tipo, value: puntos) in puntosPorColor.entries) {
      test('Completar una zona ${tipo.name} suma $puntos puntos', () {
        final tablero = mapaUno.crearTablero();

        completarZona(tablero, primeraZona(tablero, tipo));

        expect(tablero.puntuacionTotal, puntos);
        expect(tablero.puntuacionPorTipo(tipo), puntos);
        expect(tablero.zonasCompletadasPorTipo(tipo), 1);
        for (final otro in TipoZona.values.where((otro) => otro != tipo)) {
          expect(tablero.puntuacionPorTipo(otro), 0);
        }
      });

      test('Una zona ${tipo.name} a falta de una celda no suma', () {
        final tablero = mapaUno.crearTablero();

        completarZona(tablero, primeraZona(tablero, tipo), dejarUna: true);

        expect(tablero.puntuacionTotal, 0);
        expect(tablero.zonasCompletadasPorTipo(tipo), 0);
      });
    }

    test('Vaciar una celda de una zona completa le quita sus puntos', () {
      final tablero = mapaUno.crearTablero();
      final azul = primeraZona(tablero, TipoZona.azul);
      completarZona(tablero, azul);
      expect(tablero.puntuacionTotal, 7);

      final celda = azul.coordenadas.first;
      tablero.colocarDato(celda.x, celda.y, null);

      expect(tablero.puntuacionTotal, 0);
      expect(azul.completado, isFalse);
    });

    test('Una zona llena que rompe su regla no suma puntos', () {
      final tablero = mapaUno.crearTablero();
      final azul = primeraZona(tablero, TipoZona.azul);

      for (var i = 0; i < azul.coordenadas.length; i++) {
        final celda = azul.coordenadas[i];
        tablero.colocarDato(celda.x, celda.y, i + 1);
      }

      expect(tablero.puntuacionTotal, 0);
      expect(azul.completado, isFalse);
    });

    test('Completar dos zonas del mismo color suma el doble', () {
      final tablero = mapaUno.crearTablero();
      final rojas = tablero.regiones
          .where((zona) => zona.tipo.tipo == TipoZona.rojo)
          .toList();
      expect(rojas, hasLength(2));

      for (final zona in rojas) {
        completarZona(tablero, zona);
      }

      expect(tablero.puntuacionPorTipo(TipoZona.rojo), 12);
      expect(tablero.zonasCompletadasPorTipo(TipoZona.rojo), 2);
      expect(tablero.puntuacionTotal, 12);
    });

    test('El total es la suma de las puntuaciones por color', () {
      final tablero = mapaUno.crearTablero();
      completarZona(tablero, primeraZona(tablero, TipoZona.azul));
      completarZona(tablero, primeraZona(tablero, TipoZona.amarillo));
      completarZona(tablero, primeraZona(tablero, TipoZona.morado));

      final suma = TipoZona.values
          .map(tablero.puntuacionPorTipo)
          .fold(0, (total, puntos) => total + puntos);

      expect(tablero.puntuacionTotal, 7 + 8 + 6);
      expect(tablero.puntuacionTotal, suma);
    });
  });

  group('Puntuación máxima del tablero', () {
    test('El Mapa 1 puede dar hasta 54 puntos', () {
      expect(mapaUno.crearTablero().puntuacionMaxima, 54);
    });

    test('El Mapa 2 puede dar hasta 55 puntos', () {
      expect(mapaDos.crearTablero().puntuacionMaxima, 55);
    });

    test('Un tablero sin zonas tiene máximo 0', () {
      expect(Tablero().puntuacionMaxima, 0);
    });

    test('Es la suma de los puntos de todas sus zonas', () {
      final tablero = mapaDos.crearTablero();
      var suma = 0;
      for (final zona in tablero.regiones) {
        suma += zona.tipo.puntuacion;
      }

      expect(tablero.puntuacionMaxima, suma);
    });

    test('No cambia al ir colocando números', () {
      final tablero = mapaUno.crearTablero();
      final azul = primeraZona(tablero, TipoZona.azul);

      completarZona(tablero, azul);

      expect(tablero.puntuacionTotal, 7);
      expect(tablero.puntuacionMaxima, 54);
    });

    test('Completar todo el Mapa 1 llega justo al máximo', () {
      final tablero = mapaUno.crearTablero();
      for (final zona in tablero.regiones) {
        completarZona(tablero, zona);
      }

      expect(tablero.puntuacionTotal, tablero.puntuacionMaxima);
    });
  });
}
