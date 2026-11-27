import 'dart:math' as math;

/// Una moneda que salta al ganar ELO. Su posición está en píxeles desde el
/// punto de donde brotan.
class Moneda {
  Moneda({
    required this.vx,
    required this.vy,
    required this.giro,
    required this.velocidadGiro,
    required this.retraso,
  });

  double x = 0;
  double y = 0;
  double vx;
  double vy;

  /// Cuánto ha girado; se dibuja más angosta de perfil para que parezca que
  /// da vueltas.
  double giro;
  final double velocidadGiro;

  /// Segundos que espera antes de saltar, para que no salgan todas juntas.
  double retraso;

  /// Si ya saltó (pasó su retraso).
  bool get enElAire => retraso <= 0;

  /// Qué tan ancha se ve al girar, de 0 (de perfil) a 1 (de frente).
  double get anchoVisible => math.cos(giro).abs();
}

/// La lluvia de monedas al ganar ELO: brotan hacia arriba, giran y caen con
/// la gravedad hasta salir de la vista. Solo lleva la cuenta; no dibuja nada.
class LluviaMonedas {
  LluviaMonedas({required int cantidad, int semilla = 3})
    : _azar = math.Random(semilla) {
    monedas = [
      for (var i = 0; i < cantidad; i++)
        Moneda(
          vx: (_azar.nextDouble() * 2 - 1) * 140,
          vy: -(170 + _azar.nextDouble() * 120),
          giro: _azar.nextDouble() * math.pi,
          velocidadGiro: 8 + _azar.nextDouble() * 8,
          retraso: i * 0.06,
        ),
    ];
  }

  /// Píxeles por segundo al cuadrado hacia abajo.
  static const double gravedad = 560;

  /// Una moneda que bajó tanto ya no se ve.
  static const double limiteAbajo = 140;

  /// La animación no dura más que esto, pase lo que pase.
  static const double duracionMaxima = 3;

  /// Cuántas monedas saltan al ganar [cambio] de ELO: más ELO, más monedas,
  /// entre 6 y 18. Si no se ganó nada, ninguna.
  static int cantidadPara(int cambio) =>
      cambio <= 0 ? 0 : (4 + cambio ~/ 2).clamp(6, 18);

  final math.Random _azar;
  late final List<Moneda> monedas;
  double _tiempo = 0;

  double get tiempo => _tiempo;

  /// Si ya cayeron todas (o se acabó el tiempo).
  bool get terminada =>
      _tiempo >= duracionMaxima ||
      monedas.every((m) => m.enElAire && m.y > limiteAbajo);

  void avanzar(double segundos) {
    if (segundos <= 0 || terminada) return;
    final dt = math.min(segundos, 0.05);
    _tiempo += dt;
    for (final moneda in monedas) {
      if (!moneda.enElAire) {
        moneda.retraso -= dt;
        continue;
      }
      moneda
        ..vy += gravedad * dt
        ..x += moneda.vx * dt
        ..y += moneda.vy * dt
        ..giro += moneda.velocidadGiro * dt;
    }
  }
}

/// El número que se ve mientras cuenta del ELO de [antes] al de [despues];
/// [avance] va de 0 (empieza) a 1 (terminó).
int eloContado(int antes, int despues, double avance) =>
    (antes + (despues - antes) * avance.clamp(0.0, 1.0)).round();
