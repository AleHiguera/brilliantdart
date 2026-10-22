import 'mapa.dart';
import 'tipoo.dart';

/// El Mapa 2, listo para usar.
const mapaDos = MapaDos();

/// Descripción del Mapa 2: su dibujo, sus puntos y sus celdas iniciales.
///
/// Es de un solo jugador, así que cada color suma su primer puntaje (el más
/// alto): morado 6, gris 3, verde 4, amarillo 6, rojo 6 y azul 7.
class MapaDos extends Mapa {
  const MapaDos();

  /// El dibujo tal como está en el papel, una letra por celda:
  /// M = morado, G = gris, V = verde, A = amarillo, R = rojo, Z = azul.
  static const List<String> dibujo = [
    'MMMGVVV',
    'MAZZZAV',
    'MRRZZRV',
    'RRRARRR',
    'VRZZRRM',
    'VAZZZAM',
    'VVVGMMM',
  ];

  static const Map<String, TipoZona> letras = {
    'M': TipoZona.morado,
    'G': TipoZona.gris,
    'V': TipoZona.verde,
    'A': TipoZona.amarillo,
    'R': TipoZona.rojo,
    'Z': TipoZona.azul,
  };

  static final List<List<TipoZona>> _tiposPorCelda = List.unmodifiable([
    for (final fila in dibujo)
      List<TipoZona>.unmodifiable([
        for (final letra in fila.split('')) letras[letra]!,
      ]),
  ]);

  @override
  int get numero => 2;

  @override
  List<List<TipoZona>> get tiposPorCelda => _tiposPorCelda;

  @override
  List<(int, int)> get celdasIniciales => const [
    (1, 5),
    (3, 1),
    (4, 3),
    (5, 6),
    (6, 2),
    (7, 5),
  ];

  /// Los amarillos y los grises forman una sola zona aunque estén separados.
  @override
  Set<TipoZona> get tiposUnidos => const {TipoZona.amarillo, TipoZona.gris};

  @override
  Tipo crearTipo(TipoZona tipoZona) {
    return switch (tipoZona) {
      TipoZona.azul => Tipo(
        tipo: TipoZona.azul,
        color: 'Azul',
        regla: 'Todos los numeros deben ser iguales',
        puntuacion: 7,
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
        puntuacion: 4,
      ),
      TipoZona.amarillo => Tipo(
        tipo: TipoZona.amarillo,
        color: 'Amarillo',
        regla: 'Ningun numero puede repetirse entre las zonas amarillas',
        puntuacion: 6,
      ),
      TipoZona.morado => Tipo(
        tipo: TipoZona.morado,
        color: 'Morado',
        regla: 'Debe contener exactamente dos numeros diferentes',
        puntuacion: 6,
      ),
      TipoZona.gris => Tipo(
        tipo: TipoZona.gris,
        color: 'Gris',
        regla: 'Todos los numeros grises deben ser iguales',
        puntuacion: 3,
      ),
    };
  }
}
