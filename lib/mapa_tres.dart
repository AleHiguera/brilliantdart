import 'dibujo_mapa.dart';
import 'mapa.dart';
import 'tipoo.dart';

/// El Mapa 3, listo para usar.
const mapaTres = MapaTres();

/// Descripción del Mapa 3: su dibujo, sus puntos y sus celdas iniciales.
///
/// Es de un solo jugador, así que cada color suma su primer puntaje (el más
/// alto): amarillo 7, morado 7, gris 8, rojo 6, verde 6 y azul 7.
class MapaTres extends Mapa {
  const MapaTres();

  /// El dibujo tal como está en el papel, una letra por celda:
  /// M = morado, G = gris, V = verde, A = amarillo, R = rojo, Z = azul.
  static const List<String> dibujo = [
    'AAMGMAA',
    'GAMMMAG',
    'RRRMRRR',
    'RRRGRRR',
    'VZZZZZV',
    'VVVVVVV',
    'MMMGMMM',
  ];

  static final List<List<TipoZona>> _tiposPorCelda = leerDibujo(dibujo);

  @override
  int get numero => 3;

  @override
  List<List<TipoZona>> get tiposPorCelda => _tiposPorCelda;

  @override
  List<(int, int)> get celdasIniciales => const [
    (2, 3),
    (2, 6),
    (4, 4),
    (5, 2),
    (5, 7),
    (6, 3),
  ];

  /// Los amarillos y los grises forman una sola zona aunque estén separados.
  @override
  Set<TipoZona> get tiposUnidos => const {TipoZona.amarillo, TipoZona.gris};

  /// Los dos morados de abajo, separados por el gris (7, 4), son una sola
  /// zona. El morado de arriba es otra zona.
  @override
  List<List<(int, int)>> get partesUnidas => const [
    [(7, 1), (7, 5)],
  ];

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
        puntuacion: 6,
      ),
      TipoZona.amarillo => Tipo(
        tipo: TipoZona.amarillo,
        color: 'Amarillo',
        regla: 'Ningun numero puede repetirse entre las zonas amarillas',
        puntuacion: 7,
      ),
      TipoZona.morado => Tipo(
        tipo: TipoZona.morado,
        color: 'Morado',
        regla: 'Debe contener exactamente dos numeros diferentes',
        puntuacion: 7,
      ),
      TipoZona.gris => Tipo(
        tipo: TipoZona.gris,
        color: 'Gris',
        regla: 'Todos los numeros grises deben ser iguales',
        puntuacion: 8,
      ),
    };
  }
}
