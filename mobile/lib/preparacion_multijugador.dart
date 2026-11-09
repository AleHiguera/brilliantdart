import 'package:flutter/foundation.dart';
import 'package:brilliant_mobile/servicio_auth.dart';
import 'package:brilliant_mobile/servicio_partidas.dart';
import 'package:brilliant_mobile/vigilante_sala.dart';

/// Lleva la fase en que cada jugador coloca sus números iniciales: envía el
/// tablero propio y avisa cuando ya terminaron todos. No sabe nada de pantallas
/// ni de las reglas del tablero.
class PreparacionMultijugador extends ChangeNotifier {
  PreparacionMultijugador({required this.partidas, required SalaPartida sala})
    : _sala = sala {
    _vigilante = VigilanteSala(
      partidas: partidas,
      codigo: sala.codigo,
      alCambiar: _actualizar,
      alTerminar: (mensaje) {
        _perdida = mensaje;
        _avisar();
      },
    );
  }

  final ServicioPartidas partidas;
  late final VigilanteSala _vigilante;

  SalaPartida _sala;
  String? _perdida;
  String? _error;
  bool _enviando = false;
  bool _cerrada = false;

  SalaPartida get sala => _sala;

  /// Por qué ya no se puede seguir, como que el anfitrión cerró la partida.
  String? get perdida => _perdida;

  /// Por qué no se pudo enviar el tablero; se puede volver a intentar.
  String? get error => _error;
  bool get enviando => _enviando;

  String? get usuario => partidas.auth.sesion?.usuario;
  bool get soyAnfitrion => _sala.anfitrion == usuario;
  bool get yaFinalice => _sala.haFinalizado(usuario);

  /// Todos terminaron: ya se pueden lanzar los dados.
  bool get todosTerminaron => _sala.configurada;

  /// Mientras se envía o después de finalizar, el tablero ya no cambia.
  bool get puedeEditar => !_enviando && !yaFinalice && _perdida == null;

  /// Sigue la sala hasta que terminen todos.
  void iniciar() {
    if (!todosTerminaron) _vigilante.iniciar();
  }

  Future<void> finalizar(List<int> numeros) async {
    if (!puedeEditar) return;
    _enviando = true;
    _error = null;
    _avisar();
    try {
      _actualizar(await partidas.finalizarTablero(_sala.codigo, numeros));
    } on ErrorAuth catch (e) {
      _error = e.mensaje;
    } finally {
      _enviando = false;
      _avisar();
    }
  }

  /// Deja la partida. Si el aviso no llega, el servidor libera el lugar al
  /// dejar de recibir consultas.
  Future<void> salir() async {
    _vigilante.detener();
    try {
      await partidas.salir(_sala.codigo);
    } on ErrorAuth {
      // Igual se sale de la pantalla.
    }
  }

  void _actualizar(SalaPartida sala) {
    _sala = sala;
    if (sala.configurada) _vigilante.detener();
    _avisar();
  }

  void _avisar() {
    if (!_cerrada) notifyListeners();
  }

  @override
  void dispose() {
    _cerrada = true;
    _vigilante.detener();
    super.dispose();
  }
}
