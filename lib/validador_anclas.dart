import 'region.dart';
import 'tablero.dart';

class ValidadorAnclas {
  const ValidadorAnclas(this.tablero);

  final Tablero tablero;

  bool puedeSerAncla(int valor) => tablero.valoresColocados.contains(valor);

  List<MovimientoAncla> obtenerMovimientosPosibles(OpcionAncla opcion) {
    if (!opcion.puedeSeleccionarse || !puedeSerAncla(opcion.ancla)) {
      return const [];
    }

    final movimientos = <MovimientoAncla>[];
    final destinosVistos = <(int, int)>{};
    final posicionesAncla = tablero.celdas
        .where((celda) => celda.valor == opcion.ancla)
        .toList(growable: false);

    for (final ancla in posicionesAncla) {
      for (final destino
          in tablero.obtenerPosicionesAdyacentes(ancla.x, ancla.y)) {
        if (destino.valor != null ||
            !tablero.puedeColocarDato(
              destino.x,
              destino.y,
              opcion.numeroAColocar,
            ) ||
            !destinosVistos.add((destino.x, destino.y))) {
          continue;
        }
        movimientos.add(MovimientoAncla(ancla: ancla, destino: destino));
      }
    }

    return List.unmodifiable(movimientos);
  }

  List<OpcionAncla> obtenerOpciones(int dado1, int dado2) {
    return List.unmodifiable([
      OpcionAncla(
        ancla: dado1,
        numeroAColocar: dado2,
        puedeSeleccionarse: puedeSerAncla(dado1),
      ),
      if (dado2 != dado1)
        OpcionAncla(
          ancla: dado2,
          numeroAColocar: dado1,
          puedeSeleccionarse: puedeSerAncla(dado2),
        ),
    ]);
  }

  List<int> obtenerAnclasPosibles(int dado1, int dado2) {
    return obtenerOpciones(dado1, dado2)
        .where((opcion) => opcion.puedeSeleccionarse)
        .map((opcion) => opcion.ancla)
        .toList(growable: false);
  }
}

class OpcionAncla {
  const OpcionAncla({
    required this.ancla,
    required this.numeroAColocar,
    required this.puedeSeleccionarse,
  });

  final int ancla;
  final int numeroAColocar;
  final bool puedeSeleccionarse;
}

class MovimientoAncla {
  const MovimientoAncla({required this.ancla, required this.destino});

  final Coordenada ancla;
  final Coordenada destino;
}