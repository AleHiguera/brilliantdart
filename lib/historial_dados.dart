class RegistroLanzamiento {
  const RegistroLanzamiento({
    required this.numeroLanzamiento,
    required this.resultadoDado1,
    required this.resultadoDado2,
    this.accionRealizada,
  });

  final int numeroLanzamiento;
  final int resultadoDado1;
  final int resultadoDado2;
  final String? accionRealizada;

  RegistroLanzamiento conAccion(String accion) {
    if (accionRealizada != null) {
      throw StateError('La acción de este lanzamiento ya fue registrada.');
    }

    return RegistroLanzamiento(
      numeroLanzamiento: numeroLanzamiento,
      resultadoDado1: resultadoDado1,
      resultadoDado2: resultadoDado2,
      accionRealizada: accion,
    );
  }
}

class HistorialDados {
  final List<RegistroLanzamiento> _lanzamientos = [];

  List<RegistroLanzamiento> get lanzamientos =>
      List.unmodifiable(_lanzamientos);

  void registrarLanzamiento(int resultadoDado1, int resultadoDado2) {
    _lanzamientos.add(
      RegistroLanzamiento(
        numeroLanzamiento: _lanzamientos.length + 1,
        resultadoDado1: resultadoDado1,
        resultadoDado2: resultadoDado2,
      ),
    );
  }

  void registrarAccion(int numeroLanzamiento, String accionRealizada) {
    final indice = _lanzamientos.indexWhere(
      (lanzamiento) => lanzamiento.numeroLanzamiento == numeroLanzamiento,
    );
    if (indice < 0) {
      throw ArgumentError.value(
        numeroLanzamiento,
        'numeroLanzamiento',
        'No existe ese lanzamiento en el historial.',
      );
    }

    _lanzamientos[indice] =
        _lanzamientos[indice].conAccion(accionRealizada);
  }
}