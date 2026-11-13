// Prueba unitaria: en el teléfono las preferencias se guardan en un archivo
// y siguen ahí al volver a abrir la app.

import 'dart:io';

import 'package:brilliant_mobile/almacen_archivo.dart';
import 'package:brilliant_mobile/almacen_pestana.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory carpeta;
  late File archivo;

  setUp(() {
    carpeta = Directory.systemTemp.createTempSync('brilliant_');
    archivo = File('${carpeta.path}/preferencias.json');
  });

  tearDown(() => carpeta.deleteSync(recursive: true));

  group('Almacén en archivo', () {
    test('Sin archivo empieza vacío', () {
      expect(AlmacenArchivo(archivo).leer('brilliant.silencio'), isNull);
    });

    test('Lo guardado sigue al volver a abrir la app', () {
      AlmacenArchivo(archivo).guardar('brilliant.silencio', 'si');

      expect(AlmacenArchivo(archivo).leer('brilliant.silencio'), 'si');
    });

    test('Lo borrado ya no está al volver a abrir', () {
      AlmacenArchivo(archivo)
        ..guardar('brilliant.silencio', 'si')
        ..guardar('brilliant.servidor', 'https://pc:8443')
        ..borrar('brilliant.silencio');

      final otra = AlmacenArchivo(archivo);
      expect(otra.leer('brilliant.silencio'), isNull);
      expect(otra.leer('brilliant.servidor'), 'https://pc:8443');
    });

    test('Un archivo dañado se toma como vacío', () {
      archivo.writeAsStringSync('{no es json');

      final almacen = AlmacenArchivo(archivo);
      expect(almacen.leer('brilliant.silencio'), isNull);

      almacen.guardar('brilliant.silencio', 'si');
      expect(AlmacenArchivo(archivo).leer('brilliant.silencio'), 'si');
    });

    test('Ignora lo que no sea texto', () {
      archivo.writeAsStringSync('{"a": 1, "b": "dos"}');

      final almacen = AlmacenArchivo(archivo);
      expect(almacen.leer('a'), isNull);
      expect(almacen.leer('b'), 'dos');
    });

    test('Crea la carpeta si no existe', () {
      final adentro = File('${carpeta.path}/nueva/preferencias.json');

      AlmacenArchivo(adentro).guardar('x', 'y');

      expect(adentro.existsSync(), isTrue);
    });
  });

  group('Almacén del teléfono', () {
    test(
      'Ya preparado, lo duradero es un archivo en la carpeta de la app',
      () async {
        await AlmacenPestana.preparar(carpeta.path);

        final duradero = AlmacenPestana.duradero();
        expect(duradero, isA<AlmacenArchivo>());
        duradero.guardar('brilliant.silencio', 'si');
        expect(AlmacenPestana.duradero().leer('brilliant.silencio'), 'si');
      },
    );

    test(
      'La sesión no se guarda en archivo: dura lo que la app abierta',
      () async {
        await AlmacenPestana.preparar(carpeta.path);

        expect(AlmacenPestana.deLaPestana(), isA<AlmacenEnMemoria>());
      },
    );
  });
}
