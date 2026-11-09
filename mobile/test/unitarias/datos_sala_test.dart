// Prueba unitaria (no de widgets): revisa las cuentas que la sala de espera
// hace sobre quién está listo, sin servidor ni pantallas.

import 'package:brilliant_mobile/servicio_partidas.dart';
import 'package:flutter_test/flutter_test.dart';

SalaPartida sala(
  List<String> jugadores,
  List<String> listos, {
  List<String> finalizados = const [],
}) => SalaPartida(
  codigo: 'ABC234',
  mapa: 1,
  capacidad: 4,
  anfitrion: jugadores.first,
  jugadores: jugadores,
  listos: listos,
  comenzada: false,
  finalizados: finalizados,
  configurada: false,
  miTablero: const [],
);

void main() {
  group('Unitarias: datos de la sala', () {
    test('Sabe quién está listo y quién no', () {
      final enEspera = sala(['ana', 'luis'], ['luis']);

      expect(enEspera.estaListo('luis'), isTrue);
      expect(enEspera.estaListo('ana'), isFalse);
      expect(enEspera.estaListo(null), isFalse);
    });

    test('Cuenta cuántos faltan por confirmar', () {
      expect(sala(['ana', 'luis', 'eva'], []).pendientes, 3);
      expect(sala(['ana', 'luis', 'eva'], ['eva']).pendientes, 2);
      expect(sala(['ana', 'luis'], ['ana', 'luis']).pendientes, 0);
    });

    test('A solas faltan jugadores aunque esté listo', () {
      expect(sala(['ana'], ['ana']).faltanJugadores, isTrue);
      expect(sala(['ana', 'luis'], []).faltanJugadores, isFalse);
    });

    test('Sabe quién terminó su tablero y quién sigue colocando', () {
      final enPreparacion = sala(
        ['ana', 'luis', 'eva'],
        ['ana', 'luis', 'eva'],
        finalizados: ['luis'],
      );

      expect(enPreparacion.haFinalizado('luis'), isTrue);
      expect(enPreparacion.haFinalizado('ana'), isFalse);
      expect(enPreparacion.haFinalizado(null), isFalse);
      expect(enPreparacion.tablerosPendientes, ['ana', 'eva']);
    });
  });
}
