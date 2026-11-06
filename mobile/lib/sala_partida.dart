import 'package:flutter/material.dart';
import 'package:brilliantdart/catalogo_mapas.dart';
import 'package:brilliant_mobile/colores_zonas.dart' as estilo;
import 'package:brilliant_mobile/formulario_partida.dart';
import 'package:brilliant_mobile/servicio_auth.dart';
import 'package:brilliant_mobile/servicio_partidas.dart';
import 'package:brilliant_mobile/tarjetas_sala.dart';
import 'package:brilliant_mobile/vigilante_sala.dart';

/// Sala de espera: muestra el código para compartir y quién va llegando.
class SalaPartidaPage extends StatefulWidget {
  const SalaPartidaPage({
    super.key,
    required this.partidas,
    required this.sala,
  });

  final ServicioPartidas partidas;
  final SalaPartida sala;

  /// Cambia la pantalla actual por la sala a la que se acaba de entrar.
  static void abrir(
    BuildContext context,
    ServicioPartidas partidas,
    SalaPartida sala,
  ) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => SalaPartidaPage(partidas: partidas, sala: sala),
      ),
    );
  }

  @override
  State<SalaPartidaPage> createState() => _SalaPartidaPageState();
}

class _SalaPartidaPageState extends State<SalaPartidaPage> {
  late SalaPartida _sala = widget.sala;
  late final VigilanteSala _vigilante = VigilanteSala(
    partidas: widget.partidas,
    codigo: widget.sala.codigo,
    alCambiar: (sala) {
      if (mounted) setState(() => _sala = sala);
    },
    alTerminar: (mensaje) {
      if (mounted) setState(() => _salaPerdida = mensaje);
    },
  );

  /// Por qué ya no se puede seguir en la sala, como que el anfitrión la cerró.
  String? _salaPerdida;

  String? get _usuario => widget.partidas.auth.sesion?.usuario;
  bool get _soyAnfitrion => _sala.anfitrion == _usuario;

  @override
  void initState() {
    super.initState();
    _vigilante.iniciar();
  }

  @override
  void dispose() {
    _vigilante.detener();
    super.dispose();
  }

  Future<void> _salir() async {
    if (_salaPerdida != null) {
      Navigator.of(context).pop();
      return;
    }
    final navegador = Navigator.of(context);
    if (_soyAnfitrion) {
      final confirmado = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Cerrar la sala'),
          content: const Text(
            'Eres el anfitrión: si sales, la sala se cierra para todos.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              key: const Key('sala-cerrar-confirmar'),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Cerrar la sala'),
            ),
          ],
        ),
      );
      if (confirmado != true) return;
    }

    _vigilante.detener();
    try {
      await widget.partidas.salir(_sala.codigo);
    } on ErrorAuth {
      // Si el aviso no llega, el servidor libera el lugar al dejar de consultar.
    }
    navegador.pop();
  }

  @override
  Widget build(BuildContext context) {
    final perdida = _salaPerdida;
    final mapa = mapaNumero(_sala.mapa);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _salir();
      },
      child: Scaffold(
        appBar: barraPartida('Sala de partida'),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  if (perdida != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: estilo.AvisoJuego(
                        key: const Key('sala-perdida'),
                        icono: Icons.do_not_disturb_alt,
                        texto: perdida,
                        advertencia: true,
                      ),
                    )
                  else ...[
                    TarjetaCodigo(codigo: _sala.codigo),
                    const SizedBox(height: 12),
                  ],
                  TarjetaMapa(mapa: mapa),
                  const SizedBox(height: 12),
                  TarjetaJugadores(sala: _sala, usuario: _usuario),
                  const SizedBox(height: 20),
                  OutlinedButton(
                    key: const Key('sala-salir'),
                    onPressed: _salir,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        perdida != null
                            ? 'Volver al menú'
                            : _soyAnfitrion
                            ? 'Cerrar la sala'
                            : 'Salir de la sala',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
