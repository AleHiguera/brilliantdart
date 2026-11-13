// Prueba unitaria: la app recuerda el servidor con el que se entró, porque
// en el teléfono no hay página de la que tomarlo.

import 'dart:convert';

import 'package:brilliant_mobile/almacen_pestana.dart';
import 'package:brilliant_mobile/servicio_auth.dart';
import 'package:brilliant_mobile/servidor_recordado.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('Servidor recordado', () {
    test('Sin nada guardado no hay servidor', () {
      expect(ServidorRecordado(AlmacenEnMemoria()).leer(), isNull);
    });

    test('Lo guardado se lee igual, sin espacios', () {
      final almacen = AlmacenEnMemoria();
      ServidorRecordado(almacen).guardar(' https://pc:8443 ');

      expect(ServidorRecordado(almacen).leer(), 'https://pc:8443');
    });

    test('Un texto vacío es como no tener nada', () {
      final almacen = AlmacenEnMemoria()
        ..guardar(ServidorRecordado.clave, '  ');

      expect(ServidorRecordado(almacen).leer(), isNull);
    });
  });

  group('La sesión y el servidor recordado', () {
    late AlmacenPestana preferencias;
    late bool loginFalla;

    setUp(() {
      preferencias = AlmacenEnMemoria();
      loginFalla = false;
    });

    ServicioAuth abrir({String? servidor}) => ServicioAuth(
      servidor: servidor,
      preferencias: preferencias,
      cliente: MockClient((_) async {
        if (loginFalla) {
          return http.Response(
            jsonEncode({'ok': false, 'mensaje': 'PIN incorrecto.'}),
            401,
          );
        }
        return http.Response(
          jsonEncode({
            'ok': true,
            'usuario': 'ana',
            'nombre': 'Ana',
            'token': 'abc',
          }),
          200,
        );
      }),
    );

    test('Sin recordado, usa el de siempre', () {
      expect(abrir().servidor, servidorPorDefecto());
    });

    test('Al entrar se recuerda el servidor y se usa la próxima vez', () async {
      final auth = abrir()..servidor = 'https://192.168.1.129:8443';

      await auth.iniciarSesion('ana', '1234');

      expect(abrir().servidor, 'https://192.168.1.129:8443');
    });

    test('Si no se pudo entrar, no se recuerda', () async {
      loginFalla = true;
      final auth = abrir()..servidor = 'https://equivocado:8443';

      await expectLater(
        auth.iniciarSesion('ana', '0000'),
        throwsA(isA<ErrorAuth>()),
      );

      expect(abrir().servidor, servidorPorDefecto());
    });

    test('Al registrarse también se recuerda', () async {
      final auth = abrir()..servidor = 'https://pc:8443';

      await auth.registrar(
        usuario: 'ana',
        nombre: 'Ana',
        correo: 'ana@correo.com',
        pin: '1234',
      );

      expect(abrir().servidor, 'https://pc:8443');
    });

    test('El servidor indicado gana al recordado', () async {
      await (abrir()..servidor = 'https://pc:8443').iniciarSesion('ana', '1');

      expect(
        abrir(servidor: 'https://otro:8443').servidor,
        'https://otro:8443',
      );
    });
  });

  group('Mensaje sin conexión', () {
    test('En el navegador explica lo del certificado', () {
      expect(
        mensajeSinConectar('https://pc:8443', enNavegador: true),
        allOf(contains('https://pc:8443'), contains('acepta el certificado')),
      );
    });

    test('En el teléfono habla de la red y la dirección, no del navegador', () {
      final mensaje = mensajeSinConectar('https://pc:8443', enNavegador: false);

      expect(mensaje, contains('https://pc:8443'));
      expect(mensaje, contains('misma red Wi-Fi'));
      expect(mensaje, isNot(contains('navegador')));
    });
  });
}
