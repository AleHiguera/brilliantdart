enum TipoZona {
  azul,
  rojo,
  verde,
  amarillo,
  morado,
}

// ==========================================
// CLASE TIPO
// ==========================================

class Tipo {
  final TipoZona tipo;
  final String color;
  final String regla;
  final int puntuacion;

  Tipo({
    required this.tipo,
    required this.color,
    required this.regla,
    required this.puntuacion,
  });

  // ==========================================
  // MÉTODO: VALIDAR MOVIMIENTO
  // ==========================================

  bool validarMovimiento(List<int> valores) {
    switch (tipo) {
      case TipoZona.azul:
        // Todos los números deben ser iguales.
        if (valores.isEmpty) {
          return true;
        }

        return valores.every((numero) => numero == valores.first);

      case TipoZona.rojo:
        // Todos los números deben ser diferentes.
        return valores.toSet().length == valores.length;

      case TipoZona.verde:
        // Los números pueden repetirse.
        return true;

      case TipoZona.amarillo:
        // El amarillo se valida globalmente.
        return true;

      case TipoZona.morado:
        // La zona morada debe usar exactamente dos números
        // distintos, aunque cada uno pueda repetirse.
        return valores.toSet().length == 2;
    }
  }

  // ==========================================
  // MÉTODO: VALIDAR AMARILLO
  // ==========================================

  bool validarAmarillo(List<int> valores) {
    if (tipo != TipoZona.amarillo) {
      return false;
    }

    return valores.toSet().length == valores.length;
  }

  // ==========================================
  // MÉTODO: CALCULAR PUNTUACIÓN
  // ==========================================

  int calcularPuntuacion() {
    return puntuacion;
  }

  // ==========================================
  // MÉTODO: OBTENER INFORMACIÓN DEL TIPO
  // ==========================================

  String obtenerInformacion() {
    return '''
Tipo: $color
Regla: $regla
Puntuación: $puntuacion
''';
  }
}