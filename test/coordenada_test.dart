import 'package:test/test.dart';

import 'package:brilliantdart/region.dart';

void main() {
  group('Coordenada', () {
    test('El constructor con nombres guarda fila y columna', () {
      final celda = Coordenada(fila: 2, columna: 5);

      expect(celda.fila, 2);
      expect(celda.columna, 5);
    });

    test('fila es lo mismo que x y columna lo mismo que y', () {
      final celda = Coordenada(fila: 4, columna: 1);

      expect(celda.x, celda.fila);
      expect(celda.y, celda.columna);
    });

    test('El constructor xy guarda x e y', () {
      final celda = Coordenada.xy(6, 3);

      expect(celda.x, 6);
      expect(celda.y, 3);
      expect(celda.fila, 6);
      expect(celda.columna, 3);
    });

    test('Una celda nueva empieza vacía', () {
      expect(Coordenada(fila: 0, columna: 0).valor, isNull);
      expect(Coordenada.xy(0, 0).valor, isNull);
    });

    test('Se puede crear con un valor inicial', () {
      expect(Coordenada(fila: 0, columna: 0, valor: 4).valor, 4);
      expect(Coordenada.xy(1, 1, valor: 6).valor, 6);
    });

    test('El valor se puede cambiar', () {
      final celda = Coordenada.xy(0, 0);

      celda.valor = 3;
      expect(celda.valor, 3);

      celda.valor = 5;
      expect(celda.valor, 5);
    });

    test('El valor se puede borrar', () {
      final celda = Coordenada.xy(0, 0, valor: 2);

      celda.valor = null;

      expect(celda.valor, isNull);
    });

    test('Cambiar una celda no cambia otra con la misma posición', () {
      final primera = Coordenada.xy(3, 3);
      final segunda = Coordenada.xy(3, 3);

      primera.valor = 1;

      expect(segunda.valor, isNull);
    });

    for (var valor = 1; valor <= 6; valor++) {
      test('Puede guardar el número $valor', () {
        expect(Coordenada.xy(0, 0, valor: valor).valor, valor);
      });
    }
  });
}
