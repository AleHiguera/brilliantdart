// Prueba unitaria (no de widgets): revisa cómo avanza la fase en que cada
// jugador coloca sus números, sin dibujar el tablero.

import 'dart:async';
import 'dart:convert';

import 'package:brilliant_mobile/preparacion_multijugador.dart';
import 'package:brilliant_mobile/servicio_auth.dart';
import 'package:brilliant_mobile/servicio_partidas.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const List<int> numeros = [3, 1, 2, 6, 5, 4];

SalaPartida sala({
  List<String> finalizados = const [],
  bool configurada = false,
  List<int> miTablero = const [],
}) => SalaPartida(
  codigo: 'ABC234',
  mapa: 1,
  capacidad: 2,
  anfitrion: 'ana',
  jugadores: const ['ana', 'luis'],
  listos: const ['ana', 'luis'],
  comenzada: true,
  finalizados: finalizados,
  configurada: configurada,
  miTablero: miTablero,
);

http.Response json(Map<String, Object> datos, int codigo) =>
    http.Response.bytes(utf8.encode(jsonEncode(datos)), codigo);

http.Response respuesta({
  List<String> finalizados = const ['ana'],
  bool configurada = false,
}) => json({
  'ok': true,
  'mensaje': 'Sala.',
  'codigo': 'ABC234',
  'mapa': 1,
  'capacidad': 2,
  'anfitrion': 'ana',
  'jugadores': ['ana', 'luis'],
  'listos': ['ana', 'luis'],
  'comenzada': true,
  'finalizados': finalizados,
  'configurada': configurada,
  'miTablero': numeros,
}, 200);

PreparacionMultijugador preparacion(
  Future<http.Response> Function(http.Request) responder, {
  SalaPartida? inicial,
}) {
  final auth = ServicioAuth(
    servidor: 'https://servidor:8443',
    cliente: MockClient(responder),
  )..sesion = const Sesion(usuario: 'ana', nombre: 'Ana', token: 'abc');
  return PreparacionMultijugador(
    partidas: ServicioPartidas(auth),
    sala: inicial ?? sala(),
  );
}

void main() {
  group('Unitarias: preparación multijugador', () {
    test('Al principio se puede editar y nadie terminó', () {
      final fase = preparacion((_) async => respuesta());

      expect(fase.puedeEditar, isTrue);
      expect(fase.yaFinalice, isFalse);
      expect(fase.todosTerminaron, isFalse);
    });

    test('Finalizar bloquea el tablero aunque falten otros', () async {
      final fase = preparacion((_) async => respuesta());

      await fase.finalizar(numeros);

      expect(fase.yaFinalice, isTrue);
      expect(fase.puedeEditar, isFalse);
      expect(fase.todosTerminaron, isFalse);
      expect(fase.sala.tablerosPendientes, ['luis']);
    });

    test('Mientras se envía no se edita ni se envía otra vez', () async {
      final pendiente = Completer<http.Response>();
      var envios = 0;
      final fase = preparacion((_) {
        envios++;
        return pendiente.future;
      });

      final primero = fase.finalizar(numeros);
      expect(fase.puedeEditar, isFalse);
      await fase.finalizar(numeros);
      pendiente.complete(respuesta());
      await primero;

      expect(envios, 1);
    });

    test('Un tablero ya finalizado no se vuelve a enviar', () async {
      var envios = 0;
      final fase = preparacion((_) async {
        envios++;
        return respuesta();
      }, inicial: sala(finalizados: ['ana'], miTablero: numeros));

      await fase.finalizar(numeros);

      expect(envios, 0);
    });

    test('Si el envío falla se puede corregir y reintentar', () async {
      final fase = preparacion(
        (_) async => json({'ok': false, 'mensaje': 'Sin suerte.'}, 409),
      );

      await fase.finalizar(numeros);

      expect(fase.error, 'Sin suerte.');
      expect(fase.perdida, isNull);
      expect(fase.puedeEditar, isTrue);
    });

    test('Avisa cuando el último termina', () async {
      final fase = preparacion(
        (_) async => respuesta(finalizados: ['ana', 'luis'], configurada: true),
      );
      var avisos = 0;
      fase.addListener(() => avisos++);

      await fase.finalizar(numeros);

      expect(fase.todosTerminaron, isTrue);
      expect(avisos, greaterThan(0));
    });

    test('Salir avisa al servidor aunque falle la conexión', () async {
      final rutas = <String>[];
      final fase = preparacion((peticion) async {
        rutas.add(peticion.url.path);
        throw http.ClientException('Caído');
      });

      await fase.salir();

      expect(rutas, ['/api/partida/salir']);
    });

    test('Una respuesta tardía no avisa si ya se cerró', () async {
      final pendiente = Completer<http.Response>();
      final fase = preparacion((_) => pendiente.future);
      var avisos = 0;

      final envio = fase.finalizar(numeros);
      fase
        ..addListener(() => avisos++)
        ..dispose();
      pendiente.complete(respuesta());
      await envio;

      expect(avisos, 0);
    });
  });
}
