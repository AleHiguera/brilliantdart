import 'leyenda_reglas.dart';
import 'mapa.dart';
import 'nombres_zonas.dart';
import 'region.dart';
import 'tipoo.dart';

/// Una zona que lleva marca en el tablero.
///
/// [texto] es lo que se lee en la marca (R1, V2, N↑); todos los pedazos de la
/// zona llevan el mismo, así se ve que cuentan juntos. [celdasMarca] es la
/// celda de cada pedazo donde va la marca: la de más arriba y a la izquierda,
/// contando filas y columnas desde 0.
typedef MarcaZona = ({
  int zona,
  TipoZona tipo,
  String texto,
  int pedazos,
  List<(int, int)> celdasMarca,
});

/// Cómo se explica en la lista de reglas un color con marcas.
typedef ExplicacionColor = ({TipoZona tipo, List<String> marcas, String texto});

/// Marcas que dicen, en el tablero, qué pedazos de color son la misma zona.
///
/// Un color puede tener una zona partida en pedazos separados que cuentan
/// juntos, o varias zonas que puntúan aparte. Se marcan solo esos colores:
/// donde un color es un solo pedazo no hay nada que aclarar.
///
/// La marca es la inicial del color con el número de la zona, en el mismo
/// orden que los avisos («la zona verde 2» es V2). Si dos zonas del mismo color
/// tienen reglas distintas, llevan la flecha de la leyenda (N↑, N↓).
class MarcasZonas {
  MarcasZonas(this.mapa) {
    final regiones = mapa.crearTablero().regiones;
    final porColor = <TipoZona, int>{};
    for (final region in regiones) {
      porColor[region.tipo.tipo] = (porColor[region.tipo.tipo] ?? 0) + 1;
    }
    final flechas = {
      for (final regla in LeyendaReglas(mapa).reglas)
        (regla.tipo, regla.simbolo): regla.flecha,
    };
    final vistas = <TipoZona, int>{};

    for (final region in regiones) {
      final tipo = region.tipo.tipo;
      vistas[tipo] = (vistas[tipo] ?? 0) + 1;
      for (final celda in region.coordenadas) {
        _zonaPorCelda[(celda.x, celda.y)] = region.id;
      }
      final partes = pedazosDe(region);
      _pedazos[region.id] = partes.length;
      _zonasDelColor[region.id] = porColor[tipo]!;
      if (partes.length < 2 && porColor[tipo]! < 2) continue;

      final flecha = flechas[(tipo, LeyendaReglas.simboloDe(region.tipo))];
      final marca = (
        zona: region.id,
        tipo: tipo,
        texto: '${iniciales[tipo]}${flecha ?? vistas[tipo]}',
        pedazos: partes.length,
        celdasMarca: [for (final pedazo in partes) pedazo.first],
      );
      _marcas.add(marca);
      for (final celda in marca.celdasMarca) {
        _marcaPorCelda[celda] = marca.texto;
      }
    }
  }

  final Mapa mapa;

  /// La letra de cada color en la marca. El azul lleva dos para no
  /// confundirse con el amarillo.
  static const Map<TipoZona, String> iniciales = {
    TipoZona.amarillo: 'A',
    TipoZona.rojo: 'R',
    TipoZona.morado: 'M',
    TipoZona.verde: 'V',
    TipoZona.azul: 'Az',
    TipoZona.gris: 'G',
    TipoZona.naranja: 'N',
  };

  final List<MarcaZona> _marcas = [];
  final Map<(int, int), String> _marcaPorCelda = {};
  final Map<(int, int), int> _zonaPorCelda = {};
  final Map<int, int> _pedazos = {};
  final Map<int, int> _zonasDelColor = {};
  late final NombresZonas _nombres = NombresZonas(mapa);

  /// Las zonas con marca, en el orden de las zonas del mapa.
  List<MarcaZona> get marcas => List.unmodifiable(_marcas);

