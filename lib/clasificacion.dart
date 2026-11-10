/// Un jugador en la clasificación final.
typedef Puesto = ({int lugar, String jugador, int puntos, bool salio});

/// Clasificación final de una partida multijugador: de más a menos puntos.
///
/// Los empatados en puntos comparten el lugar y, como en las zonas, el empate
/// no gasta lugares: dos en 2.º y el siguiente es 3.º. El primer lugar es de
/// quien ganó, porque el ganador es siempre quien tiene más puntos: si varios
/// llegan a la meta en la misma ronda, gana el que hizo más.
class Clasificacion {
  const Clasificacion({required this.puntos, required this.jugadores});

  /// Los puntos de quien completó alguna zona, aunque ya haya salido.
  final Map<String, int> puntos;

  /// Quienes siguen en la partida, en orden de llegada.
  final List<String> jugadores;

  List<Puesto> get puestos {
    // Quien salió con puntos sigue en la clasificación: sus puntos no se pierden.
    final todos = [
      ...jugadores,
      ...puntos.keys.where((jugador) => !jugadores.contains(jugador)),
    ];
    int puntosDe(String jugador) => puntos[jugador] ?? 0;
    // Con los mismos puntos se respeta el orden de llegada, para que la lista
    // salga igual en todos los celulares.
    final enOrden =
        [for (final (indice, jugador) in todos.indexed) (indice, jugador)]
          ..sort((a, b) {
            final porPuntos = puntosDe(b.$2).compareTo(puntosDe(a.$2));
            return porPuntos != 0 ? porPuntos : a.$1.compareTo(b.$1);
          });
    final distintos = todos.map(puntosDe).toSet().toList()
      ..sort((a, b) => b.compareTo(a));

    return [
      for (final (_, jugador) in enOrden)
        (
          lugar: distintos.indexOf(puntosDe(jugador)) + 1,
          jugador: jugador,
          puntos: puntosDe(jugador),
          salio: !jugadores.contains(jugador),
        ),
    ];
  }

  /// El lugar de ese jugador, o null si no está en la partida.
  int? lugarDe(String? jugador) {
    for (final puesto in puestos) {
      if (puesto.jugador == jugador) return puesto.lugar;
    }
    return null;
  }
}
