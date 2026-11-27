import 'dart:math' as math;

/// Un copo de nieve. Su posición va de 0 a 1 en cada eje (fracción del
/// ancho y del alto), así sirve para cualquier tamaño de pantalla.
class CopoNieve {
  CopoNieve({
    required this.x,
    required this.y,
    required this.tamano,
    required this.velocidad,
    required this.fase,
  });

  /// Dónde cae, de 0 (izquierda) a 1 (derecha), sin contar el vaivén.
  double x;

  /// Qué tan abajo va, de 0 (arriba) a 1 (abajo).
  double y;

  /// Su tamaño en píxeles. Los grandes se dibujan como copito de 6 brazos.
  final double tamano;

  /// Cuánto del alto baja por segundo.
  final double velocidad;

  /// Para que cada uno se mezca de lado a lado a su propio ritmo.
  double fase;

  /// Cuánto se mueve de lado a lado, en fracción del ancho.
  static const double vaiven = 0.015;

  /// Dónde se ve ahora en x, con el vaivén.
  double get xVisible => x + math.sin(fase) * vaiven;

  /// Cuánto va girando, en radianes.
  double get giro => fase * 0.6;
}

/// La nieve que cae detrás del tablero del Reino Helado: copos de distintos
/// tamaños y velocidades que, al salir por abajo, vuelven a caer desde arriba.
class Nevada {
  Nevada({this.cantidad = 36, int semilla = 7}) : _azar = math.Random(semilla) {
    copos = [
      for (var i = 0; i < cantidad; i++)
        CopoNieve(
          x: _azar.nextDouble(),
          // Repartidos por toda la pantalla desde el principio.
          y: _azar.nextDouble(),
          tamano:
              tamanoMinimo + _azar.nextDouble() * (tamanoMaximo - tamanoMinimo),
          velocidad:
              velocidadMinima +
              _azar.nextDouble() * (velocidadMaxima - velocidadMinima),
          fase: _azar.nextDouble() * 2 * math.pi,
        ),
    ];
  }

  static const double tamanoMinimo = 2;
  static const double tamanoMaximo = 7;
  static const double velocidadMinima = 0.03;
  static const double velocidadMaxima = 0.08;

  /// Desde dónde vuelve a caer un copo (un poquito arriba de la pantalla).
  static const double arriba = -0.05;

  /// Hasta dónde baja antes de volver arriba (un poquito debajo).
  static const double abajo = 1.05;

  final int cantidad;
  final math.Random _azar;
  late final List<CopoNieve> copos;

  /// Avanza [segundos]. Un tiempo negativo no hace nada; uno grande se
  /// limita para que no salten de golpe.
  void avanzar(double segundos) {
    if (segundos <= 0) return;
    final dt = math.min(segundos, 0.1);
    for (final copo in copos) {
      copo
        ..y += copo.velocidad * dt
        ..fase += dt * 1.5;
      if (copo.y > abajo) {
        copo
          ..y = arriba
          ..x = _azar.nextDouble();
      }
    }
  }
}
