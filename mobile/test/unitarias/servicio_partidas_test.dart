// Prueba unitaria (no de widgets): no dibuja ninguna pantalla, solo revisa
// qué se envía al servidor de partidas y cómo se lee lo que responde.

import 'dart:convert';

import 'package:brilliant_mobile/servicio_auth.dart';
import 'package:brilliant_mobile/servicio_partidas.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const Map<String, Object> salaJson = {
  'ok': true,
  'mensaje': 'Sala.',
  'codigo': 'ABC234',
  'mapa': 2,
  'capacidad': 3,
  'anfitrion': 'ana',
  'jugadores': ['ana', 'luis'],
  'listos': ['luis'],
  'comenzada': false,
  'finalizados': ['luis'],
  'configurada': false,
  'miTablero': [3, 1, 2, 6, 5, 4],
  'ronda': 2,
  'dados': [5, 2],
  'jugaron': ['luis'],
  'zonas': {
    '3': {'ana': 1, 'luis': 2},
  },
  'meta': 26,
  'terminada': false,
  'ganadores': <String>[],
};

http.Response json(Map<String, Object> datos, int codigo) =>
    http.Response.bytes(utf8.encode(jsonEncode(datos)), codigo);

ServicioPartidas servicio(
  List<http.Request> peticiones, {
  http.Response? respuesta,
  bool conSesion = true,
}) {
  final auth = ServicioAuth(
    servidor: 'https://servidor:8443',
    cliente: MockClient((peticion) async {
      peticiones.add(peticion);
      return respuesta ?? json(salaJson, 200);
    }),
  );
  if (conSesion) {
    auth.sesion = const Sesion(usuario: 'ana', nombre: 'Ana', token: 'abc');
  }
  return ServicioPartidas(auth);
}

