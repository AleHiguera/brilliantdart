import 'package:flutter/material.dart';
import 'package:brilliant_mobile/guardado_partida.dart';
import 'package:brilliant_mobile/sala_partida.dart';
import 'package:brilliant_mobile/servicio_auth.dart';
import 'package:brilliant_mobile/servicio_partidas.dart';

/// Al abrir la app con una partida en juego guardada (porque se recargó la
/// página), vuelve a entrar en ella. Si el servidor ya no la deja, explica
/// por qué y se queda en [child].
class ReanudarPartida extends StatefulWidget {
  const ReanudarPartida({super.key, required this.auth, required this.child});

  final ServicioAuth auth;
  final Widget child;

  @override
  State<ReanudarPartida> createState() => _ReanudarPartidaState();
}

class _ReanudarPartidaState extends State<ReanudarPartida> {
  @override
  void initState() {
    super.initState();
    final codigo = widget.auth.partidaEnCurso;
    if (codigo != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _volver(codigo));
    }
  }

  Future<void> _volver(String codigo) async {
    final partidas = ServicioPartidas(widget.auth);
    try {
      final sala = await partidas.unirse(codigo);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SalaPartidaPage(partidas: partidas, sala: sala),
        ),
      );
    } on ErrorAuth catch (e) {
      // Una sesión que ya no vale la atiende el latido, que vuelve al inicio.
      if (e.codigo == 401 || !mounted) return;
      _olvidar(codigo);
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          key: const Key('reanudar-aviso'),
          title: const Text('No se pudo volver a la partida'),
          content: Text(e.mensaje),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
    }
  }

  void _olvidar(String codigo) {
    if (widget.auth.partidaEnCurso == codigo) widget.auth.partidaEnCurso = null;
    GuardadoPartida(widget.auth.almacen, codigo).borrar();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
