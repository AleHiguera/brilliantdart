// Prueba unitaria: el cliente del teléfono se conecta a un servidor HTTPS de
// verdad solo si su certificado es el esperado, y si no, da un error de
// conexión normal en vez de romper la app.

import 'dart:io';

import 'package:brilliant_mobile/cliente_http.dart';
import 'package:brilliant_mobile/cliente_http_nativo.dart';
import 'package:brilliant_mobile/huella_certificado.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:http/testing.dart';

void main() {
  group('Cliente del teléfono', () {
    late HttpServer servidor;
    late Uri direccion;
    final certificado = File('test/datos/prueba.cer').readAsBytesSync();

    setUp(() async {
      // Un servidor HTTPS con un certificado casero, solo para la prueba.
      final contexto = SecurityContext()
        ..useCertificateChain('test/datos/prueba.p12', password: 'prueba')
        ..usePrivateKey('test/datos/prueba.p12', password: 'prueba');
      servidor = await HttpServer.bindSecure('localhost', 0, contexto);
      servidor.listen(
        (peticion) => peticion.response
          ..write('{"ok":true}')
          ..close(),
      );
      direccion = Uri.parse('https://localhost:${servidor.port}/api/latido');
    });

    tearDown(() => servidor.close(force: true));

    http.Client clienteCon(String huella) => ClienteSeguro(
      IOClient(clienteQueConfiaEn(ConfianzaCertificado(huella))),
    );

    test('Con la huella del certificado, se conecta', () async {
      final cliente = clienteCon(ConfianzaCertificado.huellaDe(certificado));
      addTearDown(cliente.close);

      final respuesta = await cliente.post(direccion);

      expect(respuesta.statusCode, 200);
      expect(respuesta.body, '{"ok":true}');
    });

    test('Con otra huella no se conecta y da un error de conexión', () async {
      final cliente = clienteCon(huellaServidor);
      addTearDown(cliente.close);

      await expectLater(
        cliente.post(direccion),
        throwsA(
          isA<http.ClientException>().having(
            (e) => e.message,
            'mensaje',
            ClienteSeguro.certificadoAjeno,
          ),
        ),
      );
    });

    test('El cliente de la app es el seguro', () {
      final cliente = crearClienteHttp();
      addTearDown(cliente.close);

      expect(cliente, isA<ClienteSeguro>());
    });
  });

  group('Cliente seguro', () {
    test('Los demás errores pasan sin cambiar', () async {
      final cliente = ClienteSeguro(
        MockClient((_) async => throw http.ClientException('Sin red')),
      );

      await expectLater(
        cliente.post(Uri.parse('https://servidor:8443/api/login')),
        throwsA(
          isA<http.ClientException>().having(
            (e) => e.message,
            'mensaje',
            'Sin red',
          ),
        ),
      );
    });

    test('Las respuestas llegan igual', () async {
      final cliente = ClienteSeguro(
        MockClient((_) async => http.Response('hola', 200)),
      );

      final respuesta = await cliente.get(Uri.parse('https://servidor/'));

      expect(respuesta.body, 'hola');
    });
  });
}
