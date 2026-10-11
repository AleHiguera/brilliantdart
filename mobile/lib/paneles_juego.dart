import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:brilliantdart/validador_anclas.dart';
import 'package:brilliant_mobile/colores_zonas.dart';
import 'package:brilliant_mobile/historial_dados_view.dart';

/// Tarjeta de preparación: rueda de progreso, números usados y Comenzar.
class PanelPreparacion extends StatelessWidget {
  const PanelPreparacion({
    super.key,
    required this.valoresColocados,
    required this.puedeIniciar,
    required this.onComenzar,
  });

  final Set<int> valoresColocados;
  final bool puedeIniciar;
  final VoidCallback onComenzar;

  @override
  Widget build(BuildContext context) {
    final cantidad = valoresColocados.length;

    return Container(
      key: const Key('setup-panel'),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: decoracionTarjeta(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              RuedaProgresoIniciales(cantidad: cantidad),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Coloca los 6 números iniciales para comenzar',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Text(
                        puedeIniciar
                            ? '¡Listo! Ya puedes comenzar la partida.'
                            : 'Toca las celdas con + y usa cada número una vez.',
                        key: ValueKey(puedeIniciar),
                        style: TextStyle(
                          fontSize: 12,
                          color: puedeIniciar
                              ? const Color(0xFF1E6B23)
                              : Colors.black54,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 5,
                      runSpacing: 4,
                      children: [
                        for (var numero = 1; numero <= 6; numero++)
                          _NumeroInicial(
                            numero: numero,
                            colocado: valoresColocados.contains(numero),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedScale(
            scale: puedeIniciar ? 1 : 0.97,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutBack,
            child: ElevatedButton(
              style: estiloBotonElevadoPrincipal(),
              onPressed: puedeIniciar ? onComenzar : null,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_arrow_rounded, size: 20),
                  SizedBox(width: 6),
                  Text('Comenzar'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dado de la fila "números usados": se enciende cuando ya está colocado.
class _NumeroInicial extends StatelessWidget {
  const _NumeroInicial({required this.numero, required this.colocado});

  final int numero;
  final bool colocado;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      key: Key('setup-number-$numero'),
      opacity: colocado ? 1 : 0.28,
      duration: const Duration(milliseconds: 250),
      child: AnimatedScale(
        scale: colocado ? 1 : 0.88,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutBack,
        child: DadoMini(valor: numero, tamano: 22),
      ),
    );
  }
}

/// Rueda de pastel en forma de dona que se llena con animación.
class RuedaProgresoIniciales extends StatelessWidget {
  const RuedaProgresoIniciales({super.key, required this.cantidad});

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
                size: const Size.square(64),
                painter: _RuedaProgresoPainter(valor),
              ),
            ),
            Text(
              '$cantidad/6',
              key: const Key('initial-progress-count'),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _RuedaProgresoPainter extends CustomPainter {
  _RuedaProgresoPainter(this.avance);

  /// Número de sectores llenos; puede tener decimales durante la animación.
  final double avance;

  static const List<Color> _colores = [
    Color(0xFFFFEB3B),
    Color(0xFF4CAF50),
    Color(0xFF2196F3),
    Color(0xFF9C27B0),
    Color(0xFFF44336),
    Color(0xFFFF9800),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final centro = size.center(Offset.zero);
    final radio = math.min(size.width, size.height) / 2 - 1;
    final limites = Rect.fromCircle(center: centro, radius: radio);
    const sector = math.pi / 3;

    for (var indice = 0; indice < 6; indice++) {
      final inicio = -math.pi / 2 + indice * sector;
      canvas.drawArc(
        limites,
        inicio,
        sector,
        true,
        Paint()..color = const Color(0xFFE6E6E2),
      );
      final lleno = (avance - indice).clamp(0.0, 1.0);
      if (lleno > 0) {
        canvas.drawArc(
          limites,
          inicio,
          sector * lleno,
          true,
          Paint()..color = _colores[indice],
        );
      }
    }

    final separador = Paint()
      ..color = Colors.white
      ..strokeWidth = 2;
    for (var indice = 0; indice < 6; indice++) {
      final angulo = -math.pi / 2 + indice * sector;
      canvas.drawLine(
        centro,
        centro + Offset(math.cos(angulo), math.sin(angulo)) * radio,
        separador,
      );
    }

    canvas.drawCircle(centro, radio * 0.58, Paint()..color = Colors.white);
    canvas.drawCircle(
      centro,
      radio,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_RuedaProgresoPainter oldDelegate) =>
      avance != oldDelegate.avance;
}

/// Diálogo para elegir el número de una celda inicial con caras de dado.
class SelectorValorInicial extends StatelessWidget {
  const SelectorValorInicial({
    super.key,
    required this.valorActual,
    required this.valoresColocados,
  });

  final int? valorActual;
  final Set<int> valoresColocados;

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
      contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Elige un número',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 2),
          Text(
            'Si ya está en otra celda inicial, se moverá aquí.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            for (var numero = 1; numero <= 6; numero++)
              _OpcionNumero(
                numero: numero,
                actual: numero == valorActual,
                enOtraCelda:
                    numero != valorActual && valoresColocados.contains(numero),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton.icon(
            key: const Key('clear-initial-value'),
            style: TextButton.styleFrom(foregroundColor: Colors.black87),
            onPressed: () => Navigator.pop(context, 0),
            icon: const Icon(Icons.backspace_outlined, size: 18),
            label: const Text('Vaciar celda'),
          ),
        ),
      ],
    );
  }
}

class _OpcionNumero extends StatelessWidget {
  const _OpcionNumero({
    required this.numero,
    required this.actual,
    required this.enOtraCelda,
  });

  final int numero;
  final bool actual;
  final bool enOtraCelda;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: actual ? Colors.black : colorTarjeta,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        key: Key('initial-value-$numero'),
        borderRadius: BorderRadius.circular(10),
        onTap: () => Navigator.pop(context, numero),
        child: Container(
          width: 72,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: actual ? Colors.black : colorBordeTarjeta,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DadoMini(valor: numero, tamano: 36),
              const SizedBox(height: 6),
              Text(
                '$numero',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: actual ? Colors.white : Colors.black,
                ),
              ),
              Text(
                actual
                    ? 'Actual'
                    : enOtraCelda
                    ? 'En uso'
                    : 'Libre',
                style: TextStyle(
                  fontSize: 10,
                  color: actual
                      ? Colors.white70
                      : enOtraCelda
                      ? const Color(0xFF7A5C00)
                      : Colors.black45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cabecera de la tarjeta del turno: qué hacer y número de turno.
class CabeceraTurno extends StatelessWidget {
  const CabeceraTurno({super.key, required this.turno});

  final int turno;

  @override
  Widget build(BuildContext context) {
    return EncabezadoTarjeta(
      icono: Icons.casino_outlined,
      titulo: 'Lanza los dados para continuar',
      extremo: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, animacion) =>
            ScaleTransition(scale: animacion, child: child),
        child: Container(
          key: ValueKey(turno),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'Turno $turno',
            key: const Key('turn-chip'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

/// Resumen del movimiento elegido antes de confirmarlo.
class ResumenMovimiento extends StatelessWidget {
  const ResumenMovimiento({
    super.key,
    required this.opcion,
    required this.movimiento,
    required this.onConfirmar,
  });

  final OpcionAncla opcion;
  final MovimientoAncla movimiento;
  final VoidCallback onConfirmar;

  @override
  Widget build(BuildContext context) {
    Widget dato(Widget icono, String texto) => Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(width: 22, child: Center(child: icono)),
          const SizedBox(width: 8),
          Expanded(child: Text(texto, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );

    return AsegurarVisible(
      child: Container(
        key: const Key('movement-summary'),
        width: double.infinity,
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.black, width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            dato(
              DadoMini(valor: opcion.ancla),
              'Ancla: ${opcion.ancla}',
            ),
            dato(
              DadoMini(valor: opcion.numeroAColocar),
              'Número a colocar: ${opcion.numeroAColocar}',
            ),
            const SizedBox(height: 4),
            FilledButton.icon(
              key: const Key('confirm-move-button'),
              style: estiloBotonPrincipal(),
              onPressed: onConfirmar,
              icon: const Icon(Icons.check),
              label: const Text('Confirmar movimiento'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta de fin de partida con el trofeo animado.
class PanelFinPartida extends StatelessWidget {
  const PanelFinPartida({
    super.key,
    required this.puntos,
    required this.onNuevaPartida,
  });

  final int puntos;
  final VoidCallback onNuevaPartida;

  @override
  Widget build(BuildContext context) {
    return AsegurarVisible(
      arriba: true,
      child: Container(
        key: const Key('game-finished-panel'),
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFF2D14B)),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF8D6), Colors.white],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 700),
              curve: Curves.elasticOut,
              builder: (context, escala, hijo) =>
                  Transform.scale(scale: escala, child: hijo),
              child: Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFEB3B),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.emoji_events, size: 34),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Fin de la partida',
              key: Key('game-finished-message'),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              'Has puntuado $puntos puntos',
              key: const Key('game-finished-score'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            if (puntos == 54) ...[
              const SizedBox(height: 4),
              const Text(
                '¡Puntuación perfecta! Completaste todas las zonas.',
                key: Key('perfect-score'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Color(0xFF7A5C00)),
              ),
            ],
            const SizedBox(height: 4),
            const Text(
              'El tablero está completo. Ya no puedes lanzar los dados.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const Key('new-game-button'),
              style: estiloBotonPrincipal(),
              onPressed: onNuevaPartida,
              icon: const Icon(Icons.replay),
              label: const Text('Jugar nueva partida'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Al aparecer, desplaza la zona con scroll para que este bloque se vea.
class AsegurarVisible extends StatefulWidget {
  const AsegurarVisible({super.key, required this.child, this.arriba = false});

  final Widget child;

  /// Si es verdadero, deja el bloque pegado arriba en lugar de abajo.
  final bool arriba;

  @override
  State<AsegurarVisible> createState() => _AsegurarVisibleState();
}

class _AsegurarVisibleState extends State<AsegurarVisible> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        alignmentPolicy: widget.arriba
            ? ScrollPositionAlignmentPolicy.explicit
            : ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
