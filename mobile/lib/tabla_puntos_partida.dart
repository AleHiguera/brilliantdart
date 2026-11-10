import 'package:flutter/material.dart';
import 'package:brilliantdart/lugares_de_zona.dart';
import 'package:brilliantdart/puntuacion_multijugador.dart';
import 'package:brilliantdart/tipoo.dart';
import 'package:brilliant_mobile/colores_zonas.dart';
import 'package:brilliant_mobile/tabla_puntuacion.dart';

/// Cómo se escribe un lugar: 1.º, 2.º, 3.er, 4.º...
String ordinalDeLugar(int lugar) => lugar == 3 ? '3.er' : '$lugar.º';

/// Puntos de una partida multijugador: cuánto lleva cada jugador y cuánto vale
/// ahora cada zona. Solo dibuja; las cuentas son de [PuntuacionMultijugador].
class TablaPuntosPartida extends StatelessWidget {
  const TablaPuntosPartida({
    super.key,
    required this.puntuacion,
    required this.jugadores,
    required this.usuario,
    required this.ronda,
    this.meta = 0,
  });

  final PuntuacionMultijugador puntuacion;

  /// Puntos para ganar; 0 si aún no se conoce.
  final int meta;

  /// Quienes siguen en la partida.
  final List<String> jugadores;
  final String? usuario;

  /// La ronda en que este jugador podría completar su siguiente zona.
  final int ronda;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TarjetaJugadores(
          puntos: puntuacion.puntos,
          jugadores: jugadores,
          usuario: usuario,
          meta: meta,
        ),
        const SizedBox(height: 8),
        _TarjetaZonas(zonas: puntuacion.zonas, usuario: usuario, ronda: ronda),
      ],
    );
  }
}

class _TarjetaJugadores extends StatelessWidget {
  const _TarjetaJugadores({
    required this.puntos,
    required this.jugadores,
    required this.usuario,
    required this.meta,
  });

  final Map<String, int> puntos;
  final List<String> jugadores;
  final String? usuario;
  final int meta;

  @override
  Widget build(BuildContext context) {
    // Quien salió pero ganó puntos sigue en la tabla: sus puntos no se pierden.
    final todos = [
      ...jugadores,
      ...puntos.keys.where((jugador) => !jugadores.contains(jugador)),
    ];
    int puntosDe(String jugador) => puntos[jugador] ?? 0;
    // El orden de llegada desempata para que la tabla no salte entre consultas.
    final enOrden =
        [for (final (indice, jugador) in todos.indexed) (indice, jugador)]
          ..sort((a, b) {
            final porPuntos = puntosDe(b.$2).compareTo(puntosDe(a.$2));
            return porPuntos != 0 ? porPuntos : a.$1.compareTo(b.$1);
          });

    return Container(
      key: const Key('tabla-jugadores'),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: decoracionTarjeta(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const EncabezadoTarjeta(
            icono: Icons.emoji_events_outlined,
            titulo: 'Puntos',
          ),
          // En su propia línea: junto al título no cabe en la columna angosta.
          if (meta > 0)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Meta: $meta puntos',
                key: const Key('meta-partida'),
                style: const TextStyle(fontSize: 11, color: Colors.black54),
              ),
            ),
          const SizedBox(height: 4),
          for (final (_, jugador) in enOrden)
            _FilaJugador(
              key: Key('puntos-$jugador'),
              nombre: _nombreDe(jugador),
              puntos: puntosDe(jugador),
              soyYo: jugador == usuario,
            ),
        ],
      ),
    );
  }

  String _nombreDe(String jugador) {
    if (jugador == usuario) return '@$jugador (tú)';
    return jugadores.contains(jugador) ? '@$jugador' : '@$jugador (salió)';
  }
}

class _FilaJugador extends StatelessWidget {
  const _FilaJugador({
    super.key,
    required this.nombre,
    required this.puntos,
    required this.soyYo,
  });

  final String nombre;
  final int puntos;
  final bool soyYo;

  @override
  Widget build(BuildContext context) {
    final peso = soyYo ? FontWeight.bold : FontWeight.normal;
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              nombre,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, fontWeight: peso),
            ),
          ),
          const SizedBox(width: 6),
          Text('$puntos pts', style: TextStyle(fontSize: 12, fontWeight: peso)),
        ],
      ),
    );
  }
}

class _TarjetaZonas extends StatelessWidget {
  const _TarjetaZonas({
    required this.zonas,
    required this.usuario,
    required this.ronda,
  });

  final Map<int, LugaresDeZona> zonas;
  final String? usuario;
  final int ronda;

  @override
  Widget build(BuildContext context) {
    final vistos = <TipoZona, int>{};

    return Container(
      key: const Key('tabla-zonas'),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: decoracionTarjeta(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const EncabezadoTarjeta(
            icono: Icons.grid_view_outlined,
            titulo: 'Valor de las zonas',
          ),
          const SizedBox(height: 4),
          for (final MapEntry(key: id, value: zona) in zonas.entries)
            _FilaZona(
              key: Key('zona-$id'),
              tipo: zona.tipo.tipo,
              nombre: _nombreDe(zona.tipo.tipo, vistos),
              valor: _valorDe(zona),
              hecha: zona.rondaPorJugador.containsKey(usuario),
            ),
        ],
      ),
    );
  }

  /// «Verde 1» y «Verde 2» si hay dos, de arriba hacia abajo del tablero;
  /// solo «Amarilla» si hay una.
  String _nombreDe(TipoZona tipo, Map<TipoZona, int> vistos) {
    final nombre = TablaPuntuacion.nombres[tipo]!;
    final total = zonas.values.where((zona) => zona.tipo.tipo == tipo).length;
    if (total == 1) return nombre;
    vistos[tipo] = (vistos[tipo] ?? 0) + 1;
    return '$nombre ${vistos[tipo]}';
  }

  String _valorDe(LugaresDeZona zona) {
    final lugar = zona.lugares[usuario];
    if (lugar != null) {
      return '${ordinalDeLugar(lugar)} · ${zona.puntos[usuario]} pts';
    }
    final puntos = zona.puntosEnRonda(ronda);
    return puntos > 0 ? 'Vale $puntos' : 'Sin puntos';
  }
}

class _FilaZona extends StatelessWidget {
  const _FilaZona({
    super.key,
    required this.tipo,
    required this.nombre,
    required this.valor,
    required this.hecha,
  });

  final TipoZona tipo;
  final String nombre;
  final String valor;
  final bool hecha;

  @override
  Widget build(BuildContext context) {
    final color = coloresZonas[tipo]!;

    return Container(
      margin: const EdgeInsets.only(top: 3),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: hecha ? color.withValues(alpha: 0.16) : Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: Colors.black26, width: 0.5),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              nombre,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11),
            ),
          ),
          const SizedBox(width: 6),
          // En una columna angosta o con letra grande baja de línea sin salirse.
          Flexible(
            child: Text(
              valor,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11,
                fontWeight: hecha ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
