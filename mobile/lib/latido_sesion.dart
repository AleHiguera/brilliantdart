import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:brilliant_mobile/servicio_auth.dart';

/// Mientras [child] exista, avisa al servidor de que la sesión sigue abierta.
/// Si la app se cierra los avisos dejan de llegar y el usuario queda libre.
/// También es quien nota que se perdió la conexión, en cualquier pantalla.
class LatidoSesion extends StatefulWidget {
  const LatidoSesion({
    super.key,
    required this.auth,
    required this.alPerderSesion,
    required this.alDesconectarse,
    required this.child,
    this.primerLatido = intervalo,
  });

  static const Duration intervalo = Duration(seconds: 10);

  /// Tras un latido que no llegó se vuelve a intentar pronto, para saber
  /// enseguida si fue un tropiezo o se perdió la conexión.
  static const Duration reintento = Duration(seconds: 2);

  final ServicioAuth auth;

  /// El servidor dijo que la sesión ya no vale.
  final void Function(BuildContext context) alPerderSesion;

  /// Las peticiones dejaron de llegar al servidor.
  final void Function(BuildContext context, Desconexion desconexion)
  alDesconectarse;
  final Widget child;

  /// Cuánto esperar el primer latido. Una sesión recuperada al recargar la
  /// página se comprueba enseguida: el servidor pudo haberla cerrado.
  final Duration primerLatido;

  @override
  State<LatidoSesion> createState() => _LatidoSesionState();
}

class _LatidoSesionState extends State<LatidoSesion> {
  Timer? _temporizador;
  bool _terminado = false;

  @override
  void initState() {
    super.initState();
    widget.auth.desconexion.addListener(_revisarDesconexion);
    _programar(widget.primerLatido);
  }

  @override
  void dispose() {
    _terminar();
    widget.auth.desconexion.removeListener(_revisarDesconexion);
    super.dispose();
  }

  void _programar(Duration espera) {
    if (_terminado) return;
    _temporizador = Timer(espera, _latir);
  }

  void _terminar() {
    _terminado = true;
    _temporizador?.cancel();
  }

  Future<void> _latir() async {
    final sigueActiva = await widget.auth.mantenerSesion();
    if (!mounted || _terminado) return;
    if (!sigueActiva) {
      _terminar();
      widget.alPerderSesion(context);
      return;
    }
    _programar(
      widget.auth.conexion.fallando
          ? LatidoSesion.reintento
          : LatidoSesion.intervalo,
    );
  }

  void _revisarDesconexion() {
    final desconexion = widget.auth.desconexion.value;
    if (desconexion == null || !mounted || _terminado) return;
    _terminar();
    widget.alDesconectarse(context, desconexion);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
