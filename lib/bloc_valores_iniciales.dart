import 'tablero.dart';

enum EstadoInicialPartida {
  bloqueado,
  inicializado,
  jugando,
}

class BlocValoresIniciales {
  BlocValoresIniciales(this.tablero);

  final Tablero tablero;
  EstadoInicialPartida _estado = EstadoInicialPartida.bloqueado;

  static const List<(int, int)> celdasIniciales = [
    (1, 3),
    (2, 6),
    (4, 2),
    (4, 5),
    (6, 3),
    (7, 5),
  ];

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
