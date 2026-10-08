class RegistroLanzamiento {
  const RegistroLanzamiento({
    required this.numeroLanzamiento,
    required this.resultadoDado1,
    required this.resultadoDado2,
  });

  final int numeroLanzamiento;
  final int resultadoDado1;
  final int resultadoDado2;
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
}