import 'package:brilliant_mobile/datos_sala.dart';
import 'package:brilliant_mobile/servicio_auth.dart';

export 'package:brilliant_mobile/datos_sala.dart';

/// Crea salas multijugador y entra en ellas a nombre de la sesión abierta.
class ServicioPartidas {
  const ServicioPartidas(this.auth);

  static const int minimoJugadores = 2;
  static const int maximoJugadores = 6;
  static const int largoCodigo = 6;

  /// Qué le falta a un código escrito a mano, o null si vale la pena enviarlo.
  /// Si la partida existe y admite al jugador solo lo sabe el servidor.
  static String? errorCodigo(String codigo) {
    final limpio = codigo.trim();
    if (limpio.length != largoCodigo) {
      return 'El código tiene $largoCodigo caracteres.';
    }
    if (!RegExp(r'^[A-Za-z0-9]+$').hasMatch(limpio)) {
      return 'El código solo lleva letras y números.';
    }
    return null;
  }

  final ServicioAuth auth;

  Future<SalaPartida> crear({
    required int mapa,
    required int jugadores,
  }) async => SalaPartida.desdeJson(
    await auth.enviarConSesion('partida/crear', {
      'mapa': '$mapa',
      'jugadores': '$jugadores',
    }),
  );

  Future<SalaPartida> unirse(String codigo) async => SalaPartida.desdeJson(
    await auth.enviarConSesion('partida/unirse', {'codigo': codigo.trim()}),
  );

  Future<SalaPartida> consultar(String codigo) async => SalaPartida.desdeJson(
    await auth.enviarConSesion('partida/estado', {'codigo': codigo}),
  );

  /// Confirma (o retira) que el jugador está listo. Si con eso ya lo están
  /// todos, la sala que responde el servidor llega comenzada.
  Future<SalaPartida> marcarListo(String codigo, {required bool listo}) async =>
      SalaPartida.desdeJson(
        await auth.enviarConSesion(
          listo ? 'partida/listo' : 'partida/no-listo',
          {'codigo': codigo},
        ),
      );

  Future<void> salir(String codigo) async {
    await auth.enviarConSesion('partida/salir', {'codigo': codigo});
  }
}
