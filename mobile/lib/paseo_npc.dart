import 'dart:math' as math;

/// Cómo pasea un personajito del menú: camina de lado a lado, se da la vuelta
/// en las orillas y cada cierto tiempo se detiene a saludar.
///
/// Solo lleva la cuenta; no dibuja nada. Se le avisa del tiempo que pasó con
/// [avanzar].
class PaseoNpc {
  PaseoNpc({
    required this.x,
    this.direccion = 1,
    required this.velocidad,
    required this.duracionCaminata,
    this.duracionSaludo = 2.2,
  }) : assert(direccion == 1 || direccion == -1),
       assert(velocidad > 0),
       assert(duracionCaminata > 0 && duracionSaludo > 0);

  /// Lo que dice al saludar.
  static const String saludo = '¡Hola!';

  /// Posición del borde izquierdo, en píxeles desde la orilla izquierda.
  double x;

  /// 1 hacia la derecha, −1 hacia la izquierda.
  int direccion;

  /// Píxeles por segundo al caminar.
  final double velocidad;

  /// Segundos que camina antes de detenerse a saludar.
  final double duracionCaminata;

  /// Segundos que se queda saludando.
  final double duracionSaludo;

  bool _saludando = false;
  double _reloj = 0;
  double _fase = 0;

  /// Si está detenido diciendo «¡Hola!».
  bool get saludando => _saludando;

  /// Segundos que lleva en lo que está haciendo (caminar o saludar).
  double get reloj => _reloj;

  /// El balanceo de las piernas, de −1 a 1. Quieto al saludar.
  double get paso => _saludando ? 0 : math.sin(_fase * 2 * math.pi);

  /// Cuánto sube y baja el cuerpo al caminar, de 0 a 1.
  double get rebote => paso.abs();

  /// Avanza [segundos] en un espacio de [ancho] píxeles donde el personaje
  /// mide [tamano] de ancho. Un tiempo negativo no hace nada; uno muy grande
  /// (por ejemplo, al volver de otra pantalla) se limita para que no salte.
  void avanzar(
    double segundos, {
    required double ancho,
    required double tamano,
  }) {
    if (segundos <= 0) return;
    final dt = math.min(segundos, 0.1);
    final limite = math.max(0.0, ancho - tamano);
    _reloj += dt;

    if (_saludando) {
      if (_reloj >= duracionSaludo) {
        _saludando = false;
        _reloj = 0;
      }
      x = x.clamp(0, limite);
      return;
    }

    // Dos pasos por cada 24 píxeles: las piernas van al ritmo de la marcha.
    _fase = (_fase + dt * velocidad / 24) % 1;
    x += direccion * velocidad * dt;
    if (x <= 0) {
      x = 0;
      direccion = 1;
    } else if (x >= limite) {
      x = limite;
      direccion = -1;
    }
    if (_reloj >= duracionCaminata) {
      _saludando = true;
      _reloj = 0;
    }
  }
}
