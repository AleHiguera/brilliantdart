import 'tablero.dart';
import 'tipoo.dart';
import 'zona.dart';

class MapaUno {
  static const List<List<TipoZona>> tiposPorCelda = [
    [TipoZona.amarillo, TipoZona.verde, TipoZona.azul, TipoZona.morado, TipoZona.morado, TipoZona.morado, TipoZona.amarillo],
    [TipoZona.verde, TipoZona.verde, TipoZona.azul, TipoZona.azul, TipoZona.morado, TipoZona.morado, TipoZona.verde],
    [TipoZona.verde, TipoZona.rojo, TipoZona.rojo, TipoZona.azul, TipoZona.morado, TipoZona.verde, TipoZona.verde],
    [TipoZona.verde, TipoZona.rojo, TipoZona.morado, TipoZona.amarillo, TipoZona.verde, TipoZona.verde, TipoZona.verde],
    [TipoZona.verde, TipoZona.rojo, TipoZona.morado, TipoZona.morado, TipoZona.rojo, TipoZona.rojo, TipoZona.azul],
    [TipoZona.rojo, TipoZona.rojo, TipoZona.morado, TipoZona.rojo, TipoZona.rojo, TipoZona.azul, TipoZona.azul],
    [TipoZona.amarillo, TipoZona.morado, TipoZona.morado, TipoZona.rojo, TipoZona.rojo, TipoZona.azul, TipoZona.amarillo],
  ];

  static Tablero crearTablero() {
    final tablero = Tablero();
    final visitadas = <(int, int)>{};
    var siguienteId = 1;

    for (var fila = 0; fila < Tablero.filas; fila++) {
      for (var columna = 0; columna < Tablero.columnas; columna++) {
        final tipoZona = tiposPorCelda[fila][columna];
        if (visitadas.contains((fila, columna))) continue;

        final posiciones = tipoZona == TipoZona.amarillo
            ? _obtenerTodasLasPosicionesAmarillas(visitadas)
            : _obtenerComponente(fila, columna, tipoZona, visitadas);

        tablero.agregarRegion(
          Zona(
            id: siguienteId++,
            tipo: _crearTipo(tipoZona),
            coordenadas: posiciones
                .map((posicion) =>
                    tablero.obtenerCelda(posicion.$1, posicion.$2))
                .toList(growable: false),
          ),
        );
      }
    }

    return tablero;
  }

  static List<(int, int)> _obtenerTodasLasPosicionesAmarillas(
    Set<(int, int)> visitadas,
  ) {
    final posiciones = <(int, int)>[];
    for (var fila = 0; fila < Tablero.filas; fila++) {
      for (var columna = 0; columna < Tablero.columnas; columna++) {
        if (tiposPorCelda[fila][columna] == TipoZona.amarillo) {
          final posicion = (fila, columna);
          if (visitadas.add(posicion)) posiciones.add(posicion);
        }
      }
    }
    return posiciones;
  }

  static List<(int, int)> _obtenerComponente(
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

  static Tipo _crearTipo(TipoZona tipoZona) {
    return switch (tipoZona) {
      TipoZona.azul => Tipo(
          tipo: TipoZona.azul,
          color: 'Azul',
          regla: 'Todos los numeros deben ser iguales',
          puntuacion: 7,
        ),
      TipoZona.rojo => Tipo(
          tipo: TipoZona.rojo,
          color: 'Rojo',
          regla: 'Todos los numeros deben ser diferentes',
          puntuacion: 6,
        ),
      TipoZona.verde => Tipo(
          tipo: TipoZona.verde,
          color: 'Verde',
          regla: 'Los numeros pueden repetirse',
          puntuacion: 4,
        ),
      TipoZona.amarillo => Tipo(
          tipo: TipoZona.amarillo,
          color: 'Amarillo',
          regla: 'Ningun numero puede repetirse entre las zonas amarillas',
          puntuacion: 8,
        ),
      TipoZona.morado => Tipo(
          tipo: TipoZona.morado,
          color: 'Morado',
          regla: 'Debe contener exactamente dos numeros diferentes',
          puntuacion: 8,
        ),
    };
  }
}