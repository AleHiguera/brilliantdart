// Prueba unitaria (no de widgets): revisa cuándo el vigilante avisa de un
// cambio en la sala y cuándo da la sala por terminada.

import 'dart:async';
import 'dart:convert';

import 'package:brilliant_mobile/servicio_auth.dart';
import 'package:brilliant_mobile/servicio_partidas.dart';
import 'package:brilliant_mobile/vigilante_sala.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response json(Map<String, Object> datos, int codigo) =>
    http.Response.bytes(utf8.encode(jsonEncode(datos)), codigo);

http.Response sala() => json({
  'ok': true,
  'mensaje': 'Sala.',
  'codigo': 'ABC234',
  'mapa': 1,
  'capacidad': 2,
  'anfitrion': 'ana',
  'jugadores': ['ana', 'luis'],
  'listos': <String>[],
  'comenzada': false,
  'finalizados': <String>[],
  'configurada': false,
  'miTablero': <int>[],
}, 200);

http.Response rechazo(int codigo) =>
    json({'ok': false, 'mensaje': 'Sin sala.'}, codigo);

class Prueba {
  Prueba(Future<http.Response> Function() responder) {
    final auth = ServicioAuth(
      servidor: 'https://servidor:8443',
      cliente: MockClient((_) {
        consultas++;
        return responder();
      }),
    )..sesion = const Sesion(usuario: 'ana', nombre: 'Ana', token: 'abc');
    vigilante = VigilanteSala(
      partidas: ServicioPartidas(auth),
      codigo: 'ABC234',
      alCambiar: salas.add,
      alTerminar: terminos.add,
    );
  }

  late final VigilanteSala vigilante;
  final List<SalaPartida> salas = [];
  final List<String> terminos = [];
  int consultas = 0;
}

void main() {
  group('Unitarias: vigilante de la sala', () {
    test('Avisa de cómo está la sala', () async {
      final prueba = Prueba(() async => sala());

      await prueba.vigilante.consultar();

      expect(prueba.salas.single.jugadores, ['ana', 'luis']);
      expect(prueba.terminos, isEmpty);
    });

    test('Un rechazo de la sala la termina y no se consulta más', () async {
      final prueba = Prueba(() async => rechazo(409));

      await prueba.vigilante.consultar();
      await prueba.vigilante.consultar();

      expect(prueba.terminos, ['Sin sala.']);
      expect(prueba.consultas, 1);
    });

    for (final codigo in [401, 500]) {
      test('Un error $codigo no termina la sala', () async {
        final prueba = Prueba(() async => rechazo(codigo));

        await prueba.vigilante.consultar();

        expect(prueba.terminos, isEmpty);
      });
    }

    test('Sin conexión se sigue intentando', () async {
      final prueba = Prueba(() async => throw http.ClientException('Caído'));

      await prueba.vigilante.consultar();
      await prueba.vigilante.consultar();

      expect(prueba.consultas, 2);
      expect(prueba.terminos, isEmpty);
    });

    test('No lanza una consulta si la anterior sigue en camino', () async {
      final pendiente = Completer<http.Response>();
      final prueba = Prueba(() => pendiente.future);

      final primera = prueba.vigilante.consultar();
      await prueba.vigilante.consultar();
      pendiente.complete(sala());
      await primera;

      expect(prueba.consultas, 1);
    });

    test('Una respuesta tardía no avisa si ya se detuvo', () async {
      final pendiente = Completer<http.Response>();
      final prueba = Prueba(() => pendiente.future);

      final consulta = prueba.vigilante.consultar();
      prueba.vigilante.detener();
      pendiente.complete(sala());
      await consulta;

      expect(prueba.salas, isEmpty);
    });
  });
}
