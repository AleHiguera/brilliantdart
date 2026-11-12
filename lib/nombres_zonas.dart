import 'leyenda_reglas.dart';
import 'mapa.dart';
import 'tipoo.dart';

/// Cómo se llama cada zona de un mapa en un aviso: «la zona azul», «la zona
/// naranja de arriba». Si un color tiene zonas con reglas distintas (los
/// naranjas del Mapa 4), se dice cuál con la misma flecha de la leyenda. Si
/// tiene varias con la misma regla (dos verdes), se numeran igual que en la
/// tabla de valores: «la zona verde 1», «la zona verde 2».
class NombresZonas {
  NombresZonas(Mapa mapa) : _nombres = _calcular(mapa);

  final Map<int, String> _nombres;

  static const Map<TipoZona, String> colores = {
    TipoZona.amarillo: 'amarilla',
    TipoZona.rojo: 'roja',
    TipoZona.morado: 'morada',
    TipoZona.verde: 'verde',
    TipoZona.azul: 'azul',
    TipoZona.gris: 'gris',
    TipoZona.naranja: 'naranja',
  };

  /// «la zona azul», o «una zona» si el número no es de este mapa.
  String de(int zona) => _nombres[zona] ?? 'una zona';

  static Map<int, String> _calcular(Mapa mapa) {
    final flechas = {
      for (final regla in LeyendaReglas(mapa).reglas)
        (regla.tipo, regla.simbolo): regla.flecha,
    };
    final regiones = mapa.crearTablero().regiones;
    final porColor = <TipoZona, int>{};
    final vistas = <TipoZona, int>{};
    for (final region in regiones) {
      porColor[region.tipo.tipo] = (porColor[region.tipo.tipo] ?? 0) + 1;
    }
    return {
      for (final region in regiones)
        region.id: () {
          final tipo = region.tipo.tipo;
          final color = 'la zona ${colores[tipo]}';
          vistas[tipo] = (vistas[tipo] ?? 0) + 1;
          return switch (flechas[(
            tipo,
            LeyendaReglas.simboloDe(region.tipo),
          )]) {
            '↑' => '$color de arriba',
            '↓' => '$color de abajo',
            _ when porColor[tipo]! > 1 => '$color ${vistas[tipo]}',
            _ => color,
          };
        }(),
    };
  }
}
