// Prueba unitaria: en el teléfono solo se confía en el certificado cuya
// huella SHA-256 es la del servidor.

import 'dart:convert';
import 'dart:io';

import 'package:brilliant_mobile/huella_certificado.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Huella del certificado', () {
    // El certificado público del servidor (sin su llave privada).
    final servidor = File('test/datos/servidor.cer').readAsBytesSync();
    final otro = File('test/datos/prueba.cer').readAsBytesSync();

    test('Calcula la huella en el formato que imprime el servidor', () {
      expect(
        ConfianzaCertificado.huellaDe(utf8.encode('abc')),
        'BA:78:16:BF:8F:01:CF:EA:41:41:40:DE:5D:AE:22:23:'
        'B0:03:61:A3:96:17:7A:9C:B4:10:FF:61:F2:00:15:AD',
      );
    });

    test('La huella de fábrica es la del certificado del servidor', () {
      expect(ConfianzaCertificado.huellaDe(servidor), huellaServidor);
      expect(ConfianzaCertificado().acepta(servidor), isTrue);
    });

    test('No acepta otro certificado', () {
      expect(ConfianzaCertificado().acepta(otro), isFalse);
    });

    test('Acepta la huella en minúsculas, sin dos puntos o con espacios', () {
      final huella = ConfianzaCertificado.huellaDe(otro);

      expect(
        ConfianzaCertificado(
          huella.replaceAll(':', '').toLowerCase(),
        ).acepta(otro),
        isTrue,
      );
      expect(
        ConfianzaCertificado(huella.replaceAll(':', ' ')).acepta(otro),
        isTrue,
      );
    });

    test('Sin huella no acepta ningún certificado', () {
      expect(ConfianzaCertificado('').acepta(servidor), isFalse);
    });
  });
}
