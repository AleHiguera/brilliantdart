import 'tablero.dart';
import 'tipoo.dart';
import 'zona.dart';

/// Convierte el dibujo de colores de un mapa en un [Tablero] con sus zonas.
///
/// Su única responsabilidad es agrupar celdas en zonas:
/// - Las celdas vecinas (arriba, abajo, izquierda, derecha) del mismo color
///   forman una zona.
/// - Los colores de [tiposUnidos] forman una sola zona con todas sus celdas,
///   aunque estén separadas (por ejemplo, el amarillo).
/// - Cada grupo de [partesUnidas] junta en una sola zona los pedazos que
///   contienen esas celdas, aunque estén separados (por ejemplo, los dos
///   morados de abajo del Mapa 3), sin unir los demás pedazos de ese color.
///
/// Qué regla y cuántos puntos tiene cada color lo decide [crearTipo], que
/// entrega cada mapa. Si una zona necesita una regla propia (por ejemplo, los
/// dos naranjas del Mapa 4), el mapa entrega [crearTipoDeZona], que además
/// recibe las celdas de la zona.
class ConstructorTablero {
  const ConstructorTablero({
    required this.tiposPorCelda,
    required this.crearTipo,
    this.tiposUnidos = const {},
    this.partesUnidas = const [],
    this.crearTipoDeZona,
  });

  final List<List<TipoZona>> tiposPorCelda;
  final Tipo Function(TipoZona tipo) crearTipo;
  final Set<TipoZona> tiposUnidos;

  /// Grupos de celdas (filas y columnas desde 0), una celda por pedazo:
  /// los pedazos de cada grupo forman una sola zona.
  final List<List<(int, int)>> partesUnidas;

  /// Opcional: regla y puntos de una zona según su color y sus celdas
  /// (filas y columnas desde 0). Si no se da, se usa [crearTipo].
  final Tipo Function(TipoZona tipo, List<(int, int)> posiciones)?
  crearTipoDeZona;

  Tablero construir() {
    _validarDimensiones();
    _validarPartesUnidas();

    final tablero = Tablero();
    final visitadas = <(int, int)>{};
    var siguienteId = 1;

    for (var fila = 0; fila < Tablero.filas; fila++) {
      for (var columna = 0; columna < Tablero.columnas; columna++) {
        final tipoZona = tiposPorCelda[fila][columna];
        if (visitadas.contains((fila, columna))) continue;

        final posiciones = tiposUnidos.contains(tipoZona)
            ? _obtenerTodasLasPosicionesDe(tipoZona, visitadas)
            : _obtenerPedazosUnidos(fila, columna, tipoZona, visitadas);

        tablero.agregarRegion(
          Zona(
            id: siguienteId++,
            tipo: _crearTipo(tipoZona, posiciones),
            coordenadas: posiciones
                .map(
                  (posicion) => tablero.obtenerCelda(posicion.$1, posicion.$2),
                )
                .toList(growable: false),
          ),
        );
      }
    }

    return tablero;
  }

  Tipo _crearTipo(TipoZona tipoZona, List<(int, int)> posiciones) {
    final porZona = crearTipoDeZona;
    return porZona == null
        ? crearTipo(tipoZona)
        : porZona(tipoZona, List.unmodifiable(posiciones));
  }

  void _validarDimensiones() {
    if (tiposPorCelda.length != Tablero.filas ||
        tiposPorCelda.any((fila) => fila.length != Tablero.columnas)) {
      throw ArgumentError(
        'El dibujo del mapa debe tener ${Tablero.filas} filas de '
        '${Tablero.columnas} columnas.',
      );
    }
  }

  void _validarPartesUnidas() {
    for (final grupo in partesUnidas) {
      if (grupo.length < 2) {
        throw ArgumentError.value(
          grupo,
          'partesUnidas',
          'Cada grupo debe tener al menos 2 celdas.',
        );
      }
      for (final (fila, columna) in grupo) {
        if (fila < 0 ||
            fila >= Tablero.filas ||
            columna < 0 ||
            columna >= Tablero.columnas) {
          throw RangeError(
            'La celda ($fila, $columna) de partesUnidas está fuera del tablero.',
          );
        }
      }
      final colores = {
        for (final (fila, columna) in grupo) tiposPorCelda[fila][columna],
      };
      if (colores.length != 1) {
        throw ArgumentError.value(
          grupo,
          'partesUnidas',
          'Todas las celdas de un grupo deben ser del mismo color.',
        );
      }
    }
  }

  /// El pedazo de la celda indicada, junto con los pedazos con los que
  /// [partesUnidas] dice que se une.
  List<(int, int)> _obtenerPedazosUnidos(
    int fila,
    int columna,
    TipoZona tipoZona,
    Set<(int, int)> visitadas,
  ) {
    final posiciones = _obtenerComponente(fila, columna, tipoZona, visitadas);

    for (var indice = 0; indice < posiciones.length; indice++) {
      for (final grupo in partesUnidas) {
        if (!grupo.contains(posiciones[indice])) continue;
        for (final (otraFila, otraColumna) in grupo) {
          if (visitadas.contains((otraFila, otraColumna))) continue;
          posiciones.addAll(
            _obtenerComponente(otraFila, otraColumna, tipoZona, visitadas),
          );
        }
      }
    }

    return posiciones;
  }

  List<(int, int)> _obtenerTodasLasPosicionesDe(
    TipoZona tipoZona,
    Set<(int, int)> visitadas,
  ) {
    final posiciones = <(int, int)>[];
    for (var fila = 0; fila < Tablero.filas; fila++) {
      for (var columna = 0; columna < Tablero.columnas; columna++) {
        if (tiposPorCelda[fila][columna] == tipoZona) {
          final posicion = (fila, columna);
          if (visitadas.add(posicion)) posiciones.add(posicion);
        }
      }
    }
    return posiciones;
  }

  List<(int, int)> _obtenerComponente(
    int filaInicial,
    int columnaInicial,
    TipoZona tipoZona,
    Set<(int, int)> visitadas,
  ) {
    final pendientes = <(int, int)>[(filaInicial, columnaInicial)];
    final posiciones = <(int, int)>[];
    visitadas.add((filaInicial, columnaInicial));

    for (var indice = 0; indice < pendientes.length; indice++) {
      final (fila, columna) = pendientes[indice];
      posiciones.add((fila, columna));

      for (final vecina in <(int, int)>[
        (fila - 1, columna),
        (fila + 1, columna),
        (fila, columna - 1),
        (fila, columna + 1),
      ]) {
        if (vecina.$1 < 0 ||
            vecina.$1 >= Tablero.filas ||
            vecina.$2 < 0 ||
            vecina.$2 >= Tablero.columnas ||
            tiposPorCelda[vecina.$1][vecina.$2] != tipoZona ||
            !visitadas.add(vecina)) {
          continue;
        }
        pendientes.add(vecina);
      }
    }

    return posiciones;
  }
}
