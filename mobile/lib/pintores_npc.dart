import 'package:flutter/material.dart';

/// Colores de los personajitos del menú.
abstract final class ColoresNpc {
  static const Color contorno = Color(0xFF1B1B1B);
  static const Color gorro = Colors.white;
  static const Color piel = Color(0xFFFCD9BE);
  static const Color camisa = Color(0xFF3FB6F2);
  static const Color short = Color(0xFF2F5FD0);
  static const Color mochila = Color(0xFF7ED957);
  static const Color boca = Color(0xFF8E2B2B);
  static const Color perro = Color(0xFFF7C325);
  static const Color hocico = Color(0xFFFDE38A);
}

/// Medidas en las que se dibuja cada personaje (luego se escala).
const Size tamanoNino = Size(30, 40);
const Size tamanoPerro = Size(34, 30);

Paint _relleno(Color color) => Paint()..color = color;

final Paint _linea = Paint()
  ..color = ColoresNpc.contorno
  ..style = PaintingStyle.stroke
  ..strokeWidth = 1.2
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

/// Rellena una figura y le pone contorno negro.
void _figura(Canvas canvas, Path figura, Color color) {
  canvas
    ..drawPath(figura, _relleno(color))
    ..drawPath(figura, _linea);
}

/// Una extremidad: trazo negro grueso con el color encima.
void _extremidad(Canvas canvas, Offset desde, Offset hasta, Color color) {
  canvas
    ..drawLine(
      desde,
      hasta,
      Paint()
        ..color = ColoresNpc.contorno
        ..strokeWidth = 3.4
        ..strokeCap = StrokeCap.round,
    )
    ..drawLine(
      desde,
      hasta,
      Paint()
        ..color = color
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round,
    );
}

/// Un niño con gorro blanco de orejitas, camisa celeste, short azul y mochila
/// verde. Mira hacia la derecha; para que mire a la izquierda se voltea.
class PintorNino extends CustomPainter {
  const PintorNino({required this.paso, required this.saludando});

  /// Balanceo de las piernas, de −1 a 1.
  final double paso;
  final bool saludando;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(
      size.width / tamanoNino.width,
      size.height / tamanoNino.height,
    );

    // Mochila, detrás del cuerpo.
    _figura(
      canvas,
      Path()..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(4, 18, 9, 12),
          const Radius.circular(4),
        ),
      ),
      ColoresNpc.mochila,
    );

    // Piernas con zapatos.
    for (final (cadera, lado) in [(13.0, 1.0), (18.0, -1.0)]) {
      final pie = Offset(cadera + paso * 2.5 * lado, 37);
      _extremidad(canvas, Offset(cadera, 31), pie, ColoresNpc.piel);
      canvas.drawOval(
        Rect.fromCenter(
          center: pie + const Offset(0.8, 0.6),
          width: 4.5,
          height: 2.6,
        ),
        _relleno(ColoresNpc.contorno),
      );
    }

    // Short y camisa.
    _figura(
      canvas,
      Path()..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(10.5, 27, 10, 5),
          const Radius.circular(1.5),
        ),
      ),
      ColoresNpc.short,
    );
    _figura(
      canvas,
      Path()..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(10, 19, 11, 9),
          const Radius.circular(3),
        ),
      ),
      ColoresNpc.camisa,
    );

    // El brazo de enfrente: arriba saludando o balanceándose al caminar.
    final hombro = const Offset(19.5, 21.5);
    final mano = saludando ? const Offset(26, 13) : Offset(21.5 - paso * 2, 28);
    _extremidad(canvas, hombro, mano, ColoresNpc.piel);
    canvas
      ..drawCircle(mano, 1.6, _relleno(ColoresNpc.piel))
      ..drawCircle(mano, 1.6, _linea);

    // Gorro con orejitas y la cara.
    for (final oreja in const [Offset(11, 4), Offset(21, 4)]) {
      _figura(
        canvas,
        Path()..addOval(Rect.fromCircle(center: oreja, radius: 2.4)),
        ColoresNpc.gorro,
      );
    }
    _figura(
      canvas,
      Path()..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(7.5, 3.5, 17, 17),
          const Radius.circular(7),
        ),
      ),
      ColoresNpc.gorro,
    );
    _figura(
      canvas,
      Path()..addOval(const Rect.fromLTWH(11, 8, 11.5, 10)),
      ColoresNpc.piel,
    );
    canvas
      ..drawCircle(const Offset(15, 12), 0.95, _relleno(ColoresNpc.contorno))
      ..drawCircle(const Offset(19.5, 12), 0.95, _relleno(ColoresNpc.contorno));
    // Sonrisa; abierta cuando saluda.
    if (saludando) {
      _figura(
        canvas,
        Path()..addArc(const Rect.fromLTWH(14.5, 12.5, 5.5, 4.5), 0, 3.1416),
        ColoresNpc.boca,
      );
    } else {
      canvas.drawArc(
        const Rect.fromLTWH(15, 12.5, 4.5, 3),
        0.2,
        2.7,
        false,
        _linea,
      );
    }
  }

  @override
  bool shouldRepaint(PintorNino anterior) =>
      anterior.paso != paso || anterior.saludando != saludando;
}

