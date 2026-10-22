import 'constructor_tablero.dart';
import 'tablero.dart';
import 'tipoo.dart';

class MapaUno {
  static const List<List<TipoZona>> tiposPorCelda = [
    [TipoZona.amarillo, TipoZona.verde, TipoZona.azul, TipoZona.morado, TipoZona.morado, TipoZona.morado, TipoZona.amarillo],
    [TipoZona.verde, TipoZona.verde, TipoZona.azul, TipoZona.azul, TipoZona.morado, TipoZona.morado, TipoZona.verde],
    [TipoZona.verde, TipoZona.rojo, TipoZona.rojo, TipoZona.azul, TipoZona.morado, TipoZona.verde, TipoZona.verde],
    [TipoZona.verde, TipoZona.rojo, TipoZona.morado, TipoZona.amarillo, TipoZona.verde, TipoZona.verde, TipoZona.verde],
    [TipoZona.verde, TipoZona.rojo, TipoZona.morado, TipoZona.morado, TipoZona.rojo, TipoZona.rojo, TipoZona.azul],
    [TipoZona.rojo, TipoZona.rojo, TipoZona.morado, TipoZona.rojo, TipoZona.rojo, TipoZona.azul, TipoZona.azul],
    [TipoZona.amarillo, TipoZona.morado, TipoZona.morado, TipoZona.rojo, TipoZona.rojo, TipoZona.azul, TipoZona.amarillo],
  ];

  static Tablero crearTablero() {
    return const ConstructorTablero(
      tiposPorCelda: tiposPorCelda,
      crearTipo: _crearTipo,
      tiposUnidos: {TipoZona.amarillo},
    ).construir();
  }

  static Tipo _crearTipo(TipoZona tipoZona) {
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
    };
  }
}