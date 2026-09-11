enum TipoZona {
  azul,
  rojo,
  verde,
  amarillo,
  morado,
}

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
        return TipoAzul(
          color: color,
          regla: regla,
          puntuacion: puntuacion,
        );
      case TipoZona.rojo:
        return TipoRojo(
          color: color,
          regla: regla,
          puntuacion: puntuacion,
        );
      case TipoZona.verde:
        return TipoVerde(
          color: color,
          regla: regla,
          puntuacion: puntuacion,
        );
      case TipoZona.amarillo:
        return TipoAmarillo(
          color: color,
          regla: regla,
          puntuacion: puntuacion,
        );
      case TipoZona.morado:
        return TipoMorado(
          color: color,
          regla: regla,
          puntuacion: puntuacion,
        );
    }
  }

  Map<int, int> get puntuaciones;

  bool esPosibleAgregar(List<int> actuales, int posible);

  bool validarMovimiento(List<int> valores) {
    switch (tipo) {
      case TipoZona.azul:
        if (valores.isEmpty) {
          return true;
        }
        return valores.every((numero) => numero == valores.first);

      case TipoZona.rojo:
        return valores.toSet().length == valores.length;

      case TipoZona.verde:
        return true;

      case TipoZona.amarillo:
        return true;

      case TipoZona.morado:
        return valores.toSet().length == 2;
    }
  }

  bool validarAmarillo(List<int> valores) {
    if (tipo != TipoZona.amarillo) {
      return false;
    }
    return valores.toSet().length == valores.length;
  }

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
  Map<int, int> get puntuaciones => {
        1: 7,
        2: 5,
        3: 3,
      };

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
  Map<int, int> get puntuaciones => {
        1: 6,
        2: 4,
        3: 2,
      };

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
  Map<int, int> get puntuaciones => {
        1: 4,
        2: 3,
        3: 2,
      };

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
  Map<int, int> get puntuaciones => {
        1: 8,
        2: 6,
        3: 4,
      };

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
  Map<int, int> get puntuaciones => {
        1: 8,
        2: 6,
        3: 4,
      };

  @override
  bool esPosibleAgregar(List<int> actuales, int posible) {
    return actuales.isEmpty || actuales.every((valor) => valor != posible);
  }
}