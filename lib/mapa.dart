import 'constructor_tablero.dart';
import 'tablero.dart';
import 'tipoo.dart';

/// Describe un mapa del juego: su dibujo de colores, qué regla y cuántos
/// puntos tiene cada color y dónde van los números iniciales.
///
/// Su única responsabilidad es describir. El tablero con sus zonas lo arma
/// [ConstructorTablero] a partir de esta descripción.
abstract class Mapa {
  const Mapa();

  /// Número con el que el jugador elige el mapa (1, 2, 3...).
  int get numero;

  /// Color de cada celda, fila por fila (7 filas de 7 columnas).
  List<List<TipoZona>> get tiposPorCelda;

  /// Las 6 celdas de los números iniciales, contando filas y columnas desde 1.
  List<(int, int)> get celdasIniciales;

  /// Colores cuyas celdas forman una sola zona aunque estén separadas.
  Set<TipoZona> get tiposUnidos;

  /// Regla y puntos de un color en este mapa.
  Tipo crearTipo(TipoZona tipo);

  /// Colores que aparecen en el dibujo, en el orden de [TipoZona].
  List<TipoZona> get tiposPresentes {
    final presentes = {for (final fila in tiposPorCelda) ...fila};
    return [
      for (final tipo in TipoZona.values)
        if (presentes.contains(tipo)) tipo,
    ];
  }

  /// Color de la celda indicada (filas y columnas desde 0).
  TipoZona tipoEn(int fila, int columna) => tiposPorCelda[fila][columna];

  Tablero crearTablero() => ConstructorTablero(
    tiposPorCelda: tiposPorCelda,
    crearTipo: crearTipo,
    tiposUnidos: tiposUnidos,
  ).construir();
}
