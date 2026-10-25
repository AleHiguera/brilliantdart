import 'tipoo.dart';

/// Qué color significa cada letra de un dibujo de mapa:
/// M = morado, G = gris, V = verde, A = amarillo, R = rojo, Z = azul,
/// N = naranja.
const Map<String, TipoZona> letrasDeColores = {
  'M': TipoZona.morado,
  'G': TipoZona.gris,
  'V': TipoZona.verde,
  'A': TipoZona.amarillo,
  'R': TipoZona.rojo,
  'Z': TipoZona.azul,
  'N': TipoZona.naranja,
};

/// Convierte un dibujo escrito con letras (una fila por texto, como en el
/// papel) en los colores de cada celda. Su única tarea es traducir letras.
List<List<TipoZona>> leerDibujo(List<String> filas) => List.unmodifiable([
  for (final fila in filas)
    List<TipoZona>.unmodifiable([
      for (final letra in fila.split(''))
        letrasDeColores[letra] ??
            (throw ArgumentError.value(
              letra,
              'letra',
              'No es un color. Usa M, G, V, A, R, Z o N.',
            )),
    ]),
]);
