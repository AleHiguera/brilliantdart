import 'mapa.dart';
import 'tipoo.dart';

/// Una regla tal como se muestra junto al tablero: el color de la zona y un
/// signo que la resume. Si el color tiene reglas distintas según la zona (los
/// naranjas), [flecha] dice cuál es: ↑ la de más arriba, ↓ la de más abajo.
typedef ReglaVisible = ({
  TipoZona tipo,
  String simbolo,
  String regla,
  String? flecha,
});

/// Las reglas de las zonas de un mapa, resumidas en un signo cada una:
/// ≠ todos distintos, = todos iguales, XO dos números distintos, ? cualquier
/// número, y el rango (por ejemplo 4-6) en las naranjas.
///
/// Sale de las zonas reales del mapa, no de una lista fija: así un naranja del
/// 4 al 6 y otro del 1 al 3 aparecen por separado, y un color que el mapa no
/// usa no aparece.
class LeyendaReglas {
  const LeyendaReglas(this.mapa);

  final Mapa mapa;

  /// En qué orden se listan los colores.
  static const List<TipoZona> orden = [
    TipoZona.amarillo,
    TipoZona.rojo,
    TipoZona.morado,
    TipoZona.verde,
    TipoZona.azul,
    TipoZona.gris,
    TipoZona.naranja,
  ];

  static String simboloDe(Tipo tipo) => switch (tipo) {
    TipoNaranja(:final minimo, :final maximo) => '$minimo-$maximo',
    _ => switch (tipo.tipo) {
      TipoZona.amarillo || TipoZona.rojo => '≠',
      TipoZona.morado => 'XO',
      TipoZona.verde => '?',
      TipoZona.azul || TipoZona.gris => '=',
      TipoZona.naranja => '1-6',
    },
  };

  /// Una por cada regla distinta del mapa. Dos zonas del mismo color con la
  /// misma regla salen una sola vez; las del mismo color con reglas distintas
  /// (los naranjas) van de la zona más alta a la más baja.
  List<ReglaVisible> get reglas {
    int filaMasAlta(List<int> filas) => filas.reduce((a, b) => a < b ? a : b);
    final zonas =
        [
          for (final region in mapa.crearTablero().regiones)
            (
              tipo: region.tipo,
              fila: filaMasAlta([
                for (final celda in region.coordenadas) celda.x,
              ]),
            ),
        ]..sort((a, b) {
          final porColor = orden
              .indexOf(a.tipo.tipo)
              .compareTo(orden.indexOf(b.tipo.tipo));
          return porColor != 0 ? porColor : a.fila.compareTo(b.fila);
        });

    final vistas = <(TipoZona, String)>{};
    final distintas = [
      for (final zona in zonas)
        if (vistas.add((zona.tipo.tipo, simboloDe(zona.tipo)))) zona.tipo,
    ];

    String? flechaDe(int indice) {
      final tipo = distintas[indice].tipo;
      final mismoColor = [
        for (final (i, otra) in distintas.indexed)
          if (otra.tipo == tipo) i,
      ];
      if (mismoColor.length < 2) return null;
      if (indice == mismoColor.first) return '↑';
      if (indice == mismoColor.last) return '↓';
      return null;
    }

    return [
      for (final (indice, tipo) in distintas.indexed)
        (
          tipo: tipo.tipo,
          simbolo: simboloDe(tipo),
          regla: tipo.regla,
          flecha: flechaDe(indice),
        ),
    ];
  }
}