  /// El texto de la marca que va en esta celda, o null si no lleva.
  String? marcaEn(int fila, int columna) => _marcaPorCelda[(fila, columna)];

  /// El número de la zona a la que pertenece la celda.
  int? zonaEn(int fila, int columna) => _zonaPorCelda[(fila, columna)];

  /// Las celdas de una zona, para resaltarla entera.
  Set<(int, int)> celdasDe(int zona) => {
    for (final MapEntry(:key, :value) in _zonaPorCelda.entries)
      if (value == zona) key,
  };

  /// La frase que acompaña a una zona resaltada: cuántos pedazos tiene y si
  /// hay otras de su color que puntúan aparte.
  String descripcionDe(int zona) {
    final nombre = _nombres.de(zona);
    final pedazos = _pedazos[zona] ?? 1;
    final delColor = _zonasDelColor[zona] ?? 1;
    final partes = [
      if (pedazos > 1) '$pedazos pedazos que cuentan como una sola zona',
      if (delColor > 1)
        'hay $delColor zonas de este color y cada una puntúa aparte',
    ];
    final texto = partes.isEmpty ? nombre : '$nombre: ${partes.join('; ')}';
    return '${texto[0].toUpperCase()}${texto.substring(1)}.';
  }

  /// Una explicación por cada color con marcas, en el orden de la leyenda.
  List<ExplicacionColor> get explicaciones {
    final porColor = <TipoZona, List<MarcaZona>>{};
    for (final marca in _marcas) {
      (porColor[marca.tipo] ??= []).add(marca);
    }
    return [
      for (final tipo in LeyendaReglas.orden)
        if (porColor[tipo] case final zonas?)
          (
            tipo: tipo,
            marcas: [for (final zona in zonas) zona.texto],
            texto: _explicar(zonas),
          ),
    ];
  }

  static String _explicar(List<MarcaZona> zonas) {
    if (zonas.length == 1) {
      final zona = zonas.single;
      return '${zona.texto}: una sola zona en ${zona.pedazos} pedazos; '
          'cuentan juntos.';
    }
    final nombres = [
      for (final zona in zonas)
        zona.pedazos > 1
            ? '${zona.texto} (${zona.pedazos} pedazos)'
            : zona.texto,
    ];
    final lista =
        '${nombres.sublist(0, nombres.length - 1).join(', ')} y ${nombres.last}';
    return '$lista: ${zonas.length} zonas distintas; cada una se llena y '
        'puntúa aparte.';
  }

  /// Los pedazos de una zona: grupos de celdas que se tocan por un lado. Cada
  /// pedazo empieza por su celda de más arriba y a la izquierda, y los
  /// pedazos van en ese mismo orden.
  static List<List<(int, int)>> pedazosDe(Region region) {
    final pendientes = {
      for (final celda in region.coordenadas) (celda.x, celda.y),
    };
    final pedazos = <List<(int, int)>>[];
    while (pendientes.isNotEmpty) {
      final inicio = pendientes.reduce(_primeraEnLectura);
      pendientes.remove(inicio);
      final pedazo = [inicio];
      final porVisitar = [inicio];
      while (porVisitar.isNotEmpty) {
        final (fila, columna) = porVisitar.removeLast();
        for (final vecina in [
          (fila - 1, columna),
          (fila + 1, columna),
          (fila, columna - 1),
          (fila, columna + 1),
        ]) {
          if (pendientes.remove(vecina)) {
            pedazo.add(vecina);
            porVisitar.add(vecina);
          }
        }
      }
      pedazo.sort((a, b) => _primeraEnLectura(a, b) == a ? -1 : 1);
      pedazos.add(pedazo);
    }
    return pedazos;
  }

  static (int, int) _primeraEnLectura((int, int) a, (int, int) b) =>
      a.$1 < b.$1 || (a.$1 == b.$1 && a.$2 <= b.$2) ? a : b;
}
