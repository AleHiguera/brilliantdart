import 'package:brilliantdart/catalogo_mapas.dart';
import 'package:brilliant_mobile/servicio_auth.dart';

/// Sala de espera de una partida multijugador, tal como la describe el servidor.
class SalaPartida {
  const SalaPartida({
    required this.codigo,
    required this.mapa,
    required this.capacidad,
    required this.anfitrion,
    required this.jugadores,
    required this.comenzada,
  });

  /// Lee la sala del servidor. Lo que no se pueda mostrar llega como [ErrorAuth],
  /// igual que un rechazo, para que las pantallas lo enseñen como cualquier error.
  factory SalaPartida.desdeJson(Map<String, dynamic> datos) {
    if (datos case {
      'codigo': final String codigo,
      'mapa': final int mapa,
      'capacidad': final int capacidad,
      'anfitrion': final String anfitrion,
      'jugadores': final List<dynamic> jugadores,
      'comenzada': final bool comenzada,
    } when jugadores.every((jugador) => jugador is String)) {
      if (!mapasDisponibles.any((conocido) => conocido.numero == mapa)) {
        throw const ErrorAuth(
          'Esta partida usa un mapa que tu versión de la app no conoce.',
        );
      }
      return SalaPartida(
        codigo: codigo,
        mapa: mapa,
        capacidad: capacidad,
        anfitrion: anfitrion,
        jugadores: jugadores.cast<String>(),
        comenzada: comenzada,
      );
    }
    throw const ErrorAuth('Respuesta inesperada del servidor.');
  }

  final String codigo;

  /// Número del mapa que se jugará.
  final int mapa;

  /// Cuántos jugadores caben en la sala, contando al anfitrión.
  final int capacidad;
  final String anfitrion;

  /// Usuarios dentro de la sala, en orden de llegada.
  final List<String> jugadores;

  /// El anfitrión ya la inició: desde entonces no entra nadie nuevo.
  final bool comenzada;

  /// Sin otro jugador no hay partida que iniciar.
  bool get sePuedeIniciar =>
      !comenzada && jugadores.length >= ServicioPartidas.minimoJugadores;
}

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

  /// Solo el anfitrión puede hacerlo; el servidor rechaza a cualquier otro.
  Future<SalaPartida> iniciar(String codigo) async => SalaPartida.desdeJson(
    await auth.enviarConSesion('partida/iniciar', {'codigo': codigo}),
  );

  Future<void> salir(String codigo) async {
    await auth.enviarConSesion('partida/salir', {'codigo': codigo});
  }
}
