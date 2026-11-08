import 'package:flutter/material.dart';
import 'package:brilliant_mobile/colores_zonas.dart' as estilo;
import 'package:brilliant_mobile/formulario_partida.dart';
import 'package:brilliant_mobile/servicio_partidas.dart';

/// Lo que la sala muestra sobre el inicio de la partida: el aviso de que ya
/// comenzó, o el botón con el que el anfitrión la inicia. Solo dibuja; quien lo
/// usa decide qué hacer al tocar.
class PanelInicioPartida extends StatelessWidget {
  const PanelInicioPartida({
    super.key,
    required this.sala,
    required this.soyAnfitrion,
    required this.iniciando,
    required this.error,
    required this.onIniciar,
  });

  final SalaPartida sala;
  final bool soyAnfitrion;
  final bool iniciando;
  final String? error;
  final VoidCallback onIniciar;

  @override
  Widget build(BuildContext context) {
    if (sala.comenzada) {
      return const estilo.AvisoJuego(
        key: Key('sala-comenzada'),
        icono: Icons.flag_outlined,
        texto: 'La partida comenzó: ya no puede entrar nadie más.',
      );
    }
    if (!soyAnfitrion) {
      return const Text(
        'Esperando a que el anfitrión inicie la partida.',
        key: Key('sala-esperando'),
        textAlign: TextAlign.center,
      );
    }

    final mensaje = error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BotonEnviarPartida(
          key: const Key('sala-iniciar'),
          texto: 'Iniciar partida',
          enviando: iniciando,
          onPressed: sala.sePuedeIniciar ? onIniciar : null,
        ),
        if (!sala.sePuedeIniciar)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Hace falta al menos otro jugador para empezar.',
              key: Key('sala-falta-jugador'),
              textAlign: TextAlign.center,
            ),
          ),
        if (mensaje != null) ErrorPartida(mensaje),
      ],
    );
  }
}
