import 'dart:convert';
import 'dart:io';

import 'package:brilliant_mobile/servicio_auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('App en el mismo Chrome que el servidor', () {
    late Map<String, dynamic> configuracion;

    setUpAll(() {
      final launch = File('../.vscode/launch.json').readAsStringSync();
      final datos = jsonDecode(launch) as Map<String, dynamic>;
      configuracion = (datos['configurations'] as List).single;
    });

    test('No abre un Chrome aparte, que no confiaría en el certificado', () {
      expect(configuracion['deviceId'], 'web-server');
    });

    test('Se abre en localhost, el equipo donde corre el servidor', () {
      final argumentos = configuracion['args'] as List;
      final posicion = argumentos.indexOf('--web-hostname');

      expect(argumentos[posicion + 1], 'localhost');
    });

    test('Por defecto se conecta al puerto web del servidor local', () {
      expect(servidorPorDefecto(), 'https://localhost:$puertoServidorWeb');
    });
  });
}
