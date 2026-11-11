import 'package:flutter/foundation.dart';
import 'package:brilliant_mobile/guardado_partida.dart';
import 'package:brilliant_mobile/servicio_auth.dart';
import 'package:brilliant_mobile/servicio_partidas.dart';
import 'package:brilliant_mobile/vigilante_sala.dart';

/// Lo que un jugador comparte con la partida una vez que comenzó: envía su
/// tablero, sigue las rondas de dados que lanza el servidor y avisa cuando
/// terminó su turno. No sabe nada de pantallas ni de las reglas del tablero.
class PartidaCompartida extends ChangeNotifier {
  PartidaCompartida({required this.partidas, required SalaPartida sala})
    : _sala = sala,
      guardado = GuardadoPartida(partidas.auth.almacen, sala.codigo) {
    // Tras recargar la página se sabe qué turno ya se había jugado.
    if (guardado.leerTurno() case final turno?) {
      _rondaJugada = turno.ronda;
      _tableroLleno = turno.tableroLleno;
      _zonaCompletada = turno.zona;
    }
    _vigilante = VigilanteSala(
      partidas: partidas,
      codigo: sala.codigo,
      alCambiar: _actualizar,
      alTerminar: (mensaje) {
        _perdida = mensaje;
        _dejarDeJugar();
        _avisar();
      },
    );
  }

  final ServicioPartidas partidas;

  /// Lo que se guarda en la pestaña para seguir la partida tras recargar.
  final GuardadoPartida guardado;
  late final VigilanteSala _vigilante;

  SalaPartida _sala;
  String? _perdida;
  String? _error;
  bool _enviando = false;
  bool _cerrada = false;

  /// Última ronda que este jugador ya jugó aquí, aunque el servidor no lo sepa.
  int _rondaJugada = 0;
  bool _tableroLleno = false;
  int? _zonaCompletada;
  bool _avisandoTurno = false;

  SalaPartida get sala => _sala;

  /// Por qué ya no se puede seguir, como que el servidor lo sacó por ausencia.
  String? get perdida => _perdida;

  /// Por qué no se pudo enviar el tablero; se puede volver a intentar.
  String? get error => _error;
  bool get enviando => _enviando;

  String? get usuario => partidas.auth.sesion?.usuario;
  bool get yaFinalice => _sala.haFinalizado(usuario);

  /// Todos terminaron: ya se pueden lanzar los dados.
  bool get todosTerminaron => _sala.configurada;

  /// Mientras se envía o después de finalizar, el tablero ya no cambia.
  bool get puedeEditar => !_enviando && !yaFinalice && _perdida == null;

  bool get terminada => _sala.terminada;
  bool get gane => _sala.ganadores.contains(usuario);

  /// Hay un resultado que este jugador todavía no ha usado.
  bool get puedoJugarRonda =>
      _sala.ronda > 0 &&
      _sala.ronda != _rondaJugada &&
      !_sala.haJugado(usuario);

  /// El resultado de la ronda en juego, el mismo para toda la partida.
  (int, int) get resultado => (_sala.dados[0], _sala.dados[1]);

  /// El registro de zonas del servidor, más la que este jugador acaba de
  /// completar: así sus puntos se ven al momento y no dependen de que el aviso
  /// ya haya llegado. Su lugar no cambia, porque solo cuentan rondas anteriores.
  Map<int, Map<String, int>> get rondasPorZona {
    final zona = _zonaCompletada;
    final yo = usuario;
    final registro = {
      for (final MapEntry(key: id, value: rondas) in _sala.zonas.entries)
        id: {...rondas},
    };
    if (zona != null && yo != null) {
      (registro[zona] ??= {}).putIfAbsent(yo, () => _rondaJugada);
    }
    return registro;
  }

  /// La ronda en que este jugador podría completar su siguiente zona: la actual
  /// si aún no juega, o la próxima si ya terminó su turno.
  int get rondaDeMiSiguienteJugada =>
      puedoJugarRonda || _sala.ronda == 0 ? _sala.ronda : _sala.ronda + 1;

  /// Sigue la partida mientras el jugador esté en esta pantalla. También es la
  /// señal de que sigue ahí: sin ella el servidor lo sacaría de la partida.
  /// Si se pierde la conexión mientras tanto, la sesión sabe que abandonó.
  void iniciar() {
    if (!_sala.terminada) partidas.auth.partidaEnCurso = _sala.codigo;
    _vigilante.iniciar();
  }

  /// Ya no está jugando: perder la conexión desde ahora no es abandonar, y
  /// recargar la página ya no tiene a qué partida volver.
  void _dejarDeJugar() {
    if (partidas.auth.partidaEnCurso == _sala.codigo) {
      partidas.auth.partidaEnCurso = null;
    }
    guardado.borrar();
  }

  /// El jugador ya movió o pasó. Si el aviso no llega se repite en la siguiente
  /// consulta: perderlo dejaría a todos esperando la próxima ronda.
  void terminarTurno({required bool tableroLleno, int? zonaCompletada}) {
    _rondaJugada = _sala.ronda;
    _tableroLleno = tableroLleno;
    _zonaCompletada = zonaCompletada;
    guardado.guardarTurno((
      ronda: _rondaJugada,
      tableroLleno: tableroLleno,
      zona: zonaCompletada,
    ));
    _avisar();
    _avisarTurno();
  }

  Future<void> _avisarTurno() async {
    if (_avisandoTurno) return;
    _avisandoTurno = true;
    try {
      final sala = await partidas.terminarTurno(
        _sala.codigo,
        _rondaJugada,
        tableroLleno: _tableroLleno,
        zonaCompletada: _zonaCompletada,
      );
      _avisandoTurno = false;
      _actualizar(sala);
    } on ErrorAuth {
      // Se reintenta con la siguiente consulta; si la sala ya no existe, esa
      // misma consulta lo dirá.
      _avisandoTurno = false;
    }
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
    _dejarDeJugar();
    try {
      await partidas.salir(_sala.codigo);
    } on ErrorAuth {
      // Igual se sale de la pantalla.
    }
  }

  void _actualizar(SalaPartida sala) {
    // Una consulta que salió antes de avanzar puede llegar después: las rondas
    // nunca retroceden.
    if (_cerrada || sala.ronda < _sala.ronda) return;
    _sala = sala;
    // Terminada, ya no hay nada nuevo que consultar.
    if (sala.terminada) {
      _vigilante.detener();
      _dejarDeJugar();
    }
    _avisar();
    if (_rondaJugada == sala.ronda &&
        _rondaJugada > 0 &&
        !sala.haJugado(usuario)) {
      _avisarTurno();
    }
  }

  void _avisar() {
    if (!_cerrada) notifyListeners();
  }

  @override
  void dispose() {
    _cerrada = true;
    _vigilante.detener();
    _dejarDeJugar();
    super.dispose();
  }
}