void main() {
  group('Unitarias: servicio de partidas', () {
    test('Lee la sala que responde el servidor', () async {
      final sala = await servicio([]).crear(mapa: 2, jugadores: 3);

      expect(sala.codigo, 'ABC234');
      expect(sala.mapa, 2);
      expect(sala.capacidad, 3);
      expect(sala.anfitrion, 'ana');
      expect(sala.jugadores, ['ana', 'luis']);
      expect(sala.listos, ['luis']);
      expect(sala.comenzada, isFalse);
      expect(sala.finalizados, ['luis']);
      expect(sala.configurada, isFalse);
      expect(sala.miTablero, [3, 1, 2, 6, 5, 4]);
      expect(sala.ronda, 2);
      expect(sala.dados, [5, 2]);
      expect(sala.jugaron, ['luis']);
      expect(sala.meta, 26);
      expect(sala.terminada, isFalse);
      expect(sala.ganadores, isEmpty);
      expect(sala.zonas, {
        3: {'ana': 1, 'luis': 2},
      });
    });

    test('Terminar el turno dice qué ronda se jugó', () async {
      final peticiones = <http.Request>[];

      await servicio(peticiones).terminarTurno('ABC234', 2, tableroLleno: true);

      expect(peticiones.single.url.path, '/api/partida/turno');
      expect(peticiones.single.bodyFields, {
        'codigo': 'ABC234',
        'ronda': '2',
        'lleno': 'true',
      });
    });

    test('Si completó una zona también se avisa cuál', () async {
      final peticiones = <http.Request>[];

      await servicio(
        peticiones,
      ).terminarTurno('ABC234', 2, tableroLleno: false, zonaCompletada: 7);

      expect(peticiones.single.bodyFields['zona'], '7');
    });

    test('Si no completó ninguna zona no se envía ese dato', () async {
      final peticiones = <http.Request>[];

      await servicio(
        peticiones,
      ).terminarTurno('ABC234', 2, tableroLleno: false);

      expect(peticiones.single.bodyFields.containsKey('zona'), isFalse);
    });

    test('Sin lanzar aún la sala llega sin dados', () async {
      final sala = await servicio(
        [],
        respuesta: json({...salaJson, 'ronda': 0, 'dados': <int>[]}, 200),
      ).consultar('ABC234');

      expect(sala.ronda, 0);
      expect(sala.dados, isEmpty);
    });

    test('Finalizar envía solo el código y los números, en su orden', () async {
      final peticiones = <http.Request>[];

      await servicio(peticiones).finalizarTablero('ABC234', [3, 1, 2, 6, 5, 4]);

      expect(peticiones.single.url.path, '/api/partida/finalizar');
      expect(peticiones.single.bodyFields, {
        'codigo': 'ABC234',
        'numeros': '3,1,2,6,5,4',
      });
      expect(peticiones.single.headers['Authorization'], 'Bearer abc');
    });

    test('Crear envía mapa, jugadores y el token de la sesión', () async {
      final peticiones = <http.Request>[];

      await servicio(peticiones).crear(mapa: 2, jugadores: 3);

      expect(peticiones.single.url.path, '/api/partida/crear');
      expect(peticiones.single.bodyFields, {'mapa': '2', 'jugadores': '3'});
      expect(peticiones.single.headers['Authorization'], 'Bearer abc');
    });

    test('Unirse quita los espacios que se copiaron con el código', () async {
      final peticiones = <http.Request>[];

      await servicio(peticiones).unirse('  ABC234 ');

      expect(peticiones.single.url.path, '/api/partida/unirse');
      expect(peticiones.single.bodyFields, {'codigo': 'ABC234'});
    });

    test('Marcarse listo y desmarcarse usan su propia acción', () async {
      final peticiones = <http.Request>[];
      final partidas = servicio(peticiones);

      await partidas.marcarListo('ABC234', listo: true);
      await partidas.marcarListo('ABC234', listo: false);

      expect(peticiones.map((p) => p.url.path), [
        '/api/partida/listo',
        '/api/partida/no-listo',
      ]);
      expect(peticiones.map((p) => p.bodyFields), [
        {'codigo': 'ABC234'},
        {'codigo': 'ABC234'},
      ]);
    });

    test('El último en confirmar recibe la sala ya comenzada', () async {
      final partidas = servicio(
        [],
        respuesta: json({
          ...salaJson,
          'listos': ['ana', 'luis'],
          'comenzada': true,
        }, 200),
      );

      final sala = await partidas.marcarListo('ABC234', listo: true);

      expect(sala.comenzada, isTrue);
      expect(sala.pendientes, 0);
    });

    test('Consultar y salir usan su propia acción', () async {
      final peticiones = <http.Request>[];
      final partidas = servicio(peticiones);

      await partidas.consultar('ABC234');
      await partidas.salir('ABC234');

      expect(peticiones.map((p) => p.url.path), [
        '/api/partida/estado',
        '/api/partida/salir',
      ]);
    });

    test('Un rechazo llega con el mensaje y el código del servidor', () async {
      final partidas = servicio(
        [],
        respuesta: json({
          'ok': false,
          'mensaje': 'La partida ya está llena.',
        }, 409),
      );

      await expectLater(
        partidas.unirse('ABC234'),
        throwsA(
          isA<ErrorAuth>()
              .having((e) => e.mensaje, 'mensaje', 'La partida ya está llena.')
              .having((e) => e.codigo, 'codigo', 409),
        ),
      );
    });

    test('Sin sesión no se envía nada', () async {
      final peticiones = <http.Request>[];

      await expectLater(
        servicio(peticiones, conSesion: false).consultar('ABC234'),
        throwsA(isA<ErrorAuth>().having((e) => e.codigo, 'codigo', 401)),
      );
      expect(peticiones, isEmpty);
    });

    test('Un mapa que la app no conoce llega como ErrorAuth', () async {
      final partidas = servicio(
        [],
        respuesta: json({...salaJson, 'mapa': 9}, 200),
      );

      await expectLater(
        partidas.unirse('ABC234'),
        throwsA(
          isA<ErrorAuth>().having(
            (e) => e.mensaje,
            'mensaje',
            'Esta partida usa un mapa que tu versión de la app no conoce.',
          ),
        ),
      );
    });

    for (final (campo, valor) in const [
      ('mapa', '3'),
      ('capacidad', '4'),
      ('anfitrion', 7),
      ('jugadores', [1, 2]),
      ('comenzada', 'no'),
      ('listos', 'luis'),
      ('listos', [3]),
      ('finalizados', 'luis'),
      ('finalizados', [3]),
      ('configurada', 'no'),
      ('miTablero', '123456'),
      ('miTablero', [1, 2, 3]),
      ('miTablero', ['1', '2', '3', '4', '5', '6']),
      ('ronda', '2'),
      ('ronda', 0),
      ('ronda', -1),
      ('dados', '52'),
      ('dados', [5]),
      ('dados', [5, 2, 1]),
      ('dados', [0, 2]),
      ('dados', [5, 7]),
      ('dados', ['5', '2']),
      ('jugaron', 'luis'),
      ('jugaron', [1]),
      ('meta', '26'),
      ('terminada', 'no'),
      ('ganadores', 'ana'),
      ('ganadores', [1]),
      ('zonas', 'nada'),
      (
        'zonas',
        {
          'uno': {'ana': 1},
        },
      ),
      ('zonas', {'3': 'ana'}),
      (
        'zonas',
        {
          '3': {'ana': 'uno'},
        },
      ),
    ]) {
      test('Un $campo con otro tipo es una respuesta inesperada', () async {
        final partidas = servicio(
          [],
          respuesta: json({...salaJson, campo: valor}, 200),
        );

        await expectLater(
          partidas.unirse('ABC234'),
          throwsA(
            isA<ErrorAuth>().having(
              (e) => e.mensaje,
              'mensaje',
              'Respuesta inesperada del servidor.',
            ),
          ),
        );
      });
    }

    test('Una respuesta sin los datos de la sala es inesperada', () async {
      final partidas = servicio([], respuesta: json({'ok': true}, 200));

      await expectLater(partidas.unirse('ABC234'), throwsA(isA<ErrorAuth>()));
    });

    group('Código escrito a mano', () {
      test('Acepta letras y números, sin importar los espacios', () {
        expect(ServicioPartidas.errorCodigo('ABC234'), isNull);
        expect(ServicioPartidas.errorCodigo('abc234'), isNull);
        expect(ServicioPartidas.errorCodigo('  ABC234 '), isNull);
      });

      test('Rechaza el largo incorrecto', () {
        const mensaje = 'El código tiene 6 caracteres.';

        expect(ServicioPartidas.errorCodigo(''), mensaje);
        expect(ServicioPartidas.errorCodigo('ABC23'), mensaje);
        expect(ServicioPartidas.errorCodigo('ABC2345'), mensaje);
      });

      test('Rechaza símbolos y espacios internos', () {
        const mensaje = 'El código solo lleva letras y números.';

        expect(ServicioPartidas.errorCodigo('ABC-23'), mensaje);
        expect(ServicioPartidas.errorCodigo('AB 234'), mensaje);
        expect(ServicioPartidas.errorCodigo('ABCÑ23'), mensaje);
      });
    });
  });
}
