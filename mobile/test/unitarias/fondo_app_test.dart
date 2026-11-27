// Prueba unitaria: la imagen de fondo de la app y los colores que la dejan
// ver sin perder lo legible.

import 'package:brilliant_mobile/fondo_app.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Unitarias: imagen de fondo', () {
    test('La imagen viene dentro de la app', () async {
      final datos = await rootBundle.load(imagenFondo);
      expect(datos.lengthInBytes, greaterThan(0));
    });

    test('Es un JPG', () async {
      final bytes = (await rootBundle.load(imagenFondo)).buffer.asUint8List();
      expect(bytes.sublist(0, 3), [0xFF, 0xD8, 0xFF]);
    });

    test('Pesa menos de 1 MB para no hacer lenta la app', () async {
      final datos = await rootBundle.load(imagenFondo);
      expect(datos.lengthInBytes, lessThan(1024 * 1024));
    });

    test('Está en la carpeta de imágenes declarada en pubspec', () {
      expect(imagenFondo, startsWith('assets/imagenes/'));
    });
  });

  group('Unitarias: velo y colores sobre el fondo', () {
    test('El velo es blanco', () {
      for (final color in veloFondo.colors) {
        expect((color.r, color.g, color.b), (1.0, 1.0, 1.0));
      }
    });

    test('El velo deja ver la imagen: nunca la tapa más del 60 %', () {
      for (final color in veloFondo.colors) {
        expect(color.a, lessThanOrEqualTo(0.6));
      }
    });

    test('El velo aclara lo suficiente para leer: al menos 20 %', () {
      for (final color in veloFondo.colors) {
        expect(color.a, greaterThanOrEqualTo(0.2));
      }
    });

    test('Más claro arriba (donde hay texto) que abajo', () {
      expect(veloFondo.colors.first.a, greaterThan(veloFondo.colors.last.a));
    });

    test('Los campos de texto son blancos y casi opacos', () {
      expect(rellenoCampo.a, greaterThan(0.9));
    });

    test('Las pastillas de texto suelto son blancas y redondeadas', () {
      final pastilla = decoracionPastilla();
      expect(pastilla.color!.a, greaterThan(0.8));
      expect(pastilla.borderRadius, isNotNull);
    });
  });
}
