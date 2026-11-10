import 'tipoo.dart';

/// Reparte los lugares de una zona en una partida multijugador.
///
/// El lugar lo decide la ronda en que cada jugador completó la zona, nunca quién
/// confirmó más rápido dentro de esa ronda. Quienes la completan en la misma
/// ronda empatan, y un empate no gasta lugares: si uno gana el 1.º y dos ganan
/// el 2.º, el 3.º sigue libre para el siguiente.
class LugaresDeZona {
  const LugaresDeZona(this.tipo, this.rondaPorJugador);

  /// La zona que se reparte: de ella salen los puntos de cada lugar.
  final Tipo tipo;

  /// En qué ronda completó la zona cada jugador. Quien no la ha completado no
  /// aparece aquí.
  final Map<String, int> rondaPorJugador;

  /// El lugar de cada jugador que completó la zona, contando desde 1.
  Map<String, int> get lugares {
    final rondas = rondaPorJugador.values.toSet().toList()..sort();
    return {
      for (final MapEntry(key: jugador, value: ronda)
          in rondaPorJugador.entries)
        jugador: rondas.indexOf(ronda) + 1,
    };
  }

  /// El lugar de quien complete la zona en [ronda]. Solo cuentan las rondas
  /// anteriores: si otro la completó en esta misma, se empata con él.
  int lugarEnRonda(int ronda) =>
      rondaPorJugador.values.where((otra) => otra < ronda).toSet().length + 1;

  /// Cuánto vale la zona para quien la complete en [ronda].
  int puntosEnRonda(int ronda) => tipo.puntosDeLugar(lugarEnRonda(ronda));

  /// Los puntos que gana cada jugador que completó la zona. Cada uno recibe
  /// los puntos completos de su lugar, aunque lo comparta.
  Map<String, int> get puntos => {
    for (final MapEntry(key: jugador, value: lugar) in lugares.entries)
      jugador: tipo.puntosDeLugar(lugar),
  };
}
