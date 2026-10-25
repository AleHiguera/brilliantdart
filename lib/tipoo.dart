enum TipoZona { azul, rojo, verde, amarillo, morado, gris, naranja }

abstract class Tipo {
  final TipoZona tipo;
  final String color;
  final String regla;
  final int puntuacion;

  const Tipo._({
    required this.tipo,
    required this.color,
    required this.regla,
    required this.puntuacion,
  });

  factory Tipo({
    required TipoZona tipo,
    required String color,
    required String regla,
    required int puntuacion,
  }) {
    switch (tipo) {
      case TipoZona.azul:
        return TipoAzul(color: color, regla: regla, puntuacion: puntuacion);
      case TipoZona.rojo:
        return TipoRojo(color: color, regla: regla, puntuacion: puntuacion);
      case TipoZona.verde:
        return TipoVerde(color: color, regla: regla, puntuacion: puntuacion);
      case TipoZona.amarillo:
        return TipoAmarillo(color: color, regla: regla, puntuacion: puntuacion);
      case TipoZona.morado:
        return TipoMorado(color: color, regla: regla, puntuacion: puntuacion);
      case TipoZona.gris:
        return TipoGris(color: color, regla: regla, puntuacion: puntuacion);
      case TipoZona.naranja:
        return TipoNaranja(color: color, regla: regla, puntuacion: puntuacion);
    }
  }

  Map<int, int> get puntuaciones;

  bool esPosibleAgregar(List<int> actuales, int posible);

  /// Regla del color para una zona llena: cada color la define a su manera.
  bool validarMovimiento(List<int> valores);

  int calcularPuntuacion([int posicion = 1]) {
    final puntos = puntuaciones[posicion];
    if (puntos == null) {
      throw ArgumentError(
        'La posición $posicion no es válida para este tipo. Debe ser 1, 2 o 3.',
      );
    }
    return puntos;
  }

  String obtenerInformacion() {
    return '''
Tipo: $color
Regla: $regla
Puntuación: $puntuacion
''';
  }
}

class TipoAzul extends Tipo {
  const TipoAzul({
    required super.color,
    required super.regla,
    required super.puntuacion,
  }) : super._(tipo: TipoZona.azul);

  @override
  Map<int, int> get puntuaciones => {1: 7, 2: 5, 3: 3};

  /// Todos los números deben ser iguales.
  @override
  bool validarMovimiento(List<int> valores) =>
      valores.every((numero) => numero == valores.first);

  @override
  bool esPosibleAgregar(List<int> actuales, int posible) {
    if (actuales.isEmpty) {
      return true;
    }
    return actuales.every((valor) => valor == posible);
  }
}

class TipoRojo extends Tipo {
  const TipoRojo({
    required super.color,
    required super.regla,
    required super.puntuacion,
  }) : super._(tipo: TipoZona.rojo);

  @override
  Map<int, int> get puntuaciones => {1: 6, 2: 4, 3: 2};

  /// Todos los números deben ser diferentes.
  @override
  bool validarMovimiento(List<int> valores) =>
      valores.toSet().length == valores.length;

  @override
  bool esPosibleAgregar(List<int> actuales, int posible) {
    return actuales.isEmpty || actuales.every((valor) => valor != posible);
  }
}

class TipoVerde extends Tipo {
  const TipoVerde({
    required super.color,
    required super.regla,
    required super.puntuacion,
  }) : super._(tipo: TipoZona.verde);

  @override
  Map<int, int> get puntuaciones => {1: 4, 2: 3, 3: 2};

  /// Cualquier combinación de números vale.
  @override
  bool validarMovimiento(List<int> valores) => true;

  @override
  bool esPosibleAgregar(List<int> actuales, int posible) {
    return true;
  }
}

class TipoMorado extends Tipo {
  const TipoMorado({
    required super.color,
    required super.regla,
    required super.puntuacion,
  }) : super._(tipo: TipoZona.morado);

  @override
  Map<int, int> get puntuaciones => {1: 6, 2: 4, 3: 2};

  /// Debe tener exactamente dos números distintos.
  @override
  bool validarMovimiento(List<int> valores) => valores.toSet().length == 2;

  @override
  bool esPosibleAgregar(List<int> actuales, int posible) {
    final distintos = actuales.toSet()..add(posible);
    return distintos.length <= 2;
  }
}

class TipoAmarillo extends Tipo {
  const TipoAmarillo({
    required super.color,
    required super.regla,
    required super.puntuacion,
  }) : super._(tipo: TipoZona.amarillo);

  @override
  Map<int, int> get puntuaciones => {1: 8, 2: 6, 3: 4};

  /// Ningún número puede repetirse entre todas las celdas amarillas.
  @override
  bool validarMovimiento(List<int> valores) =>
      valores.toSet().length == valores.length;

  @override
  bool esPosibleAgregar(List<int> actuales, int posible) {
    return actuales.isEmpty || actuales.every((valor) => valor != posible);
  }
}

/// Gris: todas sus celdas llevan el mismo número, aunque estén separadas,
/// porque en el mapa forman una sola zona.
class TipoGris extends Tipo {
  const TipoGris({
    required super.color,
    required super.regla,
    required super.puntuacion,
  }) : super._(tipo: TipoZona.gris);

  @override
  Map<int, int> get puntuaciones => {1: 3, 2: 2, 3: 1};

  /// Todos los números deben ser iguales.
  @override
  bool validarMovimiento(List<int> valores) =>
      valores.every((numero) => numero == valores.first);

  @override
  bool esPosibleAgregar(List<int> actuales, int posible) {
    if (actuales.isEmpty) {
      return true;
    }
    return actuales.every((valor) => valor == posible);
  }
}

/// Naranja: todos sus números deben estar en un rango (por ejemplo, del 4 al
/// 6). Se pueden repetir y no hace falta que aparezcan todos los del rango.
///
/// Cada zona naranja puede tener su propio rango; el mapa lo decide.
class TipoNaranja extends Tipo {
  TipoNaranja({
    required super.color,
    required super.regla,
    required super.puntuacion,
    this.minimo = 1,
    this.maximo = 6,
  }) : super._(tipo: TipoZona.naranja) {
    if (minimo < 1 || maximo > 6 || minimo > maximo) {
      throw ArgumentError(
        'El rango del naranja debe estar entre 1 y 6 (es $minimo a $maximo).',
      );
    }
  }

  /// El número más chico que acepta esta zona.
  final int minimo;

  /// El número más grande que acepta esta zona.
  final int maximo;

  bool _enRango(int numero) => numero >= minimo && numero <= maximo;

  @override
  Map<int, int> get puntuaciones => {1: 6, 2: 4, 3: 3};

  /// Todos los números deben estar dentro del rango.
  @override
  bool validarMovimiento(List<int> valores) => valores.every(_enRango);

  @override
  bool esPosibleAgregar(List<int> actuales, int posible) => _enRango(posible);
}
