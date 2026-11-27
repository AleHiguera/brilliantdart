import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:brilliant_mobile/tema_mapa.dart';

/// Los colores de cada brazo, uno por número inicial, los mismos de la rueda.
const List<Color> coloresBrazosCopo = [
  Color(0xFFFFEB3B),
  Color(0xFF4CAF50),
  Color(0xFF2196F3),
  Color(0xFF9C27B0),
  Color(0xFFF44336),
  Color(0xFFFF9800),
];

/// Cuánto está lleno cada brazo (de 0 a 1) cuando van [avance] números
/// colocados; puede tener decimales mientras se anima.
List<double> llenadoBrazos(double avance) => [
  for (var i = 0; i < 6; i++) (avance - i).clamp(0.0, 1.0),
];

/// El copo de nieve del Reino Helado donde se ven los 6 números iniciales:
/// cada brazo se llena con su color al colocar un número. Hace lo mismo que la
/// rueda de los otros mapas.
class CopoProgresoIniciales extends StatelessWidget {
  const CopoProgresoIniciales({super.key, required this.cantidad});

  final int cantidad;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const Key('initial-progress'),
      label: '$cantidad de 6 números iniciales colocados',
      child: SizedBox.square(
        dimension: 64,
        child: Stack(
          alignment: Alignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(end: cantidad.toDouble()),
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
              builder: (context, valor, _) => CustomPaint(
                key: const Key('copo-progreso'),
                size: const Size.square(64),
                painter: PintorCopoProgreso(valor),
              ),
            ),
            Text(
              '$cantidad/6',
              key: const Key('initial-progress-count'),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1B4F7A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PintorCopoProgreso extends CustomPainter {
  PintorCopoProgreso(this.avance);

  /// Números colocados; puede tener decimales durante la animación.
  final double avance;

  /// Cada brazo apunta hacia afuera desde el centro, empezando por arriba.
  static double anguloBrazo(int indice) => -math.pi / 2 + indice * math.pi / 3;

  @override
  void paint(Canvas canvas, Size size) {
    final centro = size.center(Offset.zero);
    final largo = math.min(size.width, size.height) / 2 - 3;
    final llenos = llenadoBrazos(avance);

    for (var i = 0; i < 6; i++) {
      final direccion = Offset(
        math.cos(anguloBrazo(i)),
        math.sin(anguloBrazo(i)),
      );
      // Primero el brazo vacío (azul muy claro) y encima, lo que esté lleno.
      _brazo(canvas, centro, direccion, largo, 1, ColoresHielo.vacio);
      if (llenos[i] > 0) {
        _brazo(
          canvas,
          centro,
          direccion,
          largo,
          llenos[i],
          coloresBrazosCopo[i],
        );
      }
    }

    // El centro: un hexágono blanco donde va la cuenta.
    final hexagono = Path();
    for (var i = 0; i < 6; i++) {
      final punto =
          centro +
          Offset(
                math.cos(anguloBrazo(i) + math.pi / 6),
                math.sin(anguloBrazo(i) + math.pi / 6),
              ) *
              largo *
              0.42;
      i == 0
          ? hexagono.moveTo(punto.dx, punto.dy)
          : hexagono.lineTo(punto.dx, punto.dy);
    }
    hexagono.close();
    canvas
      ..drawPath(hexagono, Paint()..color = Colors.white)
      ..drawPath(
        hexagono,
        Paint()
          ..color = ColoresHielo.azul
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
  }

  /// Un brazo del copo con sus dos ramitas, lleno hasta [fraccion].
  void _brazo(
    Canvas canvas,
    Offset centro,
    Offset direccion,
    double largo,
    double fraccion,
    Color color,
  ) {
    final contorno = Paint()
      ..color = ColoresHielo.azul
      ..strokeWidth = 7.5
      ..strokeCap = StrokeCap.round;
    final relleno = Paint()
      ..color = color
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final punta = centro + direccion * largo * fraccion;
    // Las ramitas en V salen a 2/3 del brazo, cuando ya llegó el llenado.
    final base = centro + direccion * largo * 0.66;
    final ramas = fraccion < 0.66
        ? const <Offset>[]
        : [
            for (final lado in [-1.0, 1.0])
              base +
                  Offset(
                        math.cos(
                          math.atan2(direccion.dy, direccion.dx) +
                              lado * math.pi / 4,
                        ),
                        math.sin(
                          math.atan2(direccion.dy, direccion.dx) +
                              lado * math.pi / 4,
                        ),
                      ) *
                      largo *
                      0.3,
          ];

    // Primero todos los contornos y luego el color, para que ningún contorno
    // quede encima del brazo.
    canvas.drawLine(centro, punta, contorno);
    for (final rama in ramas) {
      canvas.drawLine(base, rama, contorno..strokeWidth = 5.5);
    }
    canvas.drawLine(centro, punta, relleno);
    for (final rama in ramas) {
      canvas.drawLine(base, rama, relleno..strokeWidth = 3);
    }
  }

  @override
  bool shouldRepaint(PintorCopoProgreso anterior) => anterior.avance != avance;
}
