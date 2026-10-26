import 'dibujo_mapa.dart';
import 'mapa.dart';
import 'tipoo.dart';

/// El Mapa 4, listo para usar.
const mapaCuatro = MapaCuatro();

/// Descripción del Mapa 4: su dibujo, sus puntos y sus celdas iniciales.
///
/// Es de un solo jugador, así que cada color suma su primer puntaje (el más
/// alto): amarillo 8, rojo 6, azul 8, verde 3, morado 7 y naranja 6.
class MapaCuatro extends Mapa {
  const MapaCuatro();

  /// El dibujo tal como está en el papel, una letra por celda:
  /// M = morado, V = verde, A = amarillo, R = rojo, Z = azul, N = naranja.
  static const List<String> dibujo = [
    'NNNNNNN',
    'ARZVZRA',
    'RRMMMRR',
    'AVZMZVA',
    'RRMMMRR',
    'ARZVZRA',
    'NNNNNNN',
  ];

  static final List<List<TipoZona>> _tiposPorCelda = leerDibujo(dibujo);

  @override
  int get numero => 4;

  @override
  List<List<TipoZona>> get tiposPorCelda => _tiposPorCelda;

  @override
  List<(int, int)> get celdasIniciales => const [
    (1, 5),
    (3, 3),
    (3, 6),
    (4, 1),
    (6, 5),
    (7, 2),
  ];

  /// Los amarillos, los azules y los verdes forman cada uno una sola zona
  /// aunque estén separados.
  @override
  Set<TipoZona> get tiposUnidos => const {
    TipoZona.amarillo,
    TipoZona.azul,
    TipoZona.verde,
  };

  /// Los dos pedazos rojos de la izquierda son una zona, y los dos de la
  /// derecha son otra.
  @override
  List<List<(int, int)>> get partesUnidas => const [
    [(3, 1), (5, 1)],
    [(3, 7), (5, 7)],
  ];

  /// El naranja de arriba (fila 1) solo acepta del 4 al 6 y el de abajo
  /// (fila 7) solo del 1 al 3. Los dos valen 6 puntos.
  @override
  Tipo crearTipoDeZona(TipoZona tipo, List<(int, int)> celdas) {
    if (tipo != TipoZona.naranja) return crearTipo(tipo);
    final arriba = celdas.first.$1 == 1;
    return arriba ? _naranja(4, 6) : _naranja(1, 3);
  }

  TipoNaranja _naranja(int minimo, int maximo) => TipoNaranja(
    color: 'Naranja',
    regla: 'Solo numeros del $minimo al $maximo; pueden repetirse',
    puntuacion: 6,
    minimo: minimo,
    maximo: maximo,
  );

  @override
  Tipo crearTipo(TipoZona tipoZona) {
    return switch (tipoZona) {
      TipoZona.azul => Tipo(
        tipo: TipoZona.azul,
        color: 'Azul',
        regla: 'Todos los numeros deben ser iguales',
        puntuacion: 8,
      ),
      TipoZona.rojo => Tipo(
        tipo: TipoZona.rojo,
        color: 'Rojo',
        regla: 'Todos los numeros deben ser diferentes',
        puntuacion: 6,
      ),
      TipoZona.verde => Tipo(
        tipo: TipoZona.verde,
        color: 'Verde',
        regla: 'Los numeros pueden repetirse',
        puntuacion: 3,
      ),
      TipoZona.amarillo => Tipo(
        tipo: TipoZona.amarillo,
        color: 'Amarillo',
        regla: 'Ningun numero puede repetirse entre las zonas amarillas',
        puntuacion: 8,
      ),
      TipoZona.morado => Tipo(
        tipo: TipoZona.morado,
        color: 'Morado',
        regla: 'Debe contener exactamente dos numeros diferentes',
        puntuacion: 7,
      ),
      // Sin saber de qué zona se trata, el naranja acepta del 1 al 6.
      TipoZona.naranja => _naranja(1, 6),
      TipoZona.gris => throw ArgumentError.value(
        tipoZona,
        'tipoZona',
        'El Mapa 4 no tiene zonas grises.',
      ),
    };
  }
}
