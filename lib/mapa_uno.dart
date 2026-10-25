import 'mapa.dart';
import 'tipoo.dart';

/// El Mapa 1, listo para usar.
const mapaUno = MapaUno();

/// Descripción del Mapa 1: su dibujo, sus puntos y sus celdas iniciales.
class MapaUno extends Mapa {
  const MapaUno();

  @override
  int get numero => 1;

  @override
  List<List<TipoZona>> get tiposPorCelda => _tiposPorCelda;

  static const List<List<TipoZona>> _tiposPorCelda = [
    [
      TipoZona.amarillo,
      TipoZona.verde,
      TipoZona.azul,
      TipoZona.morado,
      TipoZona.morado,
      TipoZona.morado,
      TipoZona.amarillo,
    ],
    [
      TipoZona.verde,
      TipoZona.verde,
      TipoZona.azul,
      TipoZona.azul,
      TipoZona.morado,
      TipoZona.morado,
      TipoZona.verde,
    ],
    [
      TipoZona.verde,
      TipoZona.rojo,
      TipoZona.rojo,
      TipoZona.azul,
      TipoZona.morado,
      TipoZona.verde,
      TipoZona.verde,
    ],
    [
      TipoZona.verde,
      TipoZona.rojo,
      TipoZona.morado,
      TipoZona.amarillo,
      TipoZona.verde,
      TipoZona.verde,
      TipoZona.verde,
    ],
    [
      TipoZona.verde,
      TipoZona.rojo,
      TipoZona.morado,
      TipoZona.morado,
      TipoZona.rojo,
      TipoZona.rojo,
      TipoZona.azul,
    ],
    [
      TipoZona.rojo,
      TipoZona.rojo,
      TipoZona.morado,
      TipoZona.rojo,
      TipoZona.rojo,
      TipoZona.azul,
      TipoZona.azul,
    ],
    [
      TipoZona.amarillo,
      TipoZona.morado,
      TipoZona.morado,
      TipoZona.rojo,
      TipoZona.rojo,
      TipoZona.azul,
      TipoZona.amarillo,
    ],
  ];

  @override
  List<(int, int)> get celdasIniciales => const [
    (1, 3),
    (2, 6),
    (4, 2),
    (4, 5),
    (6, 3),
    (7, 5),
  ];

  @override
  Set<TipoZona> get tiposUnidos => const {TipoZona.amarillo};

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
        puntuacion: 8,
      ),
      TipoZona.morado => Tipo(
        tipo: TipoZona.morado,
        color: 'Morado',
        regla: 'Debe contener exactamente dos numeros diferentes',
        puntuacion: 6,
      ),
      TipoZona.gris => throw ArgumentError.value(
        tipoZona,
        'tipoZona',
        'El Mapa 1 no tiene zonas grises.',
      ),
      TipoZona.naranja => throw ArgumentError.value(
        tipoZona,
        'tipoZona',
        'El Mapa 1 no tiene zonas naranjas.',
      ),
    };
  }
}
