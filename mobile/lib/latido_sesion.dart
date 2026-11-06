import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:brilliant_mobile/servicio_auth.dart';

/// Mientras [child] exista, avisa al servidor de que la sesión sigue abierta.
/// Si la app se cierra los avisos dejan de llegar y el usuario queda libre.
class LatidoSesion extends StatefulWidget {
  const LatidoSesion({
    super.key,
    required this.auth,
    required this.alPerderSesion,
    required this.child,
  });

  static const Duration intervalo = Duration(seconds: 10);

  final ServicioAuth auth;
  final void Function(BuildContext context) alPerderSesion;
  final Widget child;

  @override
  State<LatidoSesion> createState() => _LatidoSesionState();
}

class _LatidoSesionState extends State<LatidoSesion> {
  late final Timer _temporizador;

  @override
  void initState() {
    super.initState();
    _temporizador = Timer.periodic(LatidoSesion.intervalo, (_) => _latir());
  }

  @override
  void dispose() {
    _temporizador.cancel();
    super.dispose();
  }

  Future<void> _latir() async {
    final sigueActiva = await widget.auth.mantenerSesion();
    if (!sigueActiva && mounted) {
      _temporizador.cancel();
      widget.alPerderSesion(context);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
