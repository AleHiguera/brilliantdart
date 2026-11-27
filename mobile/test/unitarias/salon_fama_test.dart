// Prueba unitaria: lo que llega del servidor para el Salón de la Fama, cómo
// se escribe el ELO y la petición al servidor.

import 'dart:convert';

import 'package:brilliant_mobile/datos_salon_fama.dart';
import 'package:brilliant_mobile/servicio_auth.dart';
import 'package:brilliant_mobile/servicio_salon_fama.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Map<String, Object?> puesto(int lugar, String usuario, int elo) => {
  'lugar': lugar,
  'usuario': usuario,
  'elo': elo,
};

http.Response json(Map<String, Object?> datos, [int codigo = 200]) =>
    http.Response.bytes(utf8.encode(jsonEncode(datos)), codigo);

ServicioAuth sesion(
  Future<http.Response> Function(http.Request) responder, {
  List<http.Request>? peticiones,
}) => ServicioAuth(
  servidor: 'https://servidor:8443',
  cliente: MockClient((p) async {
    peticiones?.add(p);
    return responder(p);
  }),
)..sesion = const Sesion(usuario: 'ana', nombre: 'Ana', token: 'abc');

void main() {
  group('Unitarias: Salón de la Fama, lectura', () {
    test('Lee el Top con lugar, usuario y ELO', () {
      final salon = SalonFama.desdeJson({
        'top': [puesto(1, 'eva', 90), puesto(2, 'ana', 50)],
        'yo': null,
        'jugadores': 2,
      });

      expect(salon.top, [
        (lugar: 1, usuario: 'eva', elo: 90),
        (lugar: 2, usuario: 'ana', elo: 50),
      ]);
      expect(salon.yo, isNull);
      expect(salon.jugadores, 2);
    });

    test('Si quedé fuera del Top, mi puesto llega aparte', () {
      final salon = SalonFama.desdeJson({
        'top': [puesto(1, 'eva', 90)],
        'yo': puesto(66, 'ana', 1350),
        'jugadores': 80,
      });

      expect(salon.yo, (lugar: 66, usuario: 'ana', elo: 1350));
    });

    test('Conserva el orden en que llega', () {
      final salon = SalonFama.desdeJson({
        'top': [puesto(1, 'b', 9), puesto(1, 'a', 9), puesto(2, 'c', 1)],
      });

      expect(salon.top.map((p) => p.usuario), ['b', 'a', 'c']);
    });

    test('Un puesto mal formado se deja fuera, los demás se ven', () {
      final salon = SalonFama.desdeJson({
        'top': [
          puesto(1, 'eva', 90),
          {'lugar': 2, 'usuario': 'luis'},
          puesto(0, 'cero', 5),
          'texto',
          {'lugar': '3', 'usuario': 'x', 'elo': 1},
          puesto(2, 'ana', 50),
        ],
      });

      expect(salon.top.map((p) => p.usuario), ['eva', 'ana']);
    });

    test('Un yo mal formado se toma como que estoy dentro', () {
      final salon = SalonFama.desdeJson({
        'top': <Object>[],
        'yo': {'lugar': 66},
      });

      expect(salon.yo, isNull);
    });

    test('Sin el número de jugadores se cuentan los del Top', () {
      final salon = SalonFama.desdeJson({
        'top': [puesto(1, 'eva', 90), puesto(2, 'ana', 50)],
      });

      expect(salon.jugadores, 2);
    });

    test('Sin la lista del Top la respuesta no sirve', () {
      expect(
        () => SalonFama.desdeJson({'ok': true}),
        throwsA(isA<ErrorAuth>()),
      );
      expect(
        () => SalonFama.desdeJson({'top': 'nada'}),
        throwsA(isA<ErrorAuth>()),
      );
    });
  });

  group('Unitarias: Salón de la Fama, mi puesto', () {
    const salon = SalonFama(
      top: [
        (lugar: 1, usuario: 'Eva', elo: 90),
        (lugar: 2, usuario: 'ana', elo: 50),
      ],
      yo: (lugar: 66, usuario: 'luis', elo: 3),
      jugadores: 80,
    );

    test('Me encuentra dentro del Top', () {
      expect(salon.puestoDe('ana'), (lugar: 2, usuario: 'ana', elo: 50));
    });

    test('Me encuentra aparte si quedé fuera', () {
      expect(salon.puestoDe('luis')?.lugar, 66);
    });

    test('Sin importar mayúsculas', () {
      expect(salon.puestoDe('EVA')?.lugar, 1);
    });

    test('Si no aparezco, o no hay usuario, no hay puesto', () {
      expect(salon.puestoDe('nadie'), isNull);
      expect(salon.puestoDe(null), isNull);
    });
  });

  group('Unitarias: ELO con comas', () {
    test('Menos de mil va tal cual', () {
      expect(eloConComas(0), '0');
      expect(eloConComas(7), '7');
      expect(eloConComas(999), '999');
    });

    test('Los miles llevan coma, como 2,450', () {
      expect(eloConComas(1000), '1,000');
      expect(eloConComas(2450), '2,450');
      expect(eloConComas(1350), '1,350');
    });

    test('Millones también', () {
      expect(eloConComas(1234567), '1,234,567');
      expect(eloConComas(100000), '100,000');
    });

    test('Un negativo lleva su signo', () {
      expect(eloConComas(-1500), '−1,500');
    });
  });

  group('Unitarias: Salón de la Fama, servidor', () {
    test('Se pide a /api/salon-fama con la sesión', () async {
      final peticiones = <http.Request>[];
      final auth = sesion(
        (_) async => json({
          'ok': true,
          'top': [puesto(1, 'ana', 16)],
          'yo': null,
          'jugadores': 1,
        }),
        peticiones: peticiones,
      );

      final salon = await ServicioSalonFama(auth).consultar();

      expect(peticiones.single.url.path, '/api/salon-fama');
      expect(peticiones.single.method, 'POST');
      expect(peticiones.single.headers['Authorization'], 'Bearer abc');
      expect(salon.top.single.usuario, 'ana');
    });

    test('Deja mi ELO al día en la sesión (estando en el Top)', () async {
      final auth = sesion(
        (_) async => json({
          'ok': true,
          'top': [puesto(1, 'ana', 48)],
          'yo': null,
        }),
      )..elo.value = 16;

      await ServicioSalonFama(auth).consultar();

      expect(auth.elo.value, 48);
    });

    test('Deja mi ELO al día también si quedé fuera', () async {
      final auth = sesion(
        (_) async => json({
          'ok': true,
          'top': [puesto(1, 'eva', 90)],
          'yo': puesto(12, 'ana', 7),
        }),
      );

      await ServicioSalonFama(auth).consultar();

      expect(auth.elo.value, 7);
    });

    test('Si no aparezco, mi ELO no cambia', () async {
      final auth = sesion(
        (_) async => json({
          'ok': true,
          'top': [puesto(1, 'eva', 90)],
          'yo': null,
        }),
      )..elo.value = 16;

      await ServicioSalonFama(auth).consultar();

      expect(auth.elo.value, 16);
    });

    test('Si el servidor lo rechaza, llega el error', () async {
      final auth = sesion(
        (_) async => json({'ok': false, 'mensaje': 'Sin sesión.'}, 401),
      );

      expect(
        () => ServicioSalonFama(auth).consultar(),
        throwsA(isA<ErrorAuth>()),
      );
    });

    test('Sin conexión, llega el error', () async {
      final auth = sesion((_) async => throw http.ClientException('Sin red'));

      expect(
        () => ServicioSalonFama(auth).consultar(),
        throwsA(isA<ErrorAuth>()),
      );
    });

    test('Sin sesión no se pide nada', () async {
      final peticiones = <http.Request>[];
      final auth = sesion(
        (_) async => json({'ok': true}),
        peticiones: peticiones,
      )..sesion = null;

      expect(
        () => ServicioSalonFama(auth).consultar(),
        throwsA(isA<ErrorAuth>()),
      );
      expect(peticiones, isEmpty);
    });
  });
}
