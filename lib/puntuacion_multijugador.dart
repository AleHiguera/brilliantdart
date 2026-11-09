import 'lugares_de_zona.dart';
import 'mapa.dart';

/// Los puntos de una partida multijugador, a partir del registro del servidor:
/// en qué ronda completó cada jugador cada zona.
///
/// Cada zona reparte sus propios lugares aunque otra tenga el mismo color. Quien
/// salió de la partida sigue en el registro: conserva sus puntos y su lugar queda
/// ocupado, para que nadie gane ni pierda por una salida ajena.
class PuntuacionMultijugador {
  const PuntuacionMultijugador(this.mapa, this.rondasPorZona);

  final Mapa mapa;

  /// Por número de zona, en qué ronda la completó cada jugador.
  final Map<int, Map<String, int>> rondasPorZona;

  /// El reparto de cada zona del mapa, por su número.
  Map<int, LugaresDeZona> get zonas => {
    for (final zona in mapa.crearTablero().regiones)
      zona.id: LugaresDeZona(zona.tipo, rondasPorZona[zona.id] ?? const {}),
  };

  /// El total de cada jugador que ha completado alguna zona.
  Map<String, int> get puntos {
    final totales = <String, int>{};
    for (final reparto in zonas.values) {
      reparto.puntos.forEach((jugador, puntos) {
        totales[jugador] = (totales[jugador] ?? 0) + puntos;
      });
    }
    return totales;
  }
}
