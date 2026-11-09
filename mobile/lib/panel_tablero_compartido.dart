import 'package:flutter/material.dart';
import 'package:brilliant_mobile/colores_zonas.dart';
import 'package:brilliant_mobile/formulario_partida.dart';
import 'package:brilliant_mobile/paneles_juego.dart';
import 'package:brilliant_mobile/partida_compartida.dart';
import 'package:brilliant_mobile/servicio_partidas.dart';

/// Parte inferior del tablero mientras cada jugador coloca sus números:
/// el botón «Finalizado», la espera de los demás o el aviso de partida perdida.
class PanelTableroCompartido extends StatelessWidget {
  const PanelTableroCompartido({
    super.key,
    required this.compartida,
    required this.valoresColocados,
    required this.tableroCompleto,
    required this.onFinalizar,
    required this.onVolver,
  });

  final PartidaCompartida compartida;
  final Set<int> valoresColocados;
  final bool tableroCompleto;
  final VoidCallback onFinalizar;
  final VoidCallback onVolver;

  @override
  Widget build(BuildContext context) {
    final perdida = compartida.perdida;
    if (perdida != null) {
      return AvisoPartidaPerdida(motivo: perdida, onVolver: onVolver);
    }

    if (compartida.yaFinalice) {
      return _EsperaDeTableros(pendientes: compartida.sala.tablerosPendientes);
    }

    final error = compartida.error;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PanelPreparacion(
          valoresColocados: valoresColocados,
          puedeIniciar: tableroCompleto,
          textoBoton: 'Finalizado',
          textoListo: '¡Listo! Pulsa Finalizado para confirmar tu tablero.',
          onComenzar: compartida.enviando ? null : onFinalizar,
        ),
        if (error != null) ErrorPartida(error),
      ],
    );
  }
}

/// La partida ya no existe: solo queda volver al menú.
class AvisoPartidaPerdida extends StatelessWidget {
  const AvisoPartidaPerdida({
    super.key,
    required this.motivo,
    required this.onVolver,
  });

  final String motivo;
  final VoidCallback onVolver;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AvisoJuego(
          key: const Key('tablero-perdido'),
          icono: Icons.do_not_disturb_alt,
          texto: motivo,
          advertencia: true,
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          key: const Key('tablero-volver'),
          onPressed: onVolver,
          child: const Text('Volver al menú'),
        ),
      ],
    );
  }
}

/// El jugador ya usó los dados de esta ronda; los siguientes llegan cuando
/// todos hayan jugado.
class PanelEsperaRonda extends StatelessWidget {
  const PanelEsperaRonda({super.key, required this.sala});

  final SalaPartida sala;

  @override
  Widget build(BuildContext context) {
    final pendientes = sala.rondaPendientes;

    return Container(
      key: const Key('ronda-esperando'),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: decoracionTarjeta(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Turno terminado',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Dados de la ronda ${sala.ronda}: '
            '${sala.dados.join(' y ')}',
            key: const Key('ronda-dados'),
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          if (pendientes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Falta por jugar: '
              '${pendientes.map((jugador) => '@$jugador').join(', ')}',
              key: const Key('ronda-pendientes'),
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _EsperaDeTableros extends StatelessWidget {
  const _EsperaDeTableros({required this.pendientes});

  final List<String> pendientes;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('tablero-esperando'),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: decoracionTarjeta(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tu tablero está listo',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Los dados se lanzarán cuando todos hayan terminado.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          if (pendientes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Colocando sus números: '
              '${pendientes.map((jugador) => '@$jugador').join(', ')}',
              key: const Key('tablero-pendientes'),
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

/// Pide confirmar antes de dejar una partida en la que otros están esperando.
Future<bool> confirmarSalidaDePartida(
  BuildContext context, {
  required bool anfitrion,
}) async {
  final confirmado = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Salir de la partida'),
      content: Text(
        anfitrion
            ? 'Eres el anfitrión: si sales, la partida se cierra para todos.'
            : 'Si sales, ya no podrás volver a esta partida.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('tablero-salir-confirmar'),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Salir'),
        ),
      ],
    ),
  );
  return confirmado ?? false;
}
