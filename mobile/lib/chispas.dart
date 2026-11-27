import 'dart:math' as math;

/// Una brasita de fuego. Su posición va de 0 a 1 en cada eje (fracción del
/// ancho y del alto), así sirve para cualquier tamaño de pantalla.
class Chispa {
  Chispa({
    required this.x,
    required this.y,
    required this.tamano,
    required this.velocidad,
    required this.fase,
  });

  /// Dónde sube, de 0 (izquierda) a 1 (derecha), sin contar el vaivén.
  double x;

  /// Qué tan arriba va, de 0 (arriba) a 1 (abajo).
  double y;

  /// Su tamaño en píxeles.
  final double tamano;

  /// Cuánto del alto sube por segundo.
  final double velocidad;

  /// Para que cada una titile y se mezca a su propio ritmo.
  double fase;

  /// Cuánto se mueve de lado a lado, en fracción del ancho.
  static const double vaiven = 0.02;

  /// Dónde se ve ahora en x, con el vaivén.
  double get xVisible => x + math.sin(fase * 0.8) * vaiven;

  /// Qué tan encendida se ve, de 0.35 a 1: titila.
  double get brillo => 0.675 + 0.325 * math.sin(fase * 3);

  /// Qué tan caliente está, de 0 (recién salida, amarilla) a 1 (arriba, ya
  /// roja y apagándose).
  double get enfriamiento => (1 - y).clamp(0.0, 1.0);
}

/// Las brasitas que suben detrás del tablero del Reino del Fuego. Al salir
/// por arriba vuelven a salir desde abajo.
class Chispas {
  Chispas({this.cantidad = 30, int semilla = 5})
    : _azar = math.Random(semilla) {
    chispas = [
      for (var i = 0; i < cantidad; i++)
        Chispa(
          x: _azar.nextDouble(),
          // Repartidas por toda la pantalla desde el principio.
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

  static const double tamanoMinimo = 1.5;
  static const double tamanoMaximo = 4;
  static const double velocidadMinima = 0.05;
  static const double velocidadMaxima = 0.14;

  /// Desde dónde vuelve a salir una brasa (un poquito debajo de la pantalla).
  static const double abajo = 1.05;

  /// Hasta dónde sube antes de volver abajo (un poquito arriba).
  static const double arriba = -0.05;

  final int cantidad;
  final math.Random _azar;
  late final List<Chispa> chispas;

  /// Avanza [segundos]. Un tiempo negativo no hace nada; uno grande se
  /// limita para que no salten de golpe.
  void avanzar(double segundos) {
    if (segundos <= 0) return;
    final dt = math.min(segundos, 0.1);
    for (final chispa in chispas) {
      chispa
        ..y -= chispa.velocidad * dt
        ..fase += dt * 2;
      if (chispa.y < arriba) {
        chispa
          ..y = abajo
          ..x = _azar.nextDouble();
      }
    }
  }
}
