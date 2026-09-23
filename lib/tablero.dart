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

class BlocValoresIniciales {
  BlocValoresIniciales(this.tablero);

  final Tablero tablero;

  static const List<(int, int)> celdasIniciales = [
    (1, 3),
    (2, 6),
    (4, 2),
    (4, 5),
    (6, 3),
    (7, 5),
  ];

  bool get bloqueado => !puedeIniciar;

  bool get puedeIniciar => _validarValoresIniciales();

  void validarAntesDeIniciar() {
    if (!puedeIniciar) {
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