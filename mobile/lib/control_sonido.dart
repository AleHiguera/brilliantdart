import 'package:flutter/foundation.dart';
import 'package:brilliant_mobile/almacen_pestana.dart';
import 'package:brilliant_mobile/sonidos.dart';

/// Si los sonidos del juego están silenciados. Recuerda la elección en
/// [almacen], así que se mantiene al volver a abrir la app.
class ControlSonido extends ValueNotifier<bool> {
  ControlSonido([AlmacenPestana? almacen])
    : _almacen = almacen ?? AlmacenEnMemoria(),
      super((almacen ?? AlmacenEnMemoria()).leer(clave) == 'si');

  static const String clave = 'brilliant.silencio';

  /// El de toda la app. En las pruebas empieza con sonido y no recuerda nada.
  static ControlSonido global = ControlSonido();

  final AlmacenPestana _almacen;

  bool get silenciado => value;

  void alternar() => silenciar(!value);

  void silenciar(bool silencio) {
    value = silencio;
    if (silencio) {
      _almacen.guardar(clave, 'si');
    } else {
      _almacen.borrar(clave);
    }
  }
}

/// Un [Sonido] que no suena mientras [control] esté en silencio, y que se
/// corta si lo silencian mientras suena.
class SonidoSilenciable extends Sonido {
  SonidoSilenciable(this.interno, this.control) {
    control.addListener(_alCambiar);
  }

  final Sonido interno;
  final ControlSonido control;

  void _alCambiar() {
    if (control.silenciado) interno.detener();
  }

  @override
  Future<void> reproducir() async {
    if (control.silenciado) return;
    await interno.reproducir();
  }

  @override
  Future<void> detener() => interno.detener();

  @override
  void dispose() {
    control.removeListener(_alCambiar);
    interno.dispose();
  }
}
