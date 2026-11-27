import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:brilliant_mobile/datos_sala.dart';
import 'package:brilliant_mobile/decoraciones.dart';
import 'package:brilliant_mobile/etiqueta_elo.dart';
import 'package:brilliant_mobile/lluvia_monedas.dart';
import 'package:brilliant_mobile/pintores_npc.dart';

/// Al terminar la partida, cómo me fue en el ELO, con animación: si subió,
/// brotan monedas y el número sube contando; si bajó, un personajito triste
/// bajo su nubecita y el número baja; si quedó igual, no se muestra nada.
class CelebracionElo extends StatefulWidget {
  const CelebracionElo({super.key, required this.resultado});

  final ResultadoEloJugador resultado;

  /// Cuánto tarda el número en contar de antes a después.
  static const Duration duracionConteo = Duration(milliseconds: 1400);

  /// Cuánto tarda en saltar la etiqueta del cambio («+16»), después de contar.
  static const Duration duracionSalto = Duration(milliseconds: 350);

  @override
  State<CelebracionElo> createState() => _CelebracionEloState();
}

class _CelebracionEloState extends State<CelebracionElo>
    with SingleTickerProviderStateMixin {
  late final LluviaMonedas _monedas = LluviaMonedas(
    cantidad: LluviaMonedas.cantidadPara(widget.resultado.cambio),
  );
  late final Ticker _reloj = createTicker(_avanzar);
  Duration _anterior = Duration.zero;

  /// Segundos desde que empezó; con la animación apagada, ya terminó.
  double _tiempo = 0;
  bool _animada = false;

  double get _segundosConteo =>
      CelebracionElo.duracionConteo.inMilliseconds / 1000;
  double get _segundosSalto =>
      CelebracionElo.duracionSalto.inMilliseconds / 1000;
  double get _segundosTotales => _segundosConteo + _segundosSalto + 0.5;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final quieta =
        !Decoraciones.animadas ||
        (MediaQuery.maybeDisableAnimationsOf(context) ?? false);
    if (quieta) {
      // Sin animación se ve directo cómo quedó.
      _animada = false;
      _tiempo = _segundosTotales;
      if (_reloj.isActive) _reloj.stop();
    } else if (!_animada && _tiempo == 0) {
      _animada = true;
      _reloj.start();
    }
  }

  void _avanzar(Duration transcurrido) {
    final dt =
        (transcurrido - _anterior).inMicroseconds /
        Duration.microsecondsPerSecond;
    _anterior = transcurrido;
    setState(() {
      _tiempo += dt;
      _monedas.avanzar(dt);
    });
    if (_tiempo >= _segundosTotales && _monedas.terminada) _reloj.stop();
  }

  @override
  void dispose() {
    _reloj.dispose();
    super.dispose();
  }

  /// De 0 a 1 mientras cuenta, con una curva que frena al final.
  double get _avanceConteo =>
      Curves.easeOutCubic.transform((_tiempo / _segundosConteo).clamp(0, 1));

  /// De 0 a 1 el salto de la etiqueta del cambio, al terminar de contar.
  double get _avanceSalto =>
      ((_tiempo - _segundosConteo) / _segundosSalto).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final resultado = widget.resultado;
    if (resultado.cambio == 0) return const SizedBox.shrink();
    final subio = resultado.cambio > 0;
    final valor = eloContado(resultado.antes, resultado.despues, _avanceConteo);

    return Container(
      key: Key(subio ? 'elo-subio' : 'elo-bajo'),
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: subio
              ? const [Color(0xFFFFF6CC), Color(0xFFFFE07A)]
              : const [Color(0xFFEEF2F7), Color(0xFFD3DEEA)],
        ),
        border: Border.all(
          color: subio ? const Color(0xFFE5B83B) : const Color(0xFFB0C1D4),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            height: 56,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                if (subio)
                  const CustomPaint(
                    size: Size.square(38),
                    painter: PintorMoneda(),
                  )
                else
                  _MonitoTriste(tiempo: _tiempo),
                if (subio && _animada)
                  // Las monedas brotan del centro de la moneda grande.
                  Positioned(
                    left: 26,
                    top: 28,
                    child: IgnorePointer(
                      child: CustomPaint(
                        key: const Key('monedas'),
                        painter: PintorLluviaMonedas(
                          _monedas.monedas,
                          tiempo: _tiempo,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subio ? '¡Ganaste ELO!' : 'Perdiste ELO',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: subio
                        ? const Color(0xFF6B4E00)
                        : const Color(0xFF41566E),
                  ),
                ),
                const SizedBox(height: 2),
                Text.rich(
                  key: const Key('elo-contador'),
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: 'ELO ',
                        style: TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                      TextSpan(
                        text: '$valor',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF2A2620),
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // El cambio salta al terminar de contar.
          Transform.scale(
            scale: Curves.easeOutBack.transform(_avanceSalto),
            child: Container(
              key: const Key('elo-cambio-animado'),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Color(0x22000000), blurRadius: 4),
                ],
              ),
              child: CambioElo(cambio: resultado.cambio, tamanoLetra: 18),
            ),
          ),
        ],
      ),
    );
  }
}

