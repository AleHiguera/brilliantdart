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

/// Cómo está un lugar de una zona para este jugador.
enum EstadoLugar {
  /// Lo ganó este jugador.
  mio,

  /// Ya lo ganó otro: esos puntos ya no están.
  ganado,

  /// El que le tocaría si la llena ahora.
  siguiente,

  /// Todavía libre, pero antes hay otro por ganar.
  libre,
}

/// Los lugares que dan puntos en cada zona: 1.º, 2.º y 3.º.
const int lugaresConPuntos = 3;

/// El estado de [lugar] en [zona] para [usuario], si llenara la zona en
/// [ronda]. Solo cuentan como ganados los lugares de rondas anteriores: si
/// otro la llenó en esta misma, todavía se puede empatar con él.
EstadoLugar estadoDeLugar(
  LugaresDeZona zona,
  int lugar, {
  required int ronda,
  required String? usuario,
}) {
  final mio = zona.lugares[usuario];
  if (mio == lugar) return EstadoLugar.mio;
  final siguiente = zona.lugarEnRonda(ronda);
  if (lugar < siguiente) return EstadoLugar.ganado;
  if (mio == null && lugar == siguiente) return EstadoLugar.siguiente;
  return EstadoLugar.libre;
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
          // Qué lugar es cada columna de puntos.
          Padding(
            key: const Key('tabla-zonas-lugares'),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [
                const Spacer(),
                for (var lugar = 1; lugar <= lugaresConPuntos; lugar++) ...[
                  if (lugar > 1) const SizedBox(width: CasillaLugar.separacion),
                  SizedBox(
                    width: CasillaLugar.ancho,
                    child: Text(
                      ordinalDeLugar(lugar),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 9,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          for (final MapEntry(key: id, value: zona) in zonas.entries)
            _FilaZona(
              key: Key('zona-$id'),
              id: id,
              tipo: zona.tipo.tipo,
              nombre: _nombreDe(zona.tipo.tipo, vistos),
              casillas: [
                for (var lugar = 1; lugar <= lugaresConPuntos; lugar++)
                  (
                    lugar: lugar,
                    puntos: zona.tipo.puntosDeLugar(lugar),
                    estado: estadoDeLugar(
                      zona,
                      lugar,
                      ronda: ronda,
                      usuario: usuario,
                    ),
                  ),
              ],
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
}

class _FilaZona extends StatelessWidget {
  const _FilaZona({
    super.key,
    required this.id,
    required this.tipo,
    required this.nombre,
    required this.casillas,
    required this.hecha,
  });

  final int id;
  final TipoZona tipo;
  final String nombre;
  final List<({int lugar, int puntos, EstadoLugar estado})> casillas;
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
          const SizedBox(width: 4),
          for (final (indice, casilla) in casillas.indexed) ...[
            if (indice > 0) const SizedBox(width: CasillaLugar.separacion),
            CasillaLugar(
              key: Key('zona-$id-lugar-${casilla.lugar}'),
              lugar: casilla.lugar,
              puntos: casilla.puntos,
              estado: casilla.estado,
            ),
          ],
        ],
      ),
    );
  }
}

/// Los puntos de un lugar de una zona, marcados según si ya se ganaron.
class CasillaLugar extends StatelessWidget {
  const CasillaLugar({
    super.key,
    required this.lugar,
    required this.puntos,
    required this.estado,
  });

  static const double ancho = 22;
  static const double separacion = 3;

  final int lugar;
  final int puntos;
  final EstadoLugar estado;

  String get _explicacion => switch (estado) {
    EstadoLugar.mio => 'lo ganaste tú',
    EstadoLugar.ganado => 'ya lo ganó otro jugador',
    EstadoLugar.siguiente => 'es el siguiente disponible',
    EstadoLugar.libre => 'todavía libre',
  };

  @override
  Widget build(BuildContext context) {
    final (fondo, borde, texto) = switch (estado) {
      EstadoLugar.mio => (Colors.black, Colors.black, Colors.white),
      EstadoLugar.ganado => (
        const Color(0xFFE6E6E2),
        const Color(0xFFE6E6E2),
        Colors.black38,
      ),
      EstadoLugar.siguiente => (Colors.white, Colors.black, Colors.black),
      EstadoLugar.libre => (Colors.white, Colors.black12, Colors.black54),
    };
    final resaltado =
        estado == EstadoLugar.siguiente || estado == EstadoLugar.mio;

    return Tooltip(
      message: '${ordinalDeLugar(lugar)} lugar: $puntos puntos, $_explicacion',
      child: Container(
        width: ancho,
        height: 18,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fondo,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: borde,
            width: estado == EstadoLugar.siguiente ? 1.5 : 1,
          ),
        ),
        child: Text(
          '$puntos',
          style: TextStyle(
            fontSize: 11,
            color: texto,
            fontWeight: resaltado ? FontWeight.bold : FontWeight.normal,
            decoration: estado == EstadoLugar.ganado
                ? TextDecoration.lineThrough
                : null,
            decorationColor: Colors.black54,
          ),
        ),
      ),
    );
  }
}
