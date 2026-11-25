// Prueba unitaria: el ELO que llega del servidor, el de la sesión y cómo se
// escribe el cambio.

import 'dart:convert';

import 'package:brilliant_mobile/etiqueta_elo.dart';
import 'package:brilliant_mobile/partida_compartida.dart';
import 'package:brilliant_mobile/servicio_auth.dart';
import 'package:brilliant_mobile/servicio_partidas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Map<String, Object> salaJson({
  Object? elos,
  Object? resultadosElo,
  bool terminada = false,
  List<String> jugaron = const [],
}) => {
  'ok': true,
  'mensaje': 'Sala.',
  'codigo': 'ABC234',
  'mapa': 1,
  'capacidad': 2,
  'anfitrion': 'ana',
  'jugadores': ['ana', 'luis'],
  'listos': ['ana', 'luis'],
  'comenzada': true,
  'finalizados': ['ana', 'luis'],
  'configurada': true,
  'miTablero': [1, 2, 3, 4, 5, 6],
  'ronda': 1,
  'dados': [5, 2],
  'jugaron': jugaron,
  'zonas': <String, Object>{},
  'meta': 26,
  'terminada': terminada,
  'ganadores': terminada ? ['ana'] : <String>[],
  'elos': ?elos,
  'resultadosElo': ?resultadosElo,
};

const Map<String, Object> resultadosNormales = {
  'ana': {'lugar': 1, 'antes': 1000, 'cambio': 16, 'despues': 1016},
  'luis': {'lugar': 2, 'antes': 1000, 'cambio': -16, 'despues': 984},
};

http.Response json(Map<String, Object> datos, [int codigo = 200]) =>
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

Future<SalaPartida> leer(Map<String, Object> datos) =>
    ServicioPartidas(sesion((_) async => json(datos))).consultar('ABC234');

