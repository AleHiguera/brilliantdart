import 'package:test/test.dart';

import 'package:brilliantdart/catalogo_mapas.dart';
import 'package:brilliantdart/marcas_zonas.dart';
import 'package:brilliantdart/mapa_cuatro.dart';
import 'package:brilliantdart/mapa_tres.dart';
import 'package:brilliantdart/mapa_uno.dart';
import 'package:brilliantdart/nombres_zonas.dart';
import 'package:brilliantdart/tipoo.dart';

void main() {
  MarcaZona marca(MarcasZonas marcas, String texto) =>
      marcas.marcas.singleWhere((m) => m.texto == texto);

  group('Pedazos de una zona', () {
    for (final mapa in mapasDisponibles) {
      test('Mapa ${mapa.numero}: los pedazos cubren la zona sin repetir', () {
        for (final region in mapa.crearTablero().regiones) {
          final pedazos = MarcasZonas.pedazosDe(region);
          final celdas = [for (final pedazo in pedazos) ...pedazo];

          expect(celdas.toSet(), {
            for (final c in region.coordenadas) (c.x, c.y),
          });
          expect(celdas, hasLength(region.coordenadas.length));
        }
      });

      test('Mapa ${mapa.numero}: cada pedazo está unido y no toca a otro', () {
        bool vecinas((int, int) a, (int, int) b) =>
            (a.$1 - b.$1).abs() + (a.$2 - b.$2).abs() == 1;

        for (final region in mapa.crearTablero().regiones) {
          final pedazos = MarcasZonas.pedazosDe(region);
          for (final pedazo in pedazos) {
            // Se recorre desde la primera celda y se llega a todas.
            final alcanzadas = {pedazo.first};
            var crecio = true;
            while (crecio) {
              crecio = false;
              for (final celda in pedazo) {
                if (!alcanzadas.contains(celda) &&
                    alcanzadas.any((otra) => vecinas(celda, otra))) {
                  alcanzadas.add(celda);
                  crecio = true;
                }
              }
            }
            expect(alcanzadas, hasLength(pedazo.length));
          }
          for (final (i, uno) in pedazos.indexed) {
            for (final otro in pedazos.skip(i + 1)) {
              expect(uno.any((a) => otro.any((b) => vecinas(a, b))), isFalse);
            }
          }
        }
      });
    }

    test('El pedazo empieza por su celda de más arriba a la izquierda', () {
      for (final mapa in mapasDisponibles) {
        for (final region in mapa.crearTablero().regiones) {
          for (final pedazo in MarcasZonas.pedazosDe(region)) {
            final ordenado = [...pedazo]
              ..sort((a, b) => a.$1 != b.$1 ? a.$1 - b.$1 : a.$2 - b.$2);
            expect(pedazo.first, ordenado.first);
          }
        }
      }
    });
  });

  group('Marcas en el tablero', () {
    test('Una zona partida lleva la misma marca en cada pedazo', () {
      final marcas = MarcasZonas(mapaUno);
      final amarilla = marca(marcas, 'A1');

      expect(amarilla.pedazos, 5);
      expect(amarilla.celdasMarca, hasLength(5));
      for (final (fila, columna) in amarilla.celdasMarca) {
        expect(marcas.marcaEn(fila, columna), 'A1');
      }
    });

    test('Dos zonas del mismo color llevan marcas distintas', () {
      final marcas = MarcasZonas(mapaUno);

      expect(marca(marcas, 'V1').zona, isNot(marca(marcas, 'V2').zona));
      expect(marca(marcas, 'R1').zona, isNot(marca(marcas, 'R2').zona));
    });

    test('Mapa 4: dos zonas rojas, cada una de dos pedazos', () {
      final marcas = MarcasZonas(mapaCuatro);
      final r1 = marca(marcas, 'R1');
      final r2 = marca(marcas, 'R2');

      expect(r1.pedazos, 2);
      expect(r2.pedazos, 2);
      expect(r1.zona, isNot(r2.zona));
    });

    test(
      'Los naranjas con reglas distintas llevan la flecha de la leyenda',
      () {
        final marcas = MarcasZonas(mapaCuatro);

        expect(
          marcas.marcas
              .where((m) => m.tipo == TipoZona.naranja)
              .map((m) => m.texto),
          ['N↑', 'N↓'],
        );
      },
    );

    test('El azul lleva Az para no confundirse con el amarillo', () {
      final textos = MarcasZonas(mapaUno).marcas.map((m) => m.texto);

      expect(textos, containsAll(['Az1', 'Az2', 'A1']));
    });

    test('Un color de un solo pedazo y una sola zona no lleva marca', () {
      for (final mapa in mapasDisponibles) {
        final marcas = MarcasZonas(mapa);
        final regiones = mapa.crearTablero().regiones;
        for (final region in regiones) {
          final delColor = regiones.where(
            (r) => r.tipo.tipo == region.tipo.tipo,
          );
          final sola =
              delColor.length == 1 && MarcasZonas.pedazosDe(region).length == 1;
          expect(
            marcas.marcas.any((m) => m.zona == region.id),
            !sola,
            reason: 'Mapa ${mapa.numero}, zona ${region.id}',
          );
        }
      }
    });

    test('El número de la marca es el mismo que en los avisos', () {
      for (final mapa in mapasDisponibles) {
        final marcas = MarcasZonas(mapa);
        final nombres = NombresZonas(mapa);
        for (final m in marcas.marcas) {
          final numero = m.texto.substring(
            MarcasZonas.iniciales[m.tipo]!.length,
          );
          final nombre = nombres.de(m.zona);
          switch (numero) {
            case '↑':
              expect(nombre, endsWith('de arriba'));
            case '↓':
              expect(nombre, endsWith('de abajo'));
            default:
              final variasDelColor =
                  marcas.marcas.where((o) => o.tipo == m.tipo).length > 1;
              if (variasDelColor) expect(nombre, endsWith(' $numero'));
          }
        }
      }
    });

    test('Cada celda sabe de qué zona es', () {
      final marcas = MarcasZonas(mapaUno);
      for (final region in mapaUno.crearTablero().regiones) {
        for (final celda in region.coordenadas) {
          expect(marcas.zonaEn(celda.x, celda.y), region.id);
        }
        expect(marcas.celdasDe(region.id), {
          for (final c in region.coordenadas) (c.x, c.y),
        });
      }
    });

    test('Una celda sin marca no devuelve nada', () {
      final marcas = MarcasZonas(mapaUno);
      final conMarca = {for (final m in marcas.marcas) ...m.celdasMarca};
      for (var fila = 0; fila < 7; fila++) {
        for (var columna = 0; columna < 7; columna++) {
          if (!conMarca.contains((fila, columna))) {
            expect(marcas.marcaEn(fila, columna), isNull);
          }
        }
      }
    });
  });

  group('Explicaciones', () {
    test('Una zona en pedazos: cuentan juntos', () {
      final explicacion = MarcasZonas(
        mapaUno,
      ).explicaciones.singleWhere((e) => e.tipo == TipoZona.amarillo);

      expect(explicacion.marcas, ['A1']);
      expect(
        explicacion.texto,
        'A1: una sola zona en 5 pedazos; cuentan juntos.',
      );
    });

    test('Varias zonas del color: puntúan aparte', () {
      final explicacion = MarcasZonas(
        mapaUno,
      ).explicaciones.singleWhere((e) => e.tipo == TipoZona.verde);

      expect(explicacion.marcas, ['V1', 'V2']);
      expect(
        explicacion.texto,
        'V1 y V2: 2 zonas distintas; cada una se llena y puntúa aparte.',
      );
    });

    test('Si además tienen pedazos, se dice cuántos', () {
      final explicacion = MarcasZonas(
        mapaCuatro,
      ).explicaciones.singleWhere((e) => e.tipo == TipoZona.rojo);

      expect(
        explicacion.texto,
        'R1 (2 pedazos) y R2 (2 pedazos): 2 zonas distintas; cada una se '
        'llena y puntúa aparte.',
      );
    });

    test('Van en el orden de los colores de la leyenda', () {
      final tipos = MarcasZonas(mapaTres).explicaciones.map((e) => e.tipo);

      expect(tipos, [
        TipoZona.amarillo,
        TipoZona.rojo,
        TipoZona.morado,
        TipoZona.gris,
      ]);
    });
  });

  group('Descripción de una zona resaltada', () {
    test('Zona en pedazos', () {
      final marcas = MarcasZonas(mapaUno);

      expect(
        marcas.descripcionDe(marca(marcas, 'A1').zona),
        'La zona amarilla: 5 pedazos que cuentan como una sola zona.',
      );
    });

    test('Zona con otra del mismo color', () {
      final marcas = MarcasZonas(mapaUno);

      expect(
        marcas.descripcionDe(marca(marcas, 'V2').zona),
        'La zona verde 2: hay 2 zonas de este color y cada una puntúa aparte.',
      );
    });

    test('Zona en pedazos con otra del mismo color', () {
      final marcas = MarcasZonas(mapaCuatro);

      expect(
        marcas.descripcionDe(marca(marcas, 'R1').zona),
        'La zona roja 1: 2 pedazos que cuentan como una sola zona; hay 2 '
        'zonas de este color y cada una puntúa aparte.',
      );
    });

    test('Zona de un solo pedazo y única de su color', () {
      final marcas = MarcasZonas(mapaTres);
      final region = mapaTres.crearTablero().regiones.firstWhere(
        (r) => !marcas.marcas.any((m) => m.zona == r.id),
      );

      expect(
        marcas.descripcionDe(region.id),
        matches(RegExp(r'^La zona \w+\.$')),
      );
    });
  });
}
