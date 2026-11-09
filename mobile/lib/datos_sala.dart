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
    required this.finalizados,
    required this.configurada,
    required this.miTablero,
  });

  /// Lee la sala del servidor. Lo que no se pueda mostrar llega como [ErrorAuth],
  /// igual que un rechazo, para que las pantallas lo enseñen como cualquier error.
  factory SalaPartida.desdeJson(Map<String, dynamic> datos) {
    if (datos
        case {
          'codigo': final String codigo,
          'mapa': final int mapa,
          'capacidad': final int capacidad,
          'anfitrion': final String anfitrion,
          'jugadores': final List<dynamic> jugadores,
          'listos': final List<dynamic> listos,
          'comenzada': final bool comenzada,
          'finalizados': final List<dynamic> finalizados,
          'configurada': final bool configurada,
          'miTablero': final List<dynamic> miTablero,
        }
        when _sonTextos(jugadores) &&
            _sonTextos(listos) &&
            _sonTextos(finalizados) &&
            _esTableroValido(miTablero)) {
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
        finalizados: finalizados.cast<String>(),
        configurada: configurada,
        miTablero: miTablero.cast<int>(),
      );
    }
    throw const ErrorAuth('Respuesta inesperada del servidor.');
  }

  static bool _sonTextos(List<dynamic> lista) =>
      lista.every((elemento) => elemento is String);

  /// Vacío si el jugador no ha finalizado; si no, un número por celda inicial.
  static bool _esTableroValido(List<dynamic> lista) =>
      (lista.isEmpty || lista.length == 6) &&
      lista.every((elemento) => elemento is int);

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

  /// Quiénes ya terminaron de colocar sus números iniciales.
  final List<String> finalizados;

  /// Todos finalizaron su tablero: ya se pueden lanzar los dados.
  final bool configurada;

  /// Números iniciales guardados de quien consulta, en el orden de las celdas
  /// iniciales del mapa. Vacío si aún no finaliza; los ajenos no llegan.
  final List<int> miTablero;

  bool estaListo(String? usuario) => listos.contains(usuario);

  bool haFinalizado(String? usuario) => finalizados.contains(usuario);

  /// Quiénes siguen colocando sus números, en orden de llegada.
  List<String> get tablerosPendientes =>
      jugadores.where((jugador) => !finalizados.contains(jugador)).toList();

  /// Cuántos jugadores de la sala todavía no confirman.
  int get pendientes =>
      jugadores.where((jugador) => !listos.contains(jugador)).length;

  /// A solas no se puede empezar, aunque el único jugador esté listo.
  bool get faltanJugadores =>
      jugadores.length < ServicioPartidas.minimoJugadores;
}
