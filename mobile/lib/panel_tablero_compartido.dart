import 'package:flutter/material.dart';
import 'package:brilliant_mobile/colores_zonas.dart';
import 'package:brilliant_mobile/formulario_partida.dart';
import 'package:brilliant_mobile/paneles_juego.dart';
import 'package:brilliant_mobile/preparacion_multijugador.dart';

/// Parte inferior del tablero mientras cada jugador coloca sus números:
/// el botón «Finalizado», la espera de los demás o el aviso de partida perdida.
class PanelTableroCompartido extends StatelessWidget {
  const PanelTableroCompartido({
    super.key,
    required this.preparacion,
    required this.valoresColocados,
    required this.tableroCompleto,
    required this.onFinalizar,
    required this.onVolver,
  });

  final PreparacionMultijugador preparacion;
  final Set<int> valoresColocados;
  final bool tableroCompleto;
  final VoidCallback onFinalizar;
  final VoidCallback onVolver;

  @override
  Widget build(BuildContext context) {
    final perdida = preparacion.perdida;
    if (perdida != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AvisoJuego(
            key: const Key('tablero-perdido'),
            icono: Icons.do_not_disturb_alt,
            texto: perdida,
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

    if (preparacion.yaFinalice) {
      return _EsperaDeTableros(pendientes: preparacion.sala.tablerosPendientes);
    }

    final error = preparacion.error;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PanelPreparacion(
          valoresColocados: valoresColocados,
          puedeIniciar: tableroCompleto,
          textoBoton: 'Finalizado',
          textoListo: '¡Listo! Pulsa Finalizado para confirmar tu tablero.',
          onComenzar: preparacion.enviando ? null : onFinalizar,
        ),
        if (error != null) ErrorPartida(error),
      ],
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
