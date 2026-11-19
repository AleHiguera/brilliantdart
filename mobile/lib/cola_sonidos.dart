import 'dart:collection';

import 'package:brilliant_mobile/sonidos.dart';

/// Los sonidos del juego (festejo, tristeza, victoria) suenan de uno en uno,
/// en el orden en que se pidieron: si coinciden, el siguiente espera a que
/// termine el anterior en vez de encimarse.
///
/// Por ejemplo, si en la misma ronda llenas una zona y otro jugador llena
/// otra, primero suena tu festejo y después la tristeza; si además termina la
/// partida, la victoria suena al final.
class ColaSonidos {
  final Queue<Sonido> _pendientes = Queue();
  bool _sonando = false;
  bool _cerrada = false;

  /// Cuántos esperan su turno, sin contar el que está sonando.
  int get pendientes => _pendientes.length;

  bool get sonando => _sonando;

  /// Pone [sonido] al final de la fila; si no suena nada, empieza ya.
  void tocar(Sonido sonido) {
    if (_cerrada) return;
    _pendientes.add(sonido);
    if (!_sonando) _siguiente();
  }

  Future<void> _siguiente() async {
    _sonando = true;
    while (_pendientes.isNotEmpty && !_cerrada) {
      final sonido = _pendientes.removeFirst();
      try {
        await sonido.reproducir();
      } catch (_) {
        // Un sonido que falla no deja a los demás sin sonar.
      }
    }
    _sonando = false;
  }

  /// Al salir del tablero: lo que esperaba ya no suena.
  void cerrar() {
    _cerrada = true;
    _pendientes.clear();
  }
}