/// El personajito del menú, triste, bajo una nubecita que llueve.
class _MonitoTriste extends StatelessWidget {
  const _MonitoTriste({required this.tiempo});

  final double tiempo;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('monito-triste'),
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: const Size(30, 14),
          painter: PintorNubeTriste(tiempo: tiempo),
        ),
        // Cabizbajo: un poquito inclinado.
        Transform.rotate(
          angle: 0.08,
          child: CustomPaint(
            size: tamanoNino,
            painter: const PintorNino(paso: 0, saludando: false, triste: true),
          ),
        ),
      ],
    );
  }
}

/// Dibuja una moneda dorada en [centro]; [ancho] de 0 a 1 la angosta para que
/// parezca girar.
void pintarMoneda(Canvas canvas, Offset centro, double radio, double ancho) {
  final caja = Rect.fromCenter(
    center: centro,
    width: radio * 2 * math.max(ancho, 0.12),
    height: radio * 2,
  );
  canvas
    ..drawOval(
      caja,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF1A8), Color(0xFFF5C330), Color(0xFFD9971A)],
        ).createShader(caja),
    )
    ..drawOval(
      caja,
      Paint()
        ..color = const Color(0xFFB07812)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radio * 0.14,
    )
    ..drawOval(
      caja.deflate(radio * 0.3),
      Paint()
        ..color = const Color(0x99B07812)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radio * 0.08,
    );
  // Un brillo.
  if (ancho > 0.4) {
    canvas.drawLine(
      centro + Offset(-radio * 0.25 * ancho, -radio * 0.5),
      centro + Offset(-radio * 0.45 * ancho, -radio * 0.1),
      Paint()
        ..color = const Color(0xCCFFFFFF)
        ..strokeWidth = radio * 0.14
        ..strokeCap = StrokeCap.round,
    );
  }
}

/// La moneda grande de la tarjeta.
class PintorMoneda extends CustomPainter {
  const PintorMoneda();

  @override
  void paint(Canvas canvas, Size size) => pintarMoneda(
    canvas,
    size.center(Offset.zero),
    math.min(size.width, size.height) / 2,
    1,
  );

  @override
  bool shouldRepaint(PintorMoneda anterior) => false;
}

/// Las monedas que saltan, cada una en su lugar y con su giro.
class PintorLluviaMonedas extends CustomPainter {
  PintorLluviaMonedas(this.monedas, {required this.tiempo});

  final List<Moneda> monedas;

  /// Cambia en cada cuadro para que se vuelva a pintar.
  final double tiempo;

  static const double radio = 7;

  @override
  void paint(Canvas canvas, Size size) {
    for (final moneda in monedas) {
      if (!moneda.enElAire) continue;
      pintarMoneda(
        canvas,
        Offset(moneda.x, moneda.y),
        radio,
        moneda.anchoVisible,
      );
    }
  }

  @override
  bool shouldRepaint(PintorLluviaMonedas anterior) => anterior.tiempo != tiempo;
}

/// Una nubecita gris con gotas que caen.
class PintorNubeTriste extends CustomPainter {
  const PintorNubeTriste({required this.tiempo});

  final double tiempo;

  /// Dónde va cada gota (0 arriba, 1 abajo) según el tiempo.
  static double alturaGota(double tiempo, int indice) =>
      (tiempo * 1.6 + indice / 3) % 1;

  @override
  void paint(Canvas canvas, Size size) {
    final gris = Paint()..color = const Color(0xFF9AA8B8);
    canvas
      ..drawCircle(Offset(size.width * 0.3, size.height * 0.45), 5, gris)
      ..drawCircle(Offset(size.width * 0.55, size.height * 0.35), 6.5, gris)
      ..drawCircle(Offset(size.width * 0.75, size.height * 0.5), 4.5, gris)
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            size.width * 0.18,
            size.height * 0.45,
            size.width * 0.66,
            5,
          ),
          const Radius.circular(3),
        ),
        gris,
      );
    final gota = Paint()
      ..color = ColoresNpc.lagrima
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final x = size.width * (0.32 + i * 0.2);
      final y = size.height * 0.8 + alturaGota(tiempo, i) * 8;
      canvas.drawLine(Offset(x, y), Offset(x - 0.6, y + 2.5), gota);
    }
  }

  @override
  bool shouldRepaint(PintorNubeTriste anterior) => anterior.tiempo != tiempo;
}
