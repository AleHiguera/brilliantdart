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
///
/// Qué regla y cuántos puntos tiene cada color lo decide [crearTipo], que
/// entrega cada mapa.
class ConstructorTablero {
  const ConstructorTablero({
    required this.tiposPorCelda,
    required this.crearTipo,
    this.tiposUnidos = const {},
  });

  final List<List<TipoZona>> tiposPorCelda;
  final Tipo Function(TipoZona tipo) crearTipo;
  final Set<TipoZona> tiposUnidos;

  Tablero construir() {
    _validarDimensiones();

    final tablero = Tablero();
    final visitadas = <(int, int)>{};
    var siguienteId = 1;

    for (var fila = 0; fila < Tablero.filas; fila++) {
      for (var columna = 0; columna < Tablero.columnas; columna++) {
        final tipoZona = tiposPorCelda[fila][columna];
        if (visitadas.contains((fila, columna))) continue;

        final posiciones = tiposUnidos.contains(tipoZona)
            ? _obtenerTodasLasPosicionesDe(tipoZona, visitadas)
            : _obtenerComponente(fila, columna, tipoZona, visitadas);

        tablero.agregarRegion(
          Zona(
            id: siguienteId++,
            tipo: crearTipo(tipoZona),
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

  void _validarDimensiones() {
    if (tiposPorCelda.length != Tablero.filas ||
        tiposPorCelda.any((fila) => fila.length != Tablero.columnas)) {
      throw ArgumentError(
        'El dibujo del mapa debe tener ${Tablero.filas} filas de '
        '${Tablero.columnas} columnas.',
      );
    }
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
