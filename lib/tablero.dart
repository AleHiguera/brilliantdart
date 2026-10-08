import 'region.dart';

class Tablero {
  static const int filas = 7;
  static const int columnas = 7;

  final List<List<Coordenada>> _celdas;
  final List<Region> _regiones = [];

  Tablero()
      : _celdas = List.generate(
          filas,
          (fila) => List.generate(
            columnas,
            (columna) => Coordenada.xy(fila, columna),
          ),
        );

  List<Region> get regiones => List.unmodifiable(_regiones);

  Set<int> get valoresColocados =>
      celdas.map((celda) => celda.valor).whereType<int>().toSet();

  List<Coordenada> get celdas => [
        for (final fila in _celdas)
          for (final celda in fila)
            celda,
      ];

  Coordenada obtenerCelda(int fila, int columna) {
    _validarCoordenada(fila, columna);
    return _celdas[fila][columna];
  }

  void colocarDato(int fila, int columna, int? dato) {
    obtenerCelda(fila, columna).valor = dato;
  }

  bool puedeColocarDato(int fila, int columna, int dato) {
    if (fila < 0 || fila >= filas || columna < 0 || columna >= columnas) {
      return false;
    }

    if (obtenerCelda(fila, columna).valor != null) {
      return false;
    }

    final zonasDestino = _regiones
        .where((region) => region.contieneCoordenada(fila, columna))
        .toList(growable: false);

    return zonasDestino.isNotEmpty &&
        zonasDestino.every(
          (region) => region.puedeColocarNumero(fila, columna, dato),
        );
  }

  List<Coordenada> obtenerPosicionesAdyacentes(int fila, int columna) {
    _validarCoordenada(fila, columna);

    final vecinas = <(int, int)>[
      (fila - 1, columna),
      (fila + 1, columna),
      (fila, columna - 1),
      (fila, columna + 1),
    ];

    return vecinas
        .where((posicion) =>
            posicion.$1 >= 0 &&
            posicion.$1 < filas &&
            posicion.$2 >= 0 &&
            posicion.$2 < columnas)
        .map((posicion) => obtenerCelda(posicion.$1, posicion.$2))
        .toList(growable: false);
  }

  List<int?> extraerDatos() {
    return [
      for (var fila = 0; fila < filas; fila++)
        for (var columna = columnas - 1; columna >= 0; columna--)
          _celdas[fila][columna].valor,
    ];
  }

  void agregarRegion(Region region) {
    for (final coordenada in region.coordenadas) {
      _validarCoordenada(coordenada.x, coordenada.y);
    }

    if (_regiones.any((actual) => actual.id == region.id)) {
      throw ArgumentError('Ya existe una región con el id ${region.id}.');
    }

    _regiones.add(region);
  }

  List<Coordenada> obtenerCeldasDeRegion(Region region) {
    if (!_regiones.contains(region)) {
      throw ArgumentError('La región no pertenece a este tablero.');
    }

    return region.coordenadas
        .map((coordenada) => obtenerCelda(coordenada.x, coordenada.y))
        .toList(growable: false);
  }

  void _validarCoordenada(int fila, int columna) {
    if (fila < 0 || fila >= filas || columna < 0 || columna >= columnas) {
      throw RangeError(
        'La coordenada ($fila, $columna) está fuera del tablero 7x7.',
      );
    }
  }
}

