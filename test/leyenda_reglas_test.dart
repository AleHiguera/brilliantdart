// Prueba unitaria: el signo que resume la regla de cada zona y qué reglas
// muestra cada mapa junto al tablero.

import 'package:brilliantdart/catalogo_mapas.dart';
import 'package:brilliantdart/leyenda_reglas.dart';
import 'package:brilliantdart/mapa_cuatro.dart';
import 'package:brilliantdart/tipoo.dart';
import 'package:test/test.dart';

/// La regla de ese color en el primer mapa que lo usa.
Tipo reglaDe(TipoZona tipo) => mapasDisponibles
    .firstWhere((mapa) => mapa.tiposPresentes.contains(tipo))
    .crearTipo(tipo);

List<(TipoZona, String)> resumen(List<ReglaVisible> reglas) => [
  for (final regla in reglas) (regla.tipo, regla.simbolo),
];

void main() {
  group('Signo de cada regla', () {
    final esperados = {
      TipoZona.amarillo: '≠',
      TipoZona.rojo: '≠',
      TipoZona.morado: 'XO',
      TipoZona.verde: '?',
      TipoZona.azul: '=',
      TipoZona.gris: '=',
    };

    for (final MapEntry(key: tipo, value: simbolo) in esperados.entries) {
      test('${tipo.name} lleva $simbolo', () {
        expect(LeyendaReglas.simboloDe(reglaDe(tipo)), simbolo);
      });
    }

    test('Un naranja lleva su rango', () {
      expect(
        LeyendaReglas.simboloDe(
          TipoNaranja(
            color: 'Naranja',
            regla: '',
            puntuacion: 6,
            minimo: 4,
            maximo: 6,
          ),
        ),
        '4-6',
      );
      expect(
        LeyendaReglas.simboloDe(
          TipoNaranja(
            color: 'Naranja',
            regla: '',
            puntuacion: 6,
            minimo: 1,
            maximo: 3,
          ),
        ),
        '1-3',
      );
    });

    test('Los signos siguen las reglas: mismo signo, misma regla', () {
      // Amarillo y rojo: no se repite ningún número.
      for (final tipo in [TipoZona.amarillo, TipoZona.rojo]) {
        final regla = reglaDe(tipo);
        expect(regla.validarMovimiento([1, 2, 3]), isTrue);
        expect(regla.validarMovimiento([1, 1]), isFalse);
      }
      // Azul y gris: todos iguales.
      for (final tipo in [TipoZona.azul, TipoZona.gris]) {
        final regla = reglaDe(tipo);
        expect(regla.validarMovimiento([4, 4, 4]), isTrue);
        expect(regla.validarMovimiento([4, 5]), isFalse);
      }
    });
  });

  group('Reglas de cada mapa', () {
    test(
      'El Mapa 4 muestra el naranja de arriba (4-6) y el de abajo (1-3)',
      () {
        final naranjas = LeyendaReglas(
          mapaCuatro,
        ).reglas.where((regla) => regla.tipo == TipoZona.naranja);

        expect(naranjas.map((regla) => regla.simbolo), ['4-6', '1-3']);
      },
    );

    for (final mapa in mapasDisponibles) {
      group('Mapa ${mapa.numero}', () {
        final reglas = LeyendaReglas(mapa).reglas;

        test('Aparece cada color del mapa y ninguno más', () {
          expect(
            reglas.map((regla) => regla.tipo).toSet(),
            mapa.tiposPresentes.toSet(),
          );
        });

        test('Va en el orden amarillo, rojo, morado, verde, azul, gris, '
            'naranja', () {
          final posiciones = [
            for (final regla in reglas) LeyendaReglas.orden.indexOf(regla.tipo),
          ];
          expect(posiciones, [...posiciones]..sort());
        });

        test('Ninguna regla se repite', () {
          expect(resumen(reglas).toSet(), hasLength(reglas.length));
        });

        test('Solo los naranjas pueden salir más de una vez', () {
          for (final tipo in mapa.tiposPresentes) {
            if (tipo == TipoZona.naranja) continue;
            expect(
              reglas.where((regla) => regla.tipo == tipo),
              hasLength(1),
              reason: tipo.name,
            );
          }
        });

        test('Cada regla trae su explicación', () {
          for (final regla in reglas) {
            expect(regla.regla, isNotEmpty, reason: regla.tipo.name);
          }
        });
      });
    }
  });
}