/// Un perrito amarillo de cuerpo redondito, ojos grandes y hocico claro.
/// Mira hacia la derecha; para que mire a la izquierda se voltea.
class PintorPerro extends CustomPainter {
  const PintorPerro({required this.paso, required this.saludando});

  final double paso;
  final bool saludando;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(
      size.width / tamanoPerro.width,
      size.height / tamanoPerro.height,
    );

    // Cola.
    canvas.drawPath(
      Path()
        ..moveTo(6, 19)
        ..quadraticBezierTo(0, 18, 2, 12),
      Paint()
        ..color = ColoresNpc.contorno
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      Path()
        ..moveTo(6, 19)
        ..quadraticBezierTo(0, 18, 2, 12),
      Paint()
        ..color = ColoresNpc.perro
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.7
        ..strokeCap = StrokeCap.round,
    );

    // Patitas.
    for (final (cadera, lado) in [(11.0, 1.0), (22.0, -1.0)]) {
      _extremidad(
        canvas,
        Offset(cadera, 24),
        Offset(cadera + paso * 2 * lado, 28.5),
        ColoresNpc.perro,
      );
    }

    // Cuerpo de frijolito.
    _figura(
      canvas,
      Path()..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(5, 4, 23, 22),
          const Radius.circular(10),
        ),
      ),
      ColoresNpc.perro,
    );

    // Bracito: arriba si saluda.
    final mano = saludando ? const Offset(31, 8) : Offset(27 - paso, 21);
    _extremidad(canvas, const Offset(25, 16), mano, ColoresNpc.perro);

    // Hocico, nariz y boca.
    _figura(
      canvas,
      Path()..addOval(const Rect.fromLTWH(17, 12.5, 10.5, 7)),
      ColoresNpc.hocico,
    );
    canvas.drawOval(
      const Rect.fromLTWH(20.5, 12.5, 4, 2.6),
      _relleno(ColoresNpc.contorno),
    );
    if (saludando) {
      _figura(
        canvas,
        Path()..addArc(const Rect.fromLTWH(19.5, 15, 5, 4), 0, 3.1416),
        ColoresNpc.boca,
      );
    }

    // Ojos grandes.
    for (final ojo in const [Offset(16.5, 9), Offset(24, 9)]) {
      canvas
        ..drawCircle(ojo, 3.3, _relleno(Colors.white))
        ..drawCircle(ojo, 3.3, _linea)
        ..drawCircle(
          ojo + const Offset(0.9, 0.3),
          1.3,
          _relleno(ColoresNpc.contorno),
        );
    }
  }

  @override
  bool shouldRepaint(PintorPerro anterior) =>
      anterior.paso != paso || anterior.saludando != saludando;
}
