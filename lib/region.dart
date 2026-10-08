import 'tipoo.dart';

abstract class Region {
  final int id;
  final List<Coordenada> coordenadas;
  final Tipo tipo;

  bool completado;

  Region({
    required this.id,
    required List<Coordenada> coordenadas,
    required this.tipo,
    this.completado = false,
  }) : coordenadas = List.unmodifiable(coordenadas) {
    final posiciones = <String>{};
    for (final coordenada in this.coordenadas) {
      final posicion = '${coordenada.x}:${coordenada.y}';
      if (!posiciones.add(posicion)) {
        throw ArgumentError(
          'La coordenada (${coordenada.x}, ${coordenada.y}) está duplicada.',
        );
      }
    }
  }

  int get tamanoRegion => coordenadas.length;

  List<int> obtenerValores() {
    return coordenadas
        .where((coordenada) => coordenada.valor != null)
        .map((coordenada) => coordenada.valor!)
        .toList();
  }

  bool contieneCoordenada(int x, int y) {
    return coordenadas.any(
      (coordenada) => coordenada.x == x && coordenada.y == y,
    );
  }

  bool puedeColocarNumero(int fila, int columna, int numero) {
    final indiceDestino = coordenadas.indexWhere(
      (coordenada) => coordenada.x == fila && coordenada.y == columna,
    );
    if (indiceDestino < 0 || coordenadas[indiceDestino].valor != null) {
      return false;
    }

    final valoresActuales = obtenerValores();
    if (!tipo.esPosibleAgregar(valoresActuales, numero)) {
      return false;
    }

    final valoresDespuesDeColocar = [...valoresActuales, numero];
    final espaciosRestantes = coordenadas
        .where((coordenada) => coordenada.valor == null)
        .length -
      1;
    return espaciosRestantes > 0 ||
      tipo.validarMovimiento(valoresDespuesDeColocar);
  }

  bool verificarCompletado();
}

class Coordenada {
  final int x;
  final int y;
  int? valor;

  Coordenada({
    required int fila,
    required int columna,
    this.valor,
  })  : x = fila,
        y = columna;

  Coordenada.xy(this.x, this.y, {this.valor});

  int get fila => x;
  int get columna => y;
}