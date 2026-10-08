import 'dart:math';

import 'historial_dados.dart';

class Dado {
  Dado(Random random)
      : _random = random,
        valor = random.nextInt(6) + 1;

  final Random _random;
  int valor;

  int lanzar() {
    valor = _random.nextInt(6) + 1;
    return valor;
  }
}

class Dados {
  Dados({Random? random}) : this._(random ?? Random());

  Dados._(Random random)
      : dado1 = Dado(random),
      dado2 = Dado(random),
      historial = HistorialDados();

  final Dado dado1;
  final Dado dado2;
    final HistorialDados historial;

  List<Dado> get dados => List.unmodifiable([dado1, dado2]);

  (int, int) lanzar() {
    final valorDado1 = dado1.lanzar();
    final valorDado2 = dado2.lanzar();
    historial.registrarLanzamiento(valorDado1, valorDado2);
    return (valorDado1, valorDado2);
  }
}