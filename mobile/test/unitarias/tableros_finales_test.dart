// Prueba unitaria: la app manda su tablero con cada turno, y al terminar la
// partida lee cómo quedó el de cada jugador.

import 'dart:convert';

import 'package:brilliant_mobile/partida_compartida.dart';
import 'package:brilliant_mobile/servicio_auth.dart';
import 'package:brilliant_mobile/servicio_partidas.dart';
import 'package:brilliant_mobile/vigilante_sala.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

final String vacio = '0' * 49;
final String deAna = '3${'0' * 47}6';
final String deLuis = '1${'0' * 48}';

Map<String, Object> salaJson({
  bool terminada = false,
  Object? tablerosFinales,
  int ronda = 1,
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
  'miTablero': [3, 1, 2, 6, 5, 4],
  'ronda': ronda,
  'dados': [5, 2],
  'jugaron': jugaron,
  'zonas': <String, Object>{},
  'meta': 26,
  'terminada': terminada,
  'ganadores': terminada ? ['ana'] : <String>[],
  'tablerosFinales': ?tablerosFinales,
};

http.Response json(Map<String, Object> datos) =>
    http.Response.bytes(utf8.encode(jsonEncode(datos)), 200);

ServicioPartidas servicio(
  Future<http.Response> Function(http.Request) responder,
) {
  final auth = ServicioAuth(
    servidor: 'https://servidor:8443',
    cliente: MockClient(responder),
  )..sesion = const Sesion(usuario: 'ana', nombre: 'Ana', token: 'abc');
  return ServicioPartidas(auth);
}

void main() {
  group('Unitarias: envío del tablero', () {
    test('Terminar el turno manda cómo quedó el tablero', () async {
      final peticiones = <http.Request>[];
      await servicio((p) async {
        peticiones.add(p);
        return json(salaJson());
      }).terminarTurno('ABC234', 1, tableroLleno: false, tablero: deAna);

      expect(peticiones.single.bodyFields['tablero'], deAna);
    });

    test('Sin tablero no se manda ese dato', () async {
      final peticiones = <http.Request>[];
      await servicio((p) async {
        peticiones.add(p);
        return json(salaJson());
      }).terminarTurno('ABC234', 1, tableroLleno: false);

      expect(peticiones.single.bodyFields.containsKey('tablero'), isFalse);
    });

    test('Al fijar los números iniciales también va el tablero', () async {
      final peticiones = <http.Request>[];
      await servicio((p) async {
        peticiones.add(p);
        return json(salaJson());
      }).finalizarTablero('ABC234', [3, 1, 2, 6, 5, 4], tablero: deAna);

      expect(peticiones.single.bodyFields, {
        'codigo': 'ABC234',
        'numeros': '3,1,2,6,5,4',
        'tablero': deAna,
      });
    });
  });

  group('Unitarias: tableros al final de la partida', () {
    Future<SalaPartida> leer(Object? tableros, {bool terminada = true}) =>
        servicio(
          (_) async =>
              json(salaJson(terminada: terminada, tablerosFinales: tableros)),
        ).consultar('ABC234');

    test('Lee el tablero de cada jugador, en el orden que llegan', () async {
      final sala = await leer({'luis': deLuis, 'ana': deAna});

      expect(sala.tablerosFinales, {'luis': deLuis, 'ana': deAna});
      expect(sala.tablerosFinales.keys, ['luis', 'ana']);
    });

    test('Un servidor anterior no los manda: no hay tableros', () async {
      final sala = await leer(null);

      expect(sala.tablerosFinales, isEmpty);
      expect(sala.terminada, isTrue);
    });

    test('Un tablero que no se puede leer se deja fuera', () async {
      final sala = await leer({
        'ana': deAna,
        'luis': 'basura',
        'eva': 7,
        'leo': '9' * 49,
      });

      expect(sala.tablerosFinales, {'ana': deAna});
    });

    test('Si no es una lista de tableros, igual se ve quién ganó', () async {
      final sala = await leer('no es un mapa');

      expect(sala.tablerosFinales, isEmpty);
      expect(sala.ganadores, ['ana']);
    });
  });

  group('Unitarias: la partida compartida manda su tablero', () {
    PartidaCompartida partida(
      Future<http.Response> Function(http.Request) responder,
    ) => PartidaCompartida(
      partidas: servicio(responder),
      sala: SalaPartida.desdeJson(salaJson()),
    );

    test('El turno lleva el tablero que se le dio', () async {
      final peticiones = <http.Request>[];
      final fase = partida((p) async {
        peticiones.add(p);
        return json(salaJson(jugaron: ['ana']));
      });

      fase.terminarTurno(tableroLleno: false, tablero: deAna);
      await pumpEventQueue();

      final turno = peticiones.singleWhere(
        (p) => p.url.path.endsWith('/turno'),
      );
      expect(turno.bodyFields['tablero'], deAna);
    });

    test('El reintento de un aviso fallido lleva el mismo tablero', () async {
      final turnos = <http.Request>[];
      var falla = true;
      final fase = partida((p) async {
        if (p.url.path.endsWith('/turno')) {
          turnos.add(p);
          if (falla) throw http.ClientException('Caído');
          return json(salaJson(jugaron: ['ana']));
        }
        // La consulta siguiente aún no sabe que jugó: hay que reintentar.
        return json(salaJson());
      });

      fase.terminarTurno(tableroLleno: false, tablero: deAna);
      await pumpEventQueue();
      falla = false;
      // La siguiente consulta ve que el turno no llegó y lo repite.
      fase.iniciar();
      await Future<void>.delayed(
        VigilanteSala.intervalo + const Duration(milliseconds: 300),
      );
      await pumpEventQueue();
      fase.dispose();

      expect(turnos.length, greaterThanOrEqualTo(2));
      expect(turnos.map((p) => p.bodyFields['tablero']), everyElement(deAna));
    });

    test(
      'Al fijar los iniciales se recuerda el tablero para los turnos',
      () async {
        final peticiones = <http.Request>[];
        final fase = PartidaCompartida(
          partidas: servicio((p) async {
            peticiones.add(p);
            return json(salaJson(ronda: 0));
          }),
          sala: SalaPartida.desdeJson({
            ...salaJson(ronda: 0),
            'dados': <int>[],
            'finalizados': <String>[],
            'configurada': false,
            'miTablero': <int>[],
          }),
        );

        await fase.finalizar([3, 1, 2, 6, 5, 4], tablero: vacio);

        expect(fase.tablero, vacio);
        expect(peticiones.single.bodyFields['tablero'], vacio);
      },
    );
  });
}
