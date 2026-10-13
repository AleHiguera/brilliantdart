import 'package:test/test.dart';

import 'package:brilliantdart/region.dart';
import 'package:brilliantdart/tipoo.dart';
import 'package:brilliantdart/zona.dart';

void main() {
  Tipo tipo(TipoZona color) =>
      Tipo(tipo: color, color: color.name, regla: '', puntuacion: 5);

  Zona zona(TipoZona color, List<int?> valores, {int id = 1}) => Zona(
        id: id,
        tipo: tipo(color),
        coordenadas: [
          for (var i = 0; i < valores.length; i++)
            Coordenada(fila: i ~/ 7, columna: i % 7, valor: valores[i]),
        ],
      );

  group('Zona: datos básicos', () {
    test('Guarda su id', () {
      expect(zona(TipoZona.verde, [null], id: 7).id, 7);
    });

    test('Guarda su tipo', () {
      expect(zona(TipoZona.rojo, [null]).tipo.tipo, TipoZona.rojo);
    });

    test('Empieza sin completar', () {
      expect(zona(TipoZona.verde, [null, null]).completado, isFalse);
    });

    test('tamanoZona y tamanoRegion valen lo mismo', () {
      final z = zona(TipoZona.verde, [null, null, null]);

      expect(z.tamanoZona, 3);
      expect(z.tamanoRegion, 3);
    });

    test('Es una Region', () {
      expect(zona(TipoZona.verde, [null]), isA<Region>());
    });

    test('Copia la lista de coordenadas que recibe', () {
      final celdas = [Coordenada.xy(0, 0)];
      final z = Zona(id: 1, tipo: tipo(TipoZona.verde), coordenadas: celdas);

      celdas.add(Coordenada.xy(0, 1));

      expect(z.tamanoRegion, 1);
    });

    test('Reconoce sus coordenadas y no las ajenas', () {
      final z = zona(TipoZona.verde, [null, null]);

      expect(z.contieneCoordenada(0, 0), isTrue);
      expect(z.contieneCoordenada(0, 1), isTrue);
      expect(z.contieneCoordenada(0, 2), isFalse);
      expect(z.contieneCoordenada(1, 0), isFalse);
    });

    test('obtenerValores de una zona vacía es una lista vacía', () {
      expect(zona(TipoZona.verde, [null, null]).obtenerValores(), isEmpty);
    });

    test('obtenerValores respeta el orden de las celdas', () {
      expect(zona(TipoZona.verde, [5, 1, 3]).obtenerValores(), [5, 1, 3]);
    });
  });

  group('Zona: colocar números', () {
    test('colocarNumero escribe en la celda indicada', () {
      final z = zona(TipoZona.verde, [null, null]);

      z.colocarNumero(0, 1, 4);

      expect(z.coordenadas[1].valor, 4);
      expect(z.coordenadas[0].valor, isNull);
    });

    test('colocarNumero puede reemplazar un número', () {
      final z = zona(TipoZona.verde, [2]);

      z.colocarNumero(0, 0, 6);

      expect(z.coordenadas.single.valor, 6);
    });

    test('Una zona de una celda se completa al poner un número', () {
      final z = zona(TipoZona.verde, [null]);

      z.colocarNumero(0, 0, 3);

      expect(z.verificarCompletado(), isTrue);
    });
  });

  group('Zona: completar según su color', () {
    final casos = <(TipoZona, List<int>, bool)>[
      (TipoZona.azul, [2, 2, 2], true),
      (TipoZona.azul, [2, 2, 3], false),
      (TipoZona.rojo, [1, 2, 3], true),
      (TipoZona.rojo, [1, 2, 2], false),
      (TipoZona.verde, [4, 4, 1], true),
      (TipoZona.morado, [1, 1, 2], true),
      (TipoZona.morado, [1, 1, 1], false),
      (TipoZona.morado, [1, 2, 3], false),
      (TipoZona.amarillo, [1, 2, 3], true),
    ];

    for (final (color, valores, esperado) in casos) {
      test('${color.name} con $valores ${esperado ? '' : 'no '}se completa',
          () {
        final z = zona(color, valores);

        expect(z.verificarCompletado(), esperado);
        expect(z.completado, esperado);
      });
    }

    test('verificarCompletado se puede llamar muchas veces', () {
      final z = zona(TipoZona.verde, [1, 2]);

      for (var i = 0; i < 5; i++) {
        expect(z.verificarCompletado(), isTrue);
      }
    });
  });
}