void main() {
  group('Unitarias: ELO en la sala', () {
    test('Lee el ELO de cada jugador', () async {
      final sala = await leer(salaJson(elos: {'ana': 1000, 'luis': 1032}));

      expect(sala.elos, {'ana': 1000, 'luis': 1032});
    });

    test('Un servidor anterior no lo envía: no hay ELO', () async {
      final sala = await leer(salaJson());

      expect(sala.elos, isEmpty);
      expect(sala.resultadosElo, isEmpty);
    });

    test('Un ELO que no es un número se deja fuera', () async {
      final sala = await leer(
        salaJson(elos: {'ana': 1000, 'luis': '1032', 'eva': 9.5}),
      );

      expect(sala.elos, {'ana': 1000});
    });

    test('Si el ELO no es una lista de jugadores, se ignora', () async {
      final sala = await leer(salaJson(elos: [1000, 1032]));

      expect(sala.elos, isEmpty);
      expect(sala.jugadores, ['ana', 'luis']);
    });

    test(
      'Al terminar, lee antes, cambio, después y lugar de cada uno',
      () async {
        final sala = await leer(
          salaJson(terminada: true, resultadosElo: resultadosNormales),
        );

        expect(sala.resultadosElo['ana'], (
          lugar: 1,
          antes: 1000,
          cambio: 16,
          despues: 1016,
        ));
        expect(sala.resultadosElo['luis'], (
          lugar: 2,
          antes: 1000,
          cambio: -16,
          despues: 984,
        ));
      },
    );

    test(
      'Un resultado que no cuadra (antes + cambio ≠ después) se deja fuera',
      () async {
        final sala = await leer(
          salaJson(
            terminada: true,
            resultadosElo: {
              ...resultadosNormales,
              'eva': {'lugar': 3, 'antes': 1000, 'cambio': -5, 'despues': 1000},
            },
          ),
        );

        expect(sala.resultadosElo.keys, ['ana', 'luis']);
      },
    );

    test('Un resultado incompleto o con lugar 0 se deja fuera', () async {
      final sala = await leer(
        salaJson(
          terminada: true,
          resultadosElo: {
            'ana': {'lugar': 1, 'antes': 1000, 'cambio': 16},
            'luis': {'lugar': 0, 'antes': 1000, 'cambio': 0, 'despues': 1000},
            'eva': 'no es un resultado',
            'sol': {'lugar': 2, 'antes': 990, 'cambio': -6, 'despues': 984},
          },
        ),
      );

      expect(sala.resultadosElo.keys, ['sol']);
    });

    test('Un resultado mal formado no impide ver quién ganó', () async {
      final sala = await leer(
        salaJson(terminada: true, resultadosElo: 'basura'),
      );

      expect(sala.resultadosElo, isEmpty);
      expect(sala.ganadores, ['ana']);
    });
  });

  group('Unitarias: mi ELO', () {
    test('Se pide a /api/elo con la sesión y queda en la sesión', () async {
      final peticiones = <http.Request>[];
      final auth = sesion(
        (_) async => json({'ok': true, 'mensaje': 'ELO.', 'elo': 1016}),
        peticiones: peticiones,
      );

      await ServicioPartidas(auth).actualizarMiElo();

      expect(peticiones.single.url.path, '/api/elo');
      expect(peticiones.single.headers['Authorization'], 'Bearer abc');
      expect(auth.elo.value, 1016);
    });

    test('Mientras no se pide, no se sabe', () {
      expect(sesion((_) async => json({})).elo.value, isNull);
    });

    test('Sin conexión se queda el que se conocía', () async {
      final auth = sesion((_) async => throw http.ClientException('Sin red'))
        ..elo.value = 990;

      await ServicioPartidas(auth).actualizarMiElo();

      expect(auth.elo.value, 990);
    });

    test('Si el servidor lo rechaza, no rompe nada', () async {
      final auth = sesion(
        (_) async => json({'ok': false, 'mensaje': 'No.'}, 401),
      );

      await ServicioPartidas(auth).actualizarMiElo();

      expect(auth.elo.value, isNull);
    });

    test('Una respuesta sin número no cambia el ELO', () async {
      final auth = sesion(
        (_) async => json({'ok': true, 'mensaje': 'ELO.', 'elo': 'mucho'}),
      )..elo.value = 1000;

      await ServicioPartidas(auth).actualizarMiElo();

      expect(auth.elo.value, 1000);
    });

    test('Al cerrar sesión se olvida el ELO', () {
      final auth = sesion((_) async => json({}))..elo.value = 1016;

      auth.sesion = null;

      expect(auth.elo.value, isNull);
    });

    test('Al entrar otro usuario se olvida el ELO del anterior', () {
      final auth = sesion((_) async => json({}))..elo.value = 1016;

      auth.sesion = const Sesion(usuario: 'luis', nombre: 'Luis', token: 'x');

      expect(auth.elo.value, isNull);
    });

    test('Si es el mismo usuario (otro token), se conserva', () {
      final auth = sesion((_) async => json({}))..elo.value = 1016;

      auth.sesion = const Sesion(usuario: 'ana', nombre: 'Ana', token: 'otro');

      expect(auth.elo.value, 1016);
    });
  });

  group('Unitarias: el ELO al terminar una partida', () {
    Future<ServicioAuth> partidaQueRecibe(Map<String, Object> respuesta) async {
      final auth = sesion((_) async => json(respuesta))..elo.value = 1000;
      final partida = PartidaCompartida(
        partidas: ServicioPartidas(auth),
        sala: SalaPartida.desdeJson(salaJson()),
      )..terminarTurno(tableroLleno: true);
      await pumpEventQueue();
      partida.dispose();
      return auth;
    }

    test('Al terminar, mi ELO pasa a ser el nuevo', () async {
      final auth = await partidaQueRecibe(
        salaJson(terminada: true, resultadosElo: resultadosNormales),
      );

      expect(auth.elo.value, 1016);
    });

    test('Mientras no termina, mi ELO no cambia', () async {
      final auth = await partidaQueRecibe(salaJson(jugaron: ['ana']));

      expect(auth.elo.value, 1000);
    });

    test(
      'Si termina sin resultados de ELO (servidor anterior), no cambia',
      () async {
        final auth = await partidaQueRecibe(salaJson(terminada: true));

        expect(auth.elo.value, 1000);
      },
    );
  });

  group('Unitarias: turno avisado con la partida ya terminada', () {
    test('No se reintenta el aviso sin fin', () async {
      var turnos = 0;
      final auth = sesion((p) async {
        if (p.url.path.endsWith('/turno')) turnos++;
        // Terminó (por ejemplo, el otro abandonó) sin contar este turno.
        return json(salaJson(terminada: true));
      });
      final partida = PartidaCompartida(
        partidas: ServicioPartidas(auth),
        sala: SalaPartida.desdeJson(salaJson()),
      )..terminarTurno(tableroLleno: false);

      await pumpEventQueue(times: 200);
      partida.dispose();

      expect(turnos, 1);
    });
  });

  group('Unitarias: cómo se escribe el cambio de ELO', () {
    test('Ganar lleva +, perder −, y sin cambio ±0', () {
      expect(CambioElo.texto(16), '+16');
      expect(CambioElo.texto(-16), '−16');
      expect(CambioElo.texto(0), '±0');
    });

    test('Ganar en verde, perder en rojo, sin cambio en gris', () {
      expect(CambioElo.color(5), const Color(0xFF1E6B23));
      expect(CambioElo.color(-5), const Color(0xFFB3261E));
      expect(CambioElo.color(0), Colors.black54);
    });
  });
}
