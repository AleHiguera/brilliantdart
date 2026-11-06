import 'dart:async';

import 'package:brilliant_mobile/servicio_auth.dart';
import 'package:brilliant_mobile/servicio_partidas.dart';

/// Pregunta al servidor cada cierto tiempo cómo va una sala y avisa de los
/// cambios. No sabe nada de pantallas.
class VigilanteSala {
  VigilanteSala({
    required this.partidas,
    required this.codigo,
    required this.alCambiar,
    required this.alTerminar,
  });

  /// Cada cuánto se pregunta al servidor quién está en la sala.
  static const Duration intervalo = Duration(seconds: 2);

  final ServicioPartidas partidas;
  final String codigo;
  final void Function(SalaPartida sala) alCambiar;

  /// La sala ya no existe o el jugador ya no está en ella.
  final void Function(String mensaje) alTerminar;

  Timer? _temporizador;
  bool _detenido = false;
  bool _consultando = false;

  void iniciar() {
    _temporizador = Timer.periodic(intervalo, (_) => consultar());
  }

  void detener() {
    _detenido = true;
    _temporizador?.cancel();
  }

  Future<void> consultar() async {
    if (_consultando || _detenido) return;
    _consultando = true;
    try {
      final sala = await partidas.consultar(codigo);
      if (!_detenido) alCambiar(sala);
    } on ErrorAuth catch (e) {
      // Sin conexión se sigue intentando, y de una sesión perdida ya se encarga
      // LatidoSesion: solo un rechazo de la sala significa que se terminó.
      if (e.codigo == 409 && !_detenido) {
        detener();
        alTerminar(e.mensaje);
      }
    } finally {
      _consultando = false;
    }
  }
}
