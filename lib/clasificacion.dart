/// Un jugador en la clasificación final.
typedef Puesto = ({int lugar, String jugador, int puntos, bool salio});

/// Clasificación final de una partida multijugador: de más a menos puntos.
///
/// Los empatados en puntos comparten el lugar y, como en las zonas, el empate
/// no gasta lugares: dos en 2.º y el siguiente es 3.º. El primer lugar es de
/// quien ganó, porque el ganador es siempre quien tiene más puntos: si varios
/// llegan a la meta en la misma ronda, gana el que hizo más.
///
/// La excepción es ganar por abandono: si los demás salieron, gana quien se
/// quedó aunque tenga menos puntos. Por eso se pueden indicar los [ganadores]:
/// van primero, y los demás siguen desde el 2.º lugar, de más a menos puntos.
class Clasificacion {
  const Clasificacion({
    required this.puntos,
    required this.jugadores,
    this.ganadores = const [],
  });

  /// Los puntos de quien completó alguna zona, aunque ya haya salido.
  final Map<String, int> puntos;

  /// Quienes siguen en la partida, en orden de llegada.
  final List<String> jugadores;

  /// Quienes ganaron según el servidor. Vacío, gana quien tenga más puntos.
  final List<String> ganadores;

  List<Puesto> get puestos {
    // Quien salió con puntos sigue en la clasificación: sus puntos no se pierden.
    final todos = [
      ...jugadores,
      ...puntos.keys.where((jugador) => !jugadores.contains(jugador)),
    ];
    final primeros = todos.where(ganadores.contains).toList();
    final resto = todos.where((jugador) => !primeros.contains(jugador));
    int puntosDe(String jugador) => puntos[jugador] ?? 0;
    // Con los mismos puntos se respeta el orden de llegada, para que la lista
    // salga igual en todos los celulares.
    final enOrden =
        [for (final (indice, jugador) in resto.indexed) (indice, jugador)]
          ..sort((a, b) {
            final porPuntos = puntosDe(b.$2).compareTo(puntosDe(a.$2));
            return porPuntos != 0 ? porPuntos : a.$1.compareTo(b.$1);
          });
    final distintos = resto.map(puntosDe).toSet().toList()
      ..sort((a, b) => b.compareTo(a));
    // Con ganadores aparte, el resto empieza en el 2.º lugar.
    final desde = primeros.isEmpty ? 1 : 2;

    Puesto puesto(String jugador, int lugar) => (
      lugar: lugar,
      jugador: jugador,
      puntos: puntosDe(jugador),
      salio: !jugadores.contains(jugador),
    );

    return [
      for (final jugador in primeros) puesto(jugador, 1),
      for (final (_, jugador) in enOrden)
        puesto(jugador, desde + distintos.indexOf(puntosDe(jugador))),
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
