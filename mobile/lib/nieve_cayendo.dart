import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:brilliant_mobile/decoraciones.dart';
import 'package:brilliant_mobile/nevada.dart';

/// Copitos de nieve cayendo, de adorno. Los toques pasan a través de ellos.
/// Con «reducir movimiento» (o en las pruebas) se quedan quietos en su lugar.
class NieveCayendo extends StatefulWidget {
  const NieveCayendo({super.key, this.cantidad = 36});

  final int cantidad;

  @override
  State<NieveCayendo> createState() => _NieveCayendoState();
}

class _NieveCayendoState extends State<NieveCayendo>
    with SingleTickerProviderStateMixin {
  late final Nevada _nevada = Nevada(cantidad: widget.cantidad);
  late final Ticker _reloj = createTicker(_avanzar);
  Duration _anterior = Duration.zero;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final quieta =
        !Decoraciones.animadas ||
        (MediaQuery.maybeDisableAnimationsOf(context) ?? false);
    if (quieta && _reloj.isActive) {
      _reloj.stop();
    } else if (!quieta && !_reloj.isActive) {
      _anterior = Duration.zero;
      _reloj.start();
    }
  }

  void _avanzar(Duration transcurrido) {
    final segundos =
        (transcurrido - _anterior).inMicroseconds /
        Duration.microsecondsPerSecond;
    _anterior = transcurrido;
    setState(() => _nevada.avanzar(segundos));
  }

  @override
  void dispose() {
    _reloj.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          key: const Key('nieve'),
          size: Size.infinite,
          painter: PintorNieve(_nevada.copos, version: _anterior),
        ),
      ),
    );
  }
}

/// Dibuja cada copo: los chiquitos como puntitos y los grandes como copitos
/// de 6 brazos, blancos con un borde azul muy suave para verse sobre el cielo
/// claro.
class PintorNieve extends CustomPainter {
  PintorNieve(this.copos, {this.version = Duration.zero});

  final List<CopoNieve> copos;

  /// Cambia en cada cuadro para que se vuelva a pintar.
  final Duration version;

  /// Desde este tamaño se dibujan con brazos.
  static const double tamanoConBrazos = 4;

  static final Paint _punto = Paint()..color = const Color(0xE6FFFFFF);
  static final Paint _brazo = Paint()
    ..color = const Color(0xF2FFFFFF)
    ..strokeWidth = 1.2
    ..strokeCap = StrokeCap.round;
  static final Paint _sombra = Paint()
    ..color = const Color(0x405B9BD5)
    ..strokeWidth = 2.6
    ..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size size) {
    for (final copo in copos) {
      final centro = Offset(copo.xVisible * size.width, copo.y * size.height);
      if (copo.tamano < tamanoConBrazos) {
        canvas.drawCircle(centro, copo.tamano / 2, _punto);
        continue;
      }
      final radio = copo.tamano;
      for (final pintura in [_sombra, _brazo]) {
        for (var i = 0; i < 3; i++) {
          final angulo = copo.giro + i * math.pi / 3;
          final brazo = Offset(math.cos(angulo), math.sin(angulo)) * radio;
          canvas.drawLine(centro - brazo, centro + brazo, pintura);
        }
      }
    }
  }

  @override
  bool shouldRepaint(PintorNieve anterior) =>
      anterior.version != version || anterior.copos != copos;
}
