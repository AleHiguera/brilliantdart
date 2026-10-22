import 'package:flutter/material.dart';
import 'package:brilliantdart/historial_dados.dart';
import 'package:brilliant_mobile/colores_zonas.dart';

class HistorialDadosView extends StatelessWidget {
  const HistorialDadosView({
    super.key,
    required this.historial,
    this.maxAlturaFilas = 84,
  });

  final HistorialDados historial;
  final double maxAlturaFilas;

  @override
  Widget build(BuildContext context) {
    // El lanzamiento más reciente va primero.
    final lanzamientos = historial.lanzamientos.reversed.toList();

    return Container(
      key: const Key('dice-history'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: decoracionTarjeta(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EncabezadoTarjeta(
            icono: Icons.history,
            titulo: 'Historial de dados',
            extremo: lanzamientos.isEmpty
                ? null
                : Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: colorBordeTarjeta),
                    ),
                    child: Text(
                      '${lanzamientos.length}',
                      key: const Key('dice-history-count'),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 6),
          if (lanzamientos.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(Icons.casino_outlined, size: 18, color: Colors.black38),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Sin lanzamientos',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ),
                ],
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxAlturaFilas),
              child: ListView.separated(
                key: const Key('dice-history-list'),
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: lanzamientos.length,
                separatorBuilder: (context, index) => const SizedBox(height: 4),
                itemBuilder: (context, index) => _FilaLanzamiento(
                  lanzamiento: lanzamientos[index],
                  esUltimo: index == 0,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilaLanzamiento extends StatelessWidget {
  const _FilaLanzamiento({required this.lanzamiento, required this.esUltimo});

  final RegistroLanzamiento lanzamiento;
  final bool esUltimo;

  @override
  Widget build(BuildContext context) {
    final numero = lanzamiento.numeroLanzamiento;

    return Semantics(
      label:
          'Lanzamiento $numero, dados ${lanzamiento.resultadoDado1} y '
          '${lanzamiento.resultadoDado2}, '
          '${lanzamiento.accionRealizada ?? 'acción pendiente'}',
      child: Container(
        key: Key('dice-history-row-$numero'),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: esUltimo ? Colors.black : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Wrap(
          spacing: 6,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: esUltimo ? Colors.black : colorBordeTarjeta,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$numero',
                    key: Key('dice-history-number-$numero'),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: esUltimo ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                DadoMini(
                  key: Key('dice-history-die1-$numero'),
                  valor: lanzamiento.resultadoDado1,
                ),
                const SizedBox(width: 3),
                DadoMini(
                  key: Key('dice-history-die2-$numero'),
                  valor: lanzamiento.resultadoDado2,
                ),
              ],
            ),
            _EtiquetaAccion(
              key: Key('dice-history-action-$numero'),
              accion: lanzamiento.accionRealizada,
            ),
          ],
        ),
      ),
    );
  }
}

/// Dado pequeño dibujado con puntos, igual que los dados grandes del panel.
class DadoMini extends StatelessWidget {
  const DadoMini({super.key, required this.valor, this.tamano = 20});

  final int valor;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Dado $valor',
      child: Container(
        width: tamano,
        height: tamano,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(tamano / 4),
          border: Border.all(
            color: const Color(0xFF252525),
            width: tamano < 30 ? 1.2 : 1.6,
          ),
        ),
        child: CustomPaint(painter: _PuntosDadoPainter(valor)),
      ),
    );
  }
}

class _PuntosDadoPainter extends CustomPainter {
  _PuntosDadoPainter(this.valor);

  final int valor;

  // Posiciones en una cuadrícula de 3x3, como en _CaraDado del panel.
  static const Map<int, List<int>> _puntos = {
    1: [4],
    2: [0, 8],
    3: [0, 4, 8],
    4: [0, 2, 6, 8],
    5: [0, 2, 4, 6, 8],
    6: [0, 2, 3, 5, 6, 8],
  };

  @override
  void paint(Canvas canvas, Size size) {
    final pintura = Paint()..color = const Color(0xFF252525);
    final celda = size.width / 3;
    for (final indice in _puntos[valor] ?? const <int>[]) {
      canvas.drawCircle(
        Offset(
          celda * (indice % 3) + celda / 2,
          celda * (indice ~/ 3) + celda / 2,
        ),
        size.width * 0.09,
        pintura,
      );
    }
  }

  @override
  bool shouldRepaint(_PuntosDadoPainter oldDelegate) =>
      valor != oldDelegate.valor;
}

class _EtiquetaAccion extends StatelessWidget {
  const _EtiquetaAccion({super.key, required this.accion});

  final String? accion;

  @override
  Widget build(BuildContext context) {
    final (texto, fondo, color, icono) = switch (accion) {
      null => (
        'Pendiente',
        const Color(0xFFFFF4CC),
        const Color(0xFF7A5C00),
        Icons.hourglass_empty,
      ),
      'Movimiento inválido' => (
        accion!,
        const Color(0xFFFDE3E1),
        const Color(0xFFB3261E),
        Icons.block,
      ),
      'Turno pasado' => (
        accion!,
        colorBordeTarjeta,
        Colors.black87,
        Icons.skip_next,
      ),
      _ => (
        accion!,
        const Color(0xFFE2F4E3),
        const Color(0xFF1E6B23),
        Icons.check,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 12, color: color),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              texto,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
