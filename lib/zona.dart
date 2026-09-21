import 'region.dart';

export 'region.dart' show Coordenada;

// ==========================================
// CLASE ZONA
// ==========================================

class Zona extends Region {
  Zona({
    required super.id,
    required super.coordenadas,
    required super.tipo,
    super.completado,
  }) : super();

  // ==========================================
  // PROPIEDAD: TAMAÑO DE ZONA
  // ==========================================
  //
  // El tamaño depende de cuántas coordenadas
  // tiene la zona.
  // ==========================================

  int get tamanoZona => tamanoRegion;

  // ==========================================
  // MÉTODO: COLOCAR NÚMERO
  // ==========================================

  void colocarNumero(int fila, int columna, int numero) {
    for (var coordenada in coordenadas) {
      if (coordenada.x == fila && coordenada.y == columna) {
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

  @override
  bool verificarCompletado() {
  //
  // Una zona está completa cuando todas sus
  // coordenadas tienen un número.
  //
  // Además, se verifica la regla de su tipo.
  // ==========================================

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