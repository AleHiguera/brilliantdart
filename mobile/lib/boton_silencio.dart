import 'package:flutter/material.dart';
import 'package:brilliant_mobile/control_sonido.dart';

/// La bocina de arriba del tablero: un toque silencia todos los sonidos y
/// otro los vuelve a activar.
class BotonSilencio extends StatelessWidget {
  const BotonSilencio({super.key, required this.control});

  final ControlSonido control;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: control,
      builder: (context, silenciado, _) => IconButton(
        key: const Key('sonido-boton'),
        tooltip: silenciado ? 'Activar sonidos' : 'Silenciar sonidos',
        onPressed: control.alternar,
        icon: Icon(
          silenciado ? Icons.volume_off : Icons.volume_up,
          key: Key(silenciado ? 'sonido-apagado' : 'sonido-encendido'),
        ),
      ),
    );
  }
}
