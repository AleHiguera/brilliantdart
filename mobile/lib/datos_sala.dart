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
    required this.ronda,
    required this.dados,
    required this.jugaron,
    this.zonas = const {},
    this.meta = 0,
    this.terminada = false,
    this.ganadores = const [],
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
          'ronda': final int ronda,
          'dados': final List<dynamic> dados,
          'jugaron': final List<dynamic> jugaron,
          'zonas': final Map<String, dynamic> zonas,
          'meta': final int meta,
          'terminada': final bool terminada,
          'ganadores': final List<dynamic> ganadores,
        }
        when _sonTextos(jugadores) &&
            _sonTextos(listos) &&
            _sonTextos(finalizados) &&
            _esTableroValido(miTablero) &&
            _sonTextos(jugaron) &&
            _sonDadosDeRonda(ronda, dados) &&
            _sonZonas(zonas) &&
            _sonTextos(ganadores)) {
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
        ronda: ronda,
        dados: dados.cast<int>(),
        jugaron: jugaron.cast<String>(),
        zonas: {
          for (final MapEntry(key: zona, value: rondas) in zonas.entries)
            int.parse(zona): (rondas as Map<String, dynamic>)
                .cast<String, int>(),
        },
        meta: meta,
        terminada: terminada,
        ganadores: ganadores.cast<String>(),
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

  static bool _sonZonas(Map<String, dynamic> zonas) => zonas.entries.every(
    (zona) =>
        int.tryParse(zona.key) != null &&
        zona.value is Map<String, dynamic> &&
        (zona.value as Map<String, dynamic>).values.every(
          (ronda) => ronda is int,
        ),
  );

  /// Sin lanzar aún no hay dados; desde la ronda 1 son siempre dos caras.
  static bool _sonDadosDeRonda(int ronda, List<dynamic> dados) => ronda == 0
      ? dados.isEmpty
      : ronda > 0 &&
            dados.length == 2 &&
            dados.every((dado) => dado is int && dado >= 1 && dado <= 6);

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

  /// Número de la ronda en juego; 0 hasta que el servidor lanza por primera vez.
  final int ronda;

  /// El único resultado de esta ronda, igual para todos. Vacío en la ronda 0.
  final List<int> dados;

  /// Quiénes ya no deben nada en esta ronda.
  final List<String> jugaron;

  /// Por número de zona, en qué ronda la completó cada jugador. Incluye a quien
  /// ya salió de la partida, porque su lugar sigue ocupado.
  final Map<int, Map<String, int>> zonas;

  /// Puntos para ganar, según cuántos empezaron; 0 antes de comenzar.
  final int meta;

  /// El servidor dio la partida por terminada: ya no hay más rondas.
  final bool terminada;

  /// Quienes ganaron; varios si empataron en puntos.
  final List<String> ganadores;

  bool estaListo(String? usuario) => listos.contains(usuario);

  bool haFinalizado(String? usuario) => finalizados.contains(usuario);

  bool haJugado(String? usuario) => jugaron.contains(usuario);

  /// Quiénes faltan por jugar esta ronda, en orden de llegada.
  List<String> get rondaPendientes =>
      jugadores.where((jugador) => !jugaron.contains(jugador)).toList();

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
