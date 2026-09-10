import 'tipo.dart';

// ==========================================
// CLASE COORDENADA
// ==========================================
//
// Cada coordenada pertenece a una posición
// dentro del tablero 7x7.
//
// El valor puede ser:
// - un número entero
// - null, cuando la casilla está vacía
// ==========================================

class Coordenada {
  final int fila;
  final int columna;
  int? valor;

  Coordenada({
    required this.fila,
    required this.columna,
    this.valor,
  });
}

// ==========================================
// CLASE ZONA
// ==========================================

class Zona {
  final int id;
  final List<Coordenada> coordenadas;
  final Tipo tipo;

  bool completado;

  Zona({
    required this.id,
    required this.coordenadas,
    required this.tipo,
    this.completado = false,
  });

  // ==========================================
  // PROPIEDAD: TAMAÑO DE ZONA
  // ==========================================
  //
  // El tamaño depende de cuántas coordenadas
  // tiene la zona.
  // ==========================================

  int get tamanoZona {
    return coordenadas.length;
  }

  // ==========================================
  // MÉTODO: OBTENER VALORES
  // ==========================================
  //
  // Regresa solamente los números que ya están
  // colocados.
  //
  // Los valores null no se toman en cuenta.
  // ==========================================

  List<int> obtenerValores() {
    return coordenadas
        .where((coordenada) => coordenada.valor != null)
        .map((coordenada) => coordenada.valor!)
        .toList();
  }

  // ==========================================
  // MÉTODO: COLOCAR NÚMERO
  // ==========================================

  void colocarNumero(int fila, int columna, int numero) {
    for (var coordenada in coordenadas) {
      if (coordenada.fila == fila &&
          coordenada.columna == columna) {
        coordenada.valor = numero;
        return;
      }
    }

    throw Exception(
      'La coordenada ($fila, $columna) no pertenece a esta zona.',
    );
  }

  // ==========================================
  // MÉTODO: CONTIENE COORDENADA
  // ==========================================

  bool contieneCoordenada(int fila, int columna) {
    return coordenadas.any(
      (coordenada) =>
          coordenada.fila == fila &&
          coordenada.columna == columna,
    );
  }

  // ==========================================
  // MÉTODO: VERIFICAR COMPLETADO
  // ==========================================
  //
  // Una zona está completa cuando todas sus
  // coordenadas tienen un número.
  //
  // Además, se verifica la regla de su tipo.
  // ==========================================

  bool verificarCompletado() {
    // Si todavía existe una casilla vacía,
    // la zona no está completa.
    if (coordenadas.any((coordenada) => coordenada.valor == null)) {
      completado = false;
      return false;
    }

    final valores = obtenerValores();

    // Validamos según el tipo de zona.
    if (!tipo.validarMovimiento(valores)) {
      completado = false;
      return false;
    }

    completado = true;
    return true;
  }

  // ==========================================
  // MÉTODO: VALIDAR MOVIMIENTO
  // ==========================================

  bool validarMovimiento() {
    return tipo.validarMovimiento(obtenerValores());
  }
}