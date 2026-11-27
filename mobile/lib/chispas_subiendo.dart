import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:brilliant_mobile/chispas.dart';
import 'package:brilliant_mobile/decoraciones.dart';

/// Brasitas de fuego subiendo, de adorno. Los toques pasan a través de ellas.
/// Con «reducir movimiento» (o en las pruebas) se quedan quietas en su lugar.
class ChispasSubiendo extends StatefulWidget {
  const ChispasSubiendo({super.key, this.cantidad = 30});

  final int cantidad;

  @override
  State<ChispasSubiendo> createState() => _ChispasSubiendoState();
}

class _ChispasSubiendoState extends State<ChispasSubiendo>
    with SingleTickerProviderStateMixin {
  late final Chispas _chispas = Chispas(cantidad: widget.cantidad);
  late final Ticker _reloj = createTicker(_avanzar);
  Duration _anterior = Duration.zero;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final quietas =
        !Decoraciones.animadas ||
        (MediaQuery.maybeDisableAnimationsOf(context) ?? false);
    if (quietas && _reloj.isActive) {
      _reloj.stop();
    } else if (!quietas && !_reloj.isActive) {
      _anterior = Duration.zero;
      _reloj.start();
    }
  }

  void _avanzar(Duration transcurrido) {
    final segundos =
        (transcurrido - _anterior).inMicroseconds /
        Duration.microsecondsPerSecond;
    _anterior = transcurrido;
    setState(() => _chispas.avanzar(segundos));
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
          key: const Key('brasas'),
          size: Size.infinite,
          painter: PintorChispas(_chispas.chispas, version: _anterior),
        ),
      ),
    );
  }
}

/// Dibuja cada brasa con su resplandor: amarilla al salir, naranja a media
/// altura y roja arriba, titilando.
class PintorChispas extends CustomPainter {
  PintorChispas(this.chispas, {this.version = Duration.zero});

  final List<Chispa> chispas;

  /// Cambia en cada cuadro para que se vuelva a pintar.
  final Duration version;

  static const Color caliente = Color(0xFFFFE27A);
  static const Color tibia = Color(0xFFFF9A2E);
  static const Color fria = Color(0xFFE0381C);

  /// El color de una brasa según qué tanto se ha enfriado (0 a 1).
  static Color colorPara(double enfriamiento) => enfriamiento < 0.5
      ? Color.lerp(caliente, tibia, enfriamiento * 2)!
      : Color.lerp(tibia, fria, (enfriamiento - 0.5) * 2)!;

  @override
  void paint(Canvas canvas, Size size) {
    for (final chispa in chispas) {
      final centro = Offset(
        chispa.xVisible * size.width,
        chispa.y * size.height,
      );
      final color = colorPara(chispa.enfriamiento);
      final brillo = chispa.brillo;
      canvas
        ..drawCircle(
          centro,
          chispa.tamano * 2.2,
          Paint()
            ..color = color.withValues(alpha: 0.28 * brillo)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        )
        ..drawCircle(
          centro,
          chispa.tamano / 2,
          Paint()..color = color.withValues(alpha: 0.95 * brillo),
        );
    }
  }

  @override
  bool shouldRepaint(PintorChispas anterior) =>
      anterior.version != version || anterior.chispas != chispas;
}
