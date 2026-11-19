import 'package:test/test.dart';

import 'package:brilliantdart/mapa_uno.dart';
import 'package:brilliantdart/tablero_texto.dart';

void main() {
  group('Tablero como texto', () {
    test('Un tablero vacío son 49 ceros', () {
      expect(TableroTexto.escribir(mapaUno.crearTablero()), '0' * 49);
    });

    test('Cada número va en su lugar, fila por fila', () {
      final tablero = mapaUno.crearTablero()
        ..colocarDato(0, 0, 3)
        ..colocarDato(0, 6, 5)
        ..colocarDato(1, 0, 1)
        ..colocarDato(6, 6, 6);

      final texto = TableroTexto.escribir(tablero);

      expect(texto, hasLength(49));
      expect(texto[0], '3');
      expect(texto[6], '5');
      expect(texto[7], '1');
      expect(texto[48], '6');
      expect(texto.replaceAll('0', ''), '3516');
    });

    test('Leer devuelve los números y null en las vacías', () {
      final numeros = TableroTexto.leer('3${'0' * 47}6')!;

      expect(numeros, hasLength(49));
      expect(numeros.first, 3);
      expect(numeros.last, 6);
      expect(numeros.sublist(1, 48), everyElement(isNull));
    });

    test('Escribir y leer da lo mismo que tenía el tablero', () {
      final tablero = mapaUno.crearTablero();
      for (var i = 0; i < 49; i += 5) {
        tablero.colocarDato(i ~/ 7, i % 7, i % 6 + 1);
      }

      final numeros = TableroTexto.leer(TableroTexto.escribir(tablero))!;

      for (var i = 0; i < 49; i++) {
        expect(numeros[i], tablero.obtenerCelda(i ~/ 7, i % 7).valor);
      }
    });

    test('Un texto de otro largo o con otros signos no es un tablero', () {
      expect(TableroTexto.leer('0' * 48), isNull);
      expect(TableroTexto.leer('0' * 50), isNull);
      expect(TableroTexto.leer('7${'0' * 48}'), isNull);
      expect(TableroTexto.leer('a${'0' * 48}'), isNull);
      expect(TableroTexto.leer('-${'0' * 48}'), isNull);
    });
  });
}
