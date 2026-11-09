import 'package:flutter/material.dart';
import 'package:brilliant_mobile/formulario_partida.dart';
import 'package:brilliant_mobile/servicio_partidas.dart';

/// Botón de «Listo para iniciar» y cuántos faltan por confirmar. Solo dibuja;
/// quien lo usa decide qué hacer al tocar.
class PanelListo extends StatelessWidget {
  const PanelListo({
    super.key,
    required this.sala,
    required this.usuario,
    required this.enviando,
    required this.error,
    required this.onCambiar,
  });

  final SalaPartida sala;
  final String? usuario;
  final bool enviando;
  final String? error;

  /// Recibe el estado que el jugador quiere tener: listo o no.
  final ValueChanged<bool> onCambiar;

  String get _estado {
    if (sala.faltanJugadores) {
      return 'Hace falta al menos otro jugador para empezar.';
    }
    final pendientes = sala.pendientes;
    return pendientes == 1
        ? 'Falta 1 jugador por confirmar.'
        : 'Faltan $pendientes jugadores por confirmar.';
  }

  @override
  Widget build(BuildContext context) {
    final yoListo = sala.estaListo(usuario);
    final mensaje = error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _estado,
          key: const Key('sala-pendientes'),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        if (yoListo)
          OutlinedButton(
            key: const Key('sala-no-listo'),
            onPressed: enviando ? null : () => onCambiar(false),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Ya no estoy listo'),
            ),
          )
        else
          BotonEnviarPartida(
            key: const Key('sala-listo'),
            texto: 'Listo para iniciar',
            enviando: enviando,
            onPressed: () => onCambiar(true),
          ),
        if (mensaje != null) ErrorPartida(mensaje),
      ],
    );
  }
}
