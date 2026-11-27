import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:brilliant_mobile/copo_progreso.dart';
import 'package:brilliant_mobile/tema_mapa.dart';

/// La llama del Reino del Fuego donde se ven los 6 números iniciales: 6
/// lenguas de fuego en abanico que se encienden con su color al colocar cada
/// número. Hace lo mismo que la rueda de los otros mapas.
class LlamaProgresoIniciales extends StatelessWidget {
  const LlamaProgresoIniciales({super.key, required this.cantidad});

  final int cantidad;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const Key('initial-progress'),
      label: '$cantidad de 6 números iniciales colocados',
      child: SizedBox.square(
        dimension: 64,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(end: cantidad.toDouble()),
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
              builder: (context, valor, _) => CustomPaint(
                key: const Key('llama-progreso'),
                size: const Size.square(64),
                painter: PintorLlamaProgreso(valor),
              ),
            ),
            // La cuenta va en la brasa de la base.
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Container(
                width: 30,
                height: 18,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF7A1F0E),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: ColoresFuego.naranja, width: 1.2),
                ),
                child: Text(
                  '$cantidad/6',
                  key: const Key('initial-progress-count'),
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFFFE6B0),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PintorLlamaProgreso extends CustomPainter {
  PintorLlamaProgreso(this.avance);

  /// Números colocados; puede tener decimales durante la animación.
  final double avance;

  /// Dónde nace cada lengua, de izquierda a derecha, en fracción del ancho:
  /// paradas lado a lado sobre la brasa, como una fogata.
  static const List<double> posiciones = [0.16, 0.29, 0.43, 0.57, 0.71, 0.84];

  /// Hacia dónde se inclina cada lengua, en radianes desde la vertical: las
  /// de las orillas, un poco hacia afuera.
  static const List<double> inclinaciones = [
    -0.42,
    -0.22,
    -0.06,
    0.06,
    0.22,
    0.42,
  ];

  /// Qué tan larga es cada lengua: las del centro, las más altas.
  static const List<double> largos = [0.55, 0.78, 1, 0.94, 0.74, 0.52];

  @override
  void paint(Canvas canvas, Size size) {
    final alturaBase = size.height * 0.8;
    final largo = size.height * 0.74;
    final ancho = size.width * 0.085;
    final llenos = llenadoBrazos(avance);
    final contorno = Paint()
      ..color = ColoresFuego.rojo
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeJoin = StrokeJoin.round;

    // Primero las de afuera, para que las del centro queden al frente.
    for (final i in const [0, 5, 1, 4, 2, 3]) {
      final base = Offset(size.width * posiciones[i], alturaBase);
      final completa = lengua(base, inclinaciones[i], largo * largos[i], ancho);
      canvas.drawPath(completa, Paint()..color = ColoresFuego.apagado);
      if (llenos[i] > 0) {
        canvas.drawPath(
          lengua(base, inclinaciones[i], largo * largos[i] * llenos[i], ancho),
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [coloresBrazosCopo[i], _masClaro(coloresBrazosCopo[i])],
            ).createShader(completa.getBounds()),
        );
      }
      canvas.drawPath(completa, contorno);
    }
  }

  static Color _masClaro(Color color) => Color.lerp(color, Colors.white, 0.35)!;

  /// Una lengua de fuego: sale de [base] con [ancho] a cada lado, se abulta y
  /// termina en una punta que se curva hacia el centro, como una llama.
  static Path lengua(
    Offset base,
    double inclinacion,
    double largo,
    double ancho,
  ) {
    final direccion = Offset(math.sin(inclinacion), -math.cos(inclinacion));
    // Hacia la derecha de la lengua (mirando hacia donde apunta).
    final lado = Offset(-direccion.dy, direccion.dx);
    // Las de la izquierda curvan su punta a la derecha y al revés.
    final punta =
        base + direccion * largo + lado * (-inclinacion * largo * 0.55);
    Offset en(double alto, double desvio) =>
        base + direccion * (largo * alto) + lado * desvio;
    final derecha1 = en(0.35, ancho * 1.35);
    final derecha2 =
        en(0.75, ancho * 0.7) + lado * (-inclinacion * largo * 0.3);
    final izquierda1 =
        en(0.7, -ancho * 0.6) + lado * (-inclinacion * largo * 0.3);
    final izquierda2 = en(0.3, -ancho * 1.3);
    final pieDerecho = en(0, ancho * 0.7);
    final pieIzquierdo = en(0, -ancho * 0.7);
    return Path()
      ..moveTo(pieDerecho.dx, pieDerecho.dy)
      ..cubicTo(
        derecha1.dx,
        derecha1.dy,
        derecha2.dx,
        derecha2.dy,
        punta.dx,
        punta.dy,
      )
      ..cubicTo(
        izquierda1.dx,
        izquierda1.dy,
        izquierda2.dx,
        izquierda2.dy,
        pieIzquierdo.dx,
        pieIzquierdo.dy,
      )
      ..close();
  }

  @override
  bool shouldRepaint(PintorLlamaProgreso anterior) => anterior.avance != avance;
}
