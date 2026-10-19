// Prueba unitaria (no de widgets): no dibuja ninguna pantalla, solo revisa
// que cada sonido apunte al archivo correcto.

import 'package:brilliant_mobile/sonidos.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Unitarias: sonidos', () {
    test('SonidoAsset recuerda qué archivo debe sonar', () {
      expect(SonidoAsset(Sonido.dados).ruta, 'sonidos/dados.wav');
      expect(SonidoAsset(Sonido.victoria).ruta, 'sonidos/victoria.wav');
    });

    test('Las rutas de los sonidos están en la carpeta sonidos', () {
      expect(Sonido.dados, startsWith('sonidos/'));
      expect(Sonido.victoria, startsWith('sonidos/'));
    });

    test('Los dos sonidos son archivos .wav distintos', () {
      expect(Sonido.dados, endsWith('.wav'));
      expect(Sonido.victoria, endsWith('.wav'));
      expect(Sonido.dados, isNot(Sonido.victoria));
    });
  });
}
