import 'package:test/test.dart';

import 'package:brilliantdart/tipoo.dart';
import 'package:brilliantdart/zona.dart';

void main() {
  Zona crearZona(TipoZona tipo, List<int?> valores) {
    return Zona(
      id: 1,
      tipo: Tipo(tipo: tipo, color: tipo.name, regla: '', puntuacion: 1),
      coordenadas: [
        for (var i = 0; i < valores.length; i++)
          Coordenada(fila: 0, columna: i, valor: valores[i]),
      ],
    );
  }

  group('Region: colocar números', () {
    test('obtenerValores ignora las celdas vacías', () {
      final zona = crearZona(TipoZona.verde, [3, null, 5, null]);

      expect(zona.obtenerValores(), [3, 5]);
    });

    test('No permite colocar en una celda que no es de la zona', () {
      final zona = crearZona(TipoZona.verde, [null, null]);

      expect(zona.puedeColocarNumero(4, 4, 1), isFalse);
    });

    test('No permite colocar en una celda ocupada', () {
      final zona = crearZona(TipoZona.verde, [2, null]);

      expect(zona.puedeColocarNumero(0, 0, 1), isFalse);
      expect(zona.puedeColocarNumero(0, 1, 1), isTrue);
    });

    test('Respeta la regla del color mientras quedan celdas libres', () {
      final rojo = crearZona(TipoZona.rojo, [2, null, null]);

      expect(rojo.puedeColocarNumero(0, 1, 2), isFalse);
      expect(rojo.puedeColocarNumero(0, 1, 3), isTrue);
    });

    test('La última celda morada no puede dejar un solo número', () {
      final morado = crearZona(TipoZona.morado, [3, 3, null]);

      expect(morado.puedeColocarNumero(0, 2, 3), isFalse);
      expect(morado.puedeColocarNumero(0, 2, 4), isTrue);
    });

    test('Una celda morada intermedia sí puede repetir el número', () {
      final morado = crearZona(TipoZona.morado, [3, null, null]);

      expect(morado.puedeColocarNumero(0, 1, 3), isTrue);
    });

    test('colocarNumero falla si la celda no pertenece a la zona', () {
      final zona = crearZona(TipoZona.verde, [null]);

      expect(() => zona.colocarNumero(5, 5, 1), throwsException);
    });
  });

  group('Region: zona completada', () {
    test('No está completa mientras quede una celda vacía', () {
      final zona = crearZona(TipoZona.verde, [1, null]);

      expect(zona.verificarCompletado(), isFalse);
      expect(zona.completado, isFalse);
    });

    test('Se completa al llenarla y deja de estarlo al vaciar una celda', () {
      final zona = crearZona(TipoZona.azul, [4, null]);

      zona.colocarNumero(0, 1, 4);
      expect(zona.verificarCompletado(), isTrue);
      expect(zona.completado, isTrue);

      zona.coordenadas.first.valor = null;
      expect(zona.verificarCompletado(), isFalse);
      expect(zona.completado, isFalse);
    });

    test('Una zona llena que rompe su regla no está completa', () {
      final zona = crearZona(TipoZona.rojo, [1, 1]);

      expect(zona.verificarCompletado(), isFalse);
      expect(zona.validarMovimiento(), isFalse);
    });

    test('Las coordenadas de la zona no se pueden modificar desde fuera', () {
      final zona = crearZona(TipoZona.verde, [1]);

      expect(
        () => zona.coordenadas.add(Coordenada.xy(1, 1)),
        throwsUnsupportedError,
      );
    });
  });
}
