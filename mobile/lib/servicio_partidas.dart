import 'package:brilliant_mobile/servicio_auth.dart';

/// Sala de espera de una partida multijugador, tal como la describe el servidor.
class SalaPartida {
  const SalaPartida({
    required this.codigo,
    required this.mapa,
    required this.capacidad,
    required this.anfitrion,
    required this.jugadores,
  });

  factory SalaPartida.desdeJson(Map<String, dynamic> datos) => SalaPartida(
    codigo: datos['codigo'] as String,
    mapa: datos['mapa'] as int,
    capacidad: datos['capacidad'] as int,
    anfitrion: datos['anfitrion'] as String,
    jugadores: (datos['jugadores'] as List<dynamic>).cast<String>(),
  );

  final String codigo;

  /// Número del mapa que se jugará.
  final int mapa;

  /// Cuántos jugadores caben en la sala, contando al anfitrión.
  final int capacidad;
  final String anfitrion;

  /// Usuarios dentro de la sala, en orden de llegada.
  final List<String> jugadores;
}

/// Crea salas multijugador y entra en ellas a nombre de la sesión abierta.
class ServicioPartidas {
  const ServicioPartidas(this.auth);

  static const int minimoJugadores = 2;
  static const int maximoJugadores = 6;
  static const int largoCodigo = 6;

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

  Future<void> salir(String codigo) async {
    await auth.enviarConSesion('partida/salir', {'codigo': codigo});
  }
}
