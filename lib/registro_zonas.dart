import 'puntuacion_multijugador.dart';
import 'tipoo.dart';

/// Un jugador que completó una zona: en qué ronda, en qué lugar quedó y
/// cuántos puntos le dio.
typedef ZonaLograda = ({
  int zona,
  TipoZona tipo,
  String jugador,
  int ronda,
  int lugar,
  int puntos,
});

/// Quién completó cada zona de la partida, para mostrarlo como un historial:
/// lo más reciente primero. Dentro de una misma ronda, por número de zona y
/// por lugar. Sale del registro del servidor, igual para todos los jugadores.
class RegistroZonas {
  const RegistroZonas(this.puntuacion);

  final PuntuacionMultijugador puntuacion;

  List<ZonaLograda> get entradas {
    final entradas = [
      for (final MapEntry(key: zona, value: reparto)
          in puntuacion.zonas.entries)
        for (final MapEntry(key: jugador, value: lugar)
            in reparto.lugares.entries)
          (
            zona: zona,
            tipo: reparto.tipo.tipo,
            jugador: jugador,
            ronda: reparto.rondaPorJugador[jugador]!,
            lugar: lugar,
            puntos: reparto.tipo.puntosDeLugar(lugar),
          ),
    ];
    entradas.sort((a, b) {
      final porRonda = b.ronda.compareTo(a.ronda);
      if (porRonda != 0) return porRonda;
      final porZona = a.zona.compareTo(b.zona);
      if (porZona != 0) return porZona;
      return a.lugar.compareTo(b.lugar);
    });
    return entradas;
  }
}
