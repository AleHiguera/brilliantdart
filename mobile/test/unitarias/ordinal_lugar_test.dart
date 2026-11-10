// Prueba unitaria (no de widgets): cómo se escribe cada lugar en la tabla de
// zonas y en la clasificación final.

import 'package:brilliant_mobile/tabla_puntos_partida.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Unitarias: cómo se escribe un lugar', () {
    test('Los tres lugares con puntos', () {
      expect(ordinalDeLugar(1), '1.º');
      expect(ordinalDeLugar(2), '2.º');
      expect(ordinalDeLugar(3), '3.er');
    });

    test('Los lugares sin puntos, hasta el sexto jugador', () {
      expect(ordinalDeLugar(4), '4.º');
      expect(ordinalDeLugar(5), '5.º');
      expect(ordinalDeLugar(6), '6.º');
    });

    test('Solo el tercero lleva «er»', () {
      for (final lugar in [1, 2, 4, 5, 6]) {
        expect(ordinalDeLugar(lugar), endsWith('.º'));
      }
    });
  });
}
