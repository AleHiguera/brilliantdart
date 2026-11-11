// Prueba unitaria: la sesión se cierra sola cuando las peticiones dejan de
// llegar al servidor, y al volver a entrar se cierra la sesión vieja.

import 'dart:convert';

import 'package:brilliant_mobile/servicio_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Servidor falso que se puede desconectar a voluntad.
class RedFalsa {
  bool sinRed = false;
  int codigoLatido = 200;
  final List<String> peticiones = [];

  late final ServicioAuth auth = ServicioAuth(
    servidor: 'https://servidor:8443',
    cliente: MockClient((peticion) async {
      if (sinRed) throw http.ClientException('Sin red');
      final ruta = peticion.url.path;
      final token = peticion.headers['Authorization'];
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
        'token': 'nuevo',
      }, 200);
    }),
  )..sesion = const Sesion(usuario: 'ana', nombre: 'Ana', token: 'viejo');

  Future<void> latidos(int cantidad) async {
    for (var i = 0; i < cantidad; i++) {
      await auth.mantenerSesion();
    }
  }
}

http.Response _json(Map<String, Object> datos, int codigo) =>
    http.Response.bytes(utf8.encode(jsonEncode(datos)), codigo);

void main() {
  group('Desconexión por red', () {
    test('Dos fallos seguidos todavía no cierran la sesión', () async {
      final red = RedFalsa()..sinRed = true;

      await red.latidos(2);

      expect(red.auth.sesion, isNotNull);
      expect(red.auth.desconexion.value, isNull);
    });

    test('Al tercer fallo seguido se cierra la sesión y se avisa', () async {
      final red = RedFalsa()..sinRed = true;

      await red.latidos(3);

      expect(red.auth.sesion, isNull);
      expect(red.auth.desconexion.value, isNotNull);
      expect(red.auth.desconexion.value!.abandonoPartida, isFalse);
    });

    test('La desconexión se avisa una sola vez', () async {
      final red = RedFalsa()..sinRed = true;
      var avisos = 0;
      red.auth.desconexion.addListener(() => avisos++);

      await red.latidos(6);

      expect(avisos, 1);
    });

    test('Si la red vuelve entre fallos, la cuenta empieza de nuevo', () async {
      final red = RedFalsa()..sinRed = true;

      await red.latidos(2);
      red.sinRed = false;
      await red.latidos(1);
      red.sinRed = true;
      await red.latidos(2);

      expect(red.auth.sesion, isNotNull);
    });

    test('Un rechazo del servidor no es un fallo de red', () async {
      final red = RedFalsa()..codigoLatido = 503;

      await red.latidos(5);

      expect(red.auth.sesion, isNotNull);
      expect(red.auth.conexion.fallando, isFalse);
    });

    test(
      'Cualquier petición de la sesión cuenta, no solo los latidos',
      () async {
        final red = RedFalsa()..sinRed = true;

        for (var i = 0; i < 3; i++) {
          await expectLater(
            red.auth.enviarConSesion('partida/estado', {'codigo': 'ABC234'}),
            throwsA(isA<ErrorAuth>()),
          );
        }

        expect(red.auth.sesion, isNull);
      },
    );

    test('Con sesión el error ya no habla del certificado', () async {
      final red = RedFalsa()..sinRed = true;

      await expectLater(
        red.auth.enviarConSesion('partida/estado', {'codigo': 'ABC234'}),
        throwsA(
          isA<ErrorAuth>().having(
            (e) => e.mensaje,
            'mensaje',
            'Se perdió la conexión con el servidor.',
          ),
        ),
      );
    });

    test(
      'Sin sesión, como al iniciarla, se explica lo del certificado',
      () async {
        final red = RedFalsa()
          ..auth.sesion = null
          ..sinRed = true;

        await expectLater(
          red.auth.iniciarSesion('ana', '1234'),
          throwsA(
            isA<ErrorAuth>().having(
              (e) => e.mensaje,
              'mensaje',
              contains('acepta el certificado'),
            ),
          ),
        );
      },
    );

    test('Los fallos sin sesión no cuentan para desconectar', () async {
      final red = RedFalsa()
        ..auth.sesion = null
        ..sinRed = true;

      for (var i = 0; i < 3; i++) {
        await expectLater(
          red.auth.iniciarSesion('ana', '1234'),
          throwsA(isA<ErrorAuth>()),
        );
      }

      expect(red.auth.desconexion.value, isNull);
      expect(red.auth.conexion.fallando, isFalse);
    });

    test('Perder la conexión en plena partida cuenta como abandono', () async {
      final red = RedFalsa()..auth.partidaEnCurso = 'ABC234';
      red.sinRed = true;

      await red.latidos(3);

      expect(red.auth.desconexion.value!.abandonoPartida, isTrue);
      expect(red.auth.partidaEnCurso, isNull);
    });

    test('Cerrar sesión deja de estar en partida', () async {
      final red = RedFalsa()..auth.partidaEnCurso = 'ABC234';

      await red.auth.cerrarSesion();

      expect(red.auth.partidaEnCurso, isNull);
    });
  });

  group('Volver a entrar tras desconectarse', () {
    Future<RedFalsa> desconectada() async {
      final red = RedFalsa()..sinRed = true;
      await red.latidos(3);
      red.sinRed = false;
      return red;
    }

    test('Primero cierra la sesión vieja y después entra', () async {
      final red = await desconectada();

      await red.auth.iniciarSesion('ana', '1234');

      expect(red.peticiones, ['/api/logout Bearer viejo', '/api/login']);
      expect(red.auth.sesion?.token, 'nuevo');
    });

    test('Al entrar de nuevo se olvida la desconexión', () async {
      final red = await desconectada();

      await red.auth.iniciarSesion('ana', '1234');

      expect(red.auth.desconexion.value, isNull);
      expect(red.auth.conexion.fallando, isFalse);
    });

    test('La sesión vieja se cierra una sola vez', () async {
      final red = await desconectada();

      await red.auth.iniciarSesion('ana', '1234');
      await red.auth.cerrarSesion();
      await red.auth.iniciarSesion('ana', '1234');

      expect(
        red.peticiones.where((p) => p == '/api/logout Bearer viejo'),
        hasLength(1),
      );
    });

    test('Registrar una cuenta también cierra la sesión vieja', () async {
      final red = await desconectada();

      await red.auth.registrar(
        usuario: 'eva',
        nombre: 'Eva',
        correo: 'eva@correo.com',
        pin: '1234',
      );

      expect(red.peticiones.first, '/api/logout Bearer viejo');
    });

    test('Quien nunca se desconectó entra sin cerrar nada', () async {
      final red = RedFalsa()..auth.sesion = null;

      await red.auth.iniciarSesion('ana', '1234');

      expect(red.peticiones, ['/api/login']);
    });
  });

  group('Mensaje de la desconexión', () {
    test('Sin partida dice que se desconectó, sin hablar de abandono', () {
      const desconexion = Desconexion(abandonoPartida: false);

      expect(desconexion.mensaje, startsWith('Te desconectaste del servidor.'));
      expect(desconexion.mensaje, isNot(contains('abandono')));
    });

    test('En partida dice que cuenta como abandono', () {
      const desconexion = Desconexion(abandonoPartida: true);

      expect(desconexion.mensaje, startsWith('Te desconectaste del servidor'));
      expect(desconexion.mensaje, contains('cuenta como abandono'));
    });
  });
}
