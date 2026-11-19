import 'tablero.dart';

/// El tablero escrito como texto para mandarlo al servidor: 49 cifras, fila
/// por fila (7 filas de 7 columnas), con el número de cada celda o 0 si está
/// vacía. Así el servidor puede guardarlo y enseñarlo al final de la partida
/// sin saber nada de mapas ni de reglas.
class TableroTexto {
  const TableroTexto._();

  static const int lado = 7;
  static const int celdas = lado * lado;

  static String escribir(Tablero tablero) => [
    for (var fila = 0; fila < lado; fila++)
      for (var columna = 0; columna < lado; columna++)
        '${tablero.obtenerCelda(fila, columna).valor ?? 0}',
  ].join();

  /// Los números celda por celda (null si está vacía), o null si el texto no
  /// es un tablero válido.
  static List<int?>? leer(String texto) {
    if (texto.length != celdas) return null;
    final numeros = <int?>[];
    for (final cifra in texto.split('')) {
      final numero = int.tryParse(cifra);
      if (numero == null || numero < 0 || numero > 6) return null;
      numeros.add(numero == 0 ? null : numero);
    }
    return numeros;
  }
}
