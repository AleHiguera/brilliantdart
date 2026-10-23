import 'package:test/test.dart';

import 'package:brilliantdart/dibujo_mapa.dart';
import 'package:brilliantdart/mapa_dos.dart';
import 'package:brilliantdart/mapa_tres.dart';
import 'package:brilliantdart/tipoo.dart';

void main() {
  group('Leer un dibujo de letras', () {
    test('Cada letra es un color', () {
      expect(letrasDeColores, {
        'M': TipoZona.morado,
        'G': TipoZona.gris,
        'V': TipoZona.verde,
        'A': TipoZona.amarillo,
        'R': TipoZona.rojo,
        'Z': TipoZona.azul,
      });
    });

    test('Hay una letra para cada uno de los 6 colores', () {
      expect(letrasDeColores.values.toSet(), TipoZona.values.toSet());
    });

    test('Traduce cada fila en colores', () {
      expect(leerDibujo(['MGV', 'ARZ']), [
        [TipoZona.morado, TipoZona.gris, TipoZona.verde],
        [TipoZona.amarillo, TipoZona.rojo, TipoZona.azul],
      ]);
    });

    test('Un dibujo vacío da una lista vacía', () {
      expect(leerDibujo([]), isEmpty);
    });

    test('Una letra desconocida es un error', () {
      expect(() => leerDibujo(['MMX']), throwsArgumentError);
      expect(() => leerDibujo(['m']), throwsArgumentError);
    });

    test('El resultado no se puede modificar', () {
      final colores = leerDibujo(['MG']);

      expect(() => colores.add([]), throwsUnsupportedError);
      expect(() => colores[0][0] = TipoZona.azul, throwsUnsupportedError);
    });

    test('Los mapas 2 y 3 usan las mismas letras', () {
      expect(MapaDos.letras, same(letrasDeColores));
      expect(mapaDos.tiposPorCelda, leerDibujo(MapaDos.dibujo));
      expect(mapaTres.tiposPorCelda, leerDibujo(MapaTres.dibujo));
    });
  });
}
