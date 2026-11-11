import 'package:flutter/material.dart';
import 'package:brilliantdart/clasificacion.dart';
import 'package:brilliant_mobile/colores_zonas.dart';
import 'package:brilliant_mobile/tabla_puntos_partida.dart';

/// La pantalla final, igual para todos: quién ganó, por qué terminó y la
/// clasificación de todos los jugadores.
class PanelFinCompartido extends StatelessWidget {
  const PanelFinCompartido({
    super.key,
    required this.ganadores,
    required this.usuario,
    required this.puntos,
    required this.jugadores,
    required this.meta,
    required this.onVolver,
    this.porAbandono = false,
  });

  /// Quienes ganaron según el servidor; varios si empataron en puntos.
  final List<String> ganadores;
  final String? usuario;
  final Map<String, int> puntos;

  /// Quienes siguen en la partida, en orden de llegada.
  final List<String> jugadores;
  final int meta;
  final VoidCallback onVolver;

  /// Terminó porque los demás salieron, no por la meta ni por llenar tableros.
  final bool porAbandono;

  bool get _gane => ganadores.contains(usuario);

  String _titulo(int? miLugar) {
    if (_gane) {
      return ganadores.length > 1 ? '¡Empataste en primer lugar!' : '¡Ganaste!';
    }
    return miLugar == null
        ? 'Fin de la partida'
        : 'Quedaste en ${ordinalDeLugar(miLugar)} lugar';
  }

  String get _ganadores {
    final nombres = [
      for (final ganador in ganadores)
        ganador == usuario ? '@$ganador (tú)' : '@$ganador',
    ];
    final lista = nombres.length == 1
        ? nombres.single
        : '${nombres.sublist(0, nombres.length - 1).join(', ')} y ${nombres.last}';
    final verbo = ganadores.length == 1 ? 'Ganó' : 'Ganaron';
    return '$verbo $lista con ${_puntosDe(ganadores.first)} puntos';
  }

  int _puntosDe(String jugador) => puntos[jugador] ?? 0;

  /// Por qué terminó la partida.
  String get _motivo {
    if (porAbandono) {
      return _gane
          ? 'Ganaste por abandono: los demás jugadores salieron de la partida.'
          : 'Ganó por abandono: los demás jugadores salieron de la partida.';
    }
    return _puntosDe(ganadores.first) >= meta
        ? 'Se alcanzó la meta de $meta puntos.'
        : 'Nadie llegó a la meta de $meta puntos: todos llenaron su tablero.';
  }

  @override
  Widget build(BuildContext context) {
    final clasificacion = Clasificacion(
      puntos: puntos,
      jugadores: jugadores,
      ganadores: ganadores,
    );

    return Container(
      key: const Key('fin-compartido'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF2D14B)),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF8D6), Colors.white],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            _gane ? Icons.emoji_events : Icons.flag_outlined,
            size: 34,
            color: _gane ? const Color(0xFF7A5C00) : Colors.black54,
          ),
          const SizedBox(height: 6),
          Text(
            _titulo(clasificacion.lugarDe(usuario)),
            key: const Key('fin-titulo'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            _ganadores,
            key: const Key('fin-ganadores'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Tus puntos: ${_puntosDe(usuario ?? '')}',
            key: const Key('fin-mis-puntos'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            _motivo,
            key: const Key('fin-motivo'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 10),
          _TablaClasificacion(puestos: clasificacion.puestos, usuario: usuario),
          const SizedBox(height: 12),
          FilledButton(
            key: const Key('fin-volver'),
            style: estiloBotonPrincipal(),
            onPressed: onVolver,
            child: const Text('Volver al menú'),
          ),
        ],
      ),
    );
  }
}

class _TablaClasificacion extends StatelessWidget {
  const _TablaClasificacion({required this.puestos, required this.usuario});

  final List<Puesto> puestos;
  final String? usuario;

  /// El lugar de quien empata dice «(empate)» para que se note a simple vista.
  bool _empatado(Puesto puesto) =>
      puestos.where((otro) => otro.lugar == puesto.lugar).length > 1;

  Widget _fila(Puesto puesto) => _FilaPuesto(
    key: Key('clasificacion-${puesto.jugador}'),
    lugar: _empatado(puesto)
        ? '${ordinalDeLugar(puesto.lugar)} (empate)'
        : ordinalDeLugar(puesto.lugar),
    nombre: puesto.jugador == usuario
        ? '@${puesto.jugador} (tú)'
        : puesto.salio
        ? '@${puesto.jugador} (salió)'
        : '@${puesto.jugador}',
    puntos: puesto.puntos,
    soyYo: puesto.jugador == usuario,
  );

  @override
  Widget build(BuildContext context) {
    final ganadores = puestos.where((puesto) => puesto.lugar == 1).toList();
    final resto = puestos.where((puesto) => puesto.lugar != 1).toList();

    return Container(
      key: const Key('clasificacion'),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: decoracionTarjeta(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Clasificación',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          // Quien ganó va aparte, bajo su propio título, como en el papel.
          Container(
            key: const Key('clasificacion-ganadores'),
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3C4),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.emoji_events,
                      size: 16,
                      color: Color(0xFF7A5C00),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      ganadores.length > 1 ? 'Ganadores' : 'Ganador',
                      key: const Key('clasificacion-titulo-ganador'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7A5C00),
                      ),
                    ),
                  ],
                ),
                for (final puesto in ganadores) _fila(puesto),
              ],
            ),
          ),
          for (final puesto in resto) _fila(puesto),
        ],
      ),
    );
  }
}

class _FilaPuesto extends StatelessWidget {
  const _FilaPuesto({
    super.key,
    required this.lugar,
    required this.nombre,
    required this.puntos,
    required this.soyYo,
  });

  final String lugar;
  final String nombre;
  final int puntos;
  final bool soyYo;

  @override
  Widget build(BuildContext context) {
    final estilo = TextStyle(
      fontSize: 12,
      fontWeight: soyYo ? FontWeight.bold : FontWeight.normal,
    );

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: 2,
            fit: FlexFit.tight,
            child: Text(lugar, style: estilo),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 3,
            child: Text(nombre, overflow: TextOverflow.ellipsis, style: estilo),
          ),
          const SizedBox(width: 6),
          Text('$puntos pts', style: estilo),
        ],
      ),
    );
  }
}

/// Quien llenó su tablero ya no juega, pero la partida sigue para los demás.
class PanelTableroLleno extends StatelessWidget {
  const PanelTableroLleno({super.key, required this.puntos});

  final int puntos;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('tablero-lleno'),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: decoracionTarjeta(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Llenaste tu tablero',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Tus puntos: $puntos',
            key: const Key('lleno-puntos'),
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 4),
          const Text(
            'La partida sigue hasta que alguien llegue a la meta '
            'o todos llenen su tablero.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
