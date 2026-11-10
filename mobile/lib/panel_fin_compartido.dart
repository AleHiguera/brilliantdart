import 'package:flutter/material.dart';
import 'package:brilliant_mobile/colores_zonas.dart';

/// La pantalla final, igual para todos: quién ganó, por qué terminó y cuántos
/// puntos hizo cada uno. Los puntos de todos siguen en la tabla de la partida.
class PanelFinCompartido extends StatelessWidget {
  const PanelFinCompartido({
    super.key,
    required this.ganadores,
    required this.usuario,
    required this.puntos,
    required this.meta,
    required this.onVolver,
  });

  final List<String> ganadores;
  final String? usuario;
  final Map<String, int> puntos;
  final int meta;
  final VoidCallback onVolver;

  bool get _gane => ganadores.contains(usuario);

  String get _titulo {
    if (!_gane) return 'Fin de la partida';
    return ganadores.length > 1 ? '¡Empataste en primer lugar!' : '¡Ganaste!';
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

  @override
  Widget build(BuildContext context) {
    final llegaron = _puntosDe(ganadores.first) >= meta;

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
        children: [
          Icon(
            _gane ? Icons.emoji_events : Icons.flag_outlined,
            size: 34,
            color: _gane ? const Color(0xFF7A5C00) : Colors.black54,
          ),
          const SizedBox(height: 6),
          Text(
            _titulo,
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
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            llegaron
                ? 'Se alcanzó la meta de $meta puntos.'
                : 'Nadie llegó a la meta de $meta puntos: '
                      'todos llenaron su tablero.',
            key: const Key('fin-motivo'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
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
