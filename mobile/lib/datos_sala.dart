import 'package:brilliantdart/catalogo_mapas.dart';
import 'package:brilliant_mobile/servicio_auth.dart';
import 'package:brilliant_mobile/servicio_partidas.dart';

/// Sala de espera de una partida multijugador, tal como la describe el servidor.
class SalaPartida {
  const SalaPartida({
    required this.codigo,
    required this.mapa,
    required this.capacidad,
    required this.anfitrion,
    required this.jugadores,
    required this.listos,
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
      'listos': final List<dynamic> listos,
      'comenzada': final bool comenzada,
    } when _sonTextos(jugadores) && _sonTextos(listos)) {
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
        listos: listos.cast<String>(),
        comenzada: comenzada,
      );
    }
    throw const ErrorAuth('Respuesta inesperada del servidor.');
  }

  static bool _sonTextos(List<dynamic> lista) =>
      lista.every((elemento) => elemento is String);

  final String codigo;

  /// Número del mapa que se jugará.
  final int mapa;

  /// Cuántos jugadores caben en la sala, contando al anfitrión.
  final int capacidad;
  final String anfitrion;

  /// Usuarios dentro de la sala, en orden de llegada.
  final List<String> jugadores;

  /// Quiénes ya confirmaron que están listos para iniciar.
  final List<String> listos;

  /// Todos confirmaron y el servidor la inició: ya no entra nadie nuevo.
  final bool comenzada;

  bool estaListo(String? usuario) => listos.contains(usuario);

  /// Cuántos jugadores de la sala todavía no confirman.
  int get pendientes =>
      jugadores.where((jugador) => !listos.contains(jugador)).length;

  /// A solas no se puede empezar, aunque el único jugador esté listo.
  bool get faltanJugadores =>
      jugadores.length < ServicioPartidas.minimoJugadores;
}
