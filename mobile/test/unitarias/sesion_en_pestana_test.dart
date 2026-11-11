// Prueba unitaria: ServicioAuth guarda su sesión en la pestaña y la recupera
// al recargar la página (aquí, al crear otro ServicioAuth con el mismo
// almacén).

import 'dart:convert';

import 'package:brilliant_mobile/almacen_pestana.dart';
import 'package:brilliant_mobile/servicio_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class ServidorFalso {
  bool sinRed = false;
  int codigoLatido = 200;
  final List<String> peticiones = [];

  ServicioAuth abrir(AlmacenPestana almacen) => ServicioAuth(
    servidor: 'https://servidor:8443',
    almacen: almacen,
    cliente: MockClient((peticion) async {
      if (sinRed) throw http.ClientException('Sin red');
      final token = peticion.headers['Authorization'];
      final ruta = peticion.url.path;
      peticiones.add(token == null ? ruta : '$ruta $token');
      if (ruta == '/api/latido') {
        return _json({
          'ok': codigoLatido == 200,
          'mensaje': 'Latido.',
        }, codigoLatido);
      }
      return _json({
        'ok': true,
        'mensaje': 'Bien.',
        'usuario': 'ana',
        'nombre': 'Ana',
        'token': 'abc',
      }, 200);
    }),
  );
}

http.Response _json(Map<String, Object> datos, int codigo) =>
    http.Response.bytes(utf8.encode(jsonEncode(datos)), codigo);

void main() {
  group('Sesión en la pestaña', () {
    late AlmacenEnMemoria almacen;
    late ServidorFalso servidor;

    setUp(() {
      almacen = AlmacenEnMemoria();
      servidor = ServidorFalso();
    });

    test('Sin nada guardado se empieza sin sesión', () {
      expect(servidor.abrir(almacen).sesion, isNull);
    });

    test('Tras entrar, recargar recupera la misma sesión', () async {
      await servidor.abrir(almacen).iniciarSesion('ana', '1234');

      final recargada = servidor.abrir(almacen).sesion;

      expect(recargada?.usuario, 'ana');
      expect(recargada?.nombre, 'Ana');
      expect(recargada?.token, 'abc');
    });

    test('Registrarse también queda guardado', () async {
      await servidor
          .abrir(almacen)
          .registrar(
            usuario: 'ana',
            nombre: 'Ana',
            correo: 'ana@correo.com',
            pin: '1234',
          );

      expect(servidor.abrir(almacen).sesion?.token, 'abc');
    });

    test('Tras cerrar sesión, recargar ya no tiene sesión', () async {
      final auth = servidor.abrir(almacen);
      await auth.iniciarSesion('ana', '1234');

      await auth.cerrarSesion();

      expect(servidor.abrir(almacen).sesion, isNull);
    });

    test('Si el servidor rechaza la sesión, tampoco queda guardada', () async {
      final auth = servidor.abrir(almacen);
      await auth.iniciarSesion('ana', '1234');
      servidor.codigoLatido = 401;

      await auth.mantenerSesion();

      expect(servidor.abrir(almacen).sesion, isNull);
    });

    test('La partida en juego también se recupera', () async {
      final auth = servidor.abrir(almacen);
      await auth.iniciarSesion('ana', '1234');
      auth.partidaEnCurso = 'ABC234';

      expect(servidor.abrir(almacen).partidaEnCurso, 'ABC234');
    });

    test('Sin sesión no se recupera ninguna partida', () {
      almacen.guardar('brilliant.partida', 'ABC234');

      expect(servidor.abrir(almacen).partidaEnCurso, isNull);
    });

    test('Perder la sesión olvida la partida en juego', () async {
      final auth = servidor.abrir(almacen);
      await auth.iniciarSesion('ana', '1234');
      auth.partidaEnCurso = 'ABC234';

      auth.sesion = null;

      expect(auth.partidaEnCurso, isNull);
      expect(servidor.abrir(almacen).partidaEnCurso, isNull);
    });

    test('Sin conexión, la sesión se borra también de la pestaña', () async {
      final auth = servidor.abrir(almacen);
      await auth.iniciarSesion('ana', '1234');
      servidor.sinRed = true;

      for (var i = 0; i < 3; i++) {
        await auth.mantenerSesion();
      }

      expect(auth.desconexion.value, isNotNull);
      expect(servidor.abrir(almacen).sesion, isNull);
    });

    test('La sesión abandonada se cierra aunque se haya recargado', () async {
      final auth = servidor.abrir(almacen);
      await auth.iniciarSesion('ana', '1234');
      servidor.sinRed = true;
      for (var i = 0; i < 3; i++) {
        await auth.mantenerSesion();
      }
      servidor
        ..sinRed = false
        ..peticiones.clear();

      await servidor.abrir(almacen).iniciarSesion('ana', '1234');

      expect(servidor.peticiones, ['/api/logout Bearer abc', '/api/login']);
    });

    test('Una sesión guardada dañada no se usa', () {
      almacen.guardar('brilliant.sesion', '{"usuario": 3}');

      expect(servidor.abrir(almacen).sesion, isNull);
    });
  });
}
