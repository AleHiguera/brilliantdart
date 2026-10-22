import 'tablero.dart';

enum EstadoInicialPartida { bloqueado, inicializado, jugando }

class BlocValoresIniciales {
  /// [celdasIniciales] son las 6 celdas del mapa donde van los números
  /// iniciales, contando filas y columnas desde 1.
  BlocValoresIniciales(
    this.tablero, {
    required List<(int, int)> celdasIniciales,
  }) : celdasIniciales = List.unmodifiable(celdasIniciales) {
    if (this.celdasIniciales.length != 6 ||
        this.celdasIniciales.toSet().length != 6) {
      throw ArgumentError.value(
        celdasIniciales,
        'celdasIniciales',
        'Deben ser 6 celdas distintas, una por cada número del 1 al 6.',
      );
    }
  }

  final Tablero tablero;
  final List<(int, int)> celdasIniciales;
  EstadoInicialPartida _estado = EstadoInicialPartida.bloqueado;

  EstadoInicialPartida get estado => _actualizarEstado();

  bool get bloqueado => estado == EstadoInicialPartida.bloqueado;

  bool get puedeIniciar => estado == EstadoInicialPartida.inicializado;

  bool get jugando => estado == EstadoInicialPartida.jugando;

  void colocarValorInicial(int fila, int columna, int? valor) {
    final esCeldaInicial = celdasIniciales.any(
      (celda) => celda.$1 == fila && celda.$2 == columna,
    );
    if (!esCeldaInicial) {
      throw ArgumentError('La celda ($fila, $columna) no es inicial.');
    }
    if (valor != null && (valor < 1 || valor > 6)) {
      throw ArgumentError.value(valor, 'valor', 'Debe estar entre 1 y 6.');
    }

    if (valor != null) {
      for (final (otraFila, otraColumna) in celdasIniciales) {
        if (otraFila == fila && otraColumna == columna) continue;
        final otraCelda = tablero.obtenerCelda(otraFila - 1, otraColumna - 1);
        if (otraCelda.valor == valor) {
          otraCelda.valor = null;
        }
      }
    }

    tablero.colocarDato(fila - 1, columna - 1, valor);
  }

  void iniciarPartida() {
    if (estado != EstadoInicialPartida.inicializado) {
      throw StateError(
        'La partida no puede iniciar hasta que las celdas iniciales sean válidas.',
      );
    }

    _estado = EstadoInicialPartida.jugando;
  }

  void reiniciar() {
    _estado = EstadoInicialPartida.bloqueado;
  }

  void validarAntesDeIniciar() {
    if (estado != EstadoInicialPartida.inicializado) {
      throw StateError(
        'Debes completar los valores iniciales antes de iniciar la partida.',
      );
    }
  }

  List<int> obtenerValoresIniciales() {
    final valores = <int>[];

    for (final (fila, columna) in celdasIniciales) {
      final valor = tablero.obtenerCelda(fila - 1, columna - 1).valor;
      if (valor == null) {
        return const [];
      }
      valores.add(valor);
    }

    return valores;
  }

  EstadoInicialPartida _actualizarEstado() {
    if (_validarValoresIniciales()) {
      if (_estado == EstadoInicialPartida.jugando) {
        return EstadoInicialPartida.jugando;
      }
      return EstadoInicialPartida.inicializado;
    }

    return EstadoInicialPartida.bloqueado;
  }

  bool _validarValoresIniciales() {
    final valores = obtenerValoresIniciales();
    if (valores.length != celdasIniciales.length) {
      return false;
    }

    final conjunto = valores.toSet();
    if (conjunto.length != celdasIniciales.length) {
      return false;
    }

    final esperados = List<int>.generate(6, (index) => index + 1);
    return conjunto.containsAll(esperados);
  }
}
