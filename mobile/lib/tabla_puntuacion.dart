import 'package:flutter/material.dart';
import 'package:brilliantdart/tablero.dart';
import 'package:brilliantdart/tipoo.dart';
import 'package:brilliant_mobile/colores_zonas.dart';

class TablaPuntuacion extends StatelessWidget {
  const TablaPuntuacion({super.key, required this.tablero});

  final Tablero tablero;

  static const Map<TipoZona, String> _nombres = {
    TipoZona.morado: 'Morada',
    TipoZona.amarillo: 'Amarilla',
    TipoZona.verde: 'Verde',
    TipoZona.azul: 'Azul',
    TipoZona.rojo: 'Roja',
    TipoZona.gris: 'Gris',
  };

  @override
  Widget build(BuildContext context) {
    final maximo = tablero.puntuacionMaxima;
    final total = tablero.puntuacionTotal;
    // Solo los colores que tiene este tablero (el Mapa 1 no tiene gris).
    final colores = TipoZona.values.where(
      (tipo) => tablero.regiones.any((zona) => zona.tipo.tipo == tipo),
    );

    return Container(
      key: const Key('score-table'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: decoracionTarjeta(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EncabezadoTarjeta(
            icono: Icons.emoji_events_outlined,
            titulo: 'Puntuación',
            extremo: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$total pts',
                key: const Key('score-total'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: maximo == 0 ? 0 : total / maximo),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (context, avance, _) => LinearProgressIndicator(
                key: const Key('score-progress'),
                value: avance,
                minHeight: 5,
                backgroundColor: colorBordeTarjeta,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 6),
          for (final tipo in colores) _filaColor(tipo),
        ],
      ),
    );
  }

  Widget _filaColor(TipoZona tipo) {
    final zonas = tablero.regiones
        .where((zona) => zona.tipo.tipo == tipo)
        .toList(growable: false);
    final hechas = tablero.zonasCompletadasPorTipo(tipo);
    final puntos = tablero.puntuacionPorTipo(tipo);
    final color = coloresZonas[tipo]!;
    final completo = zonas.isNotEmpty && hechas == zonas.length;

    return AnimatedContainer(
      key: Key('score-row-${tipo.name}'),
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(top: 3),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: completo ? color.withValues(alpha: 0.16) : Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: Colors.black26, width: 0.5),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _nombres[tipo]!,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11),
            ),
          ),
          for (var indice = 0; indice < zonas.length; indice++)
            Padding(
              padding: const EdgeInsets.only(left: 3),
              child: _MarcaZona(color: color, hecha: indice < hechas),
            ),
          SizedBox(
            width: 30,
            child: Text(
              '$hechas/${zonas.length}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: Colors.black54),
            ),
          ),
          SizedBox(
            width: 24,
            child: Text(
              '$puntos',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: puntos > 0 ? Colors.black : Colors.black38,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Circulito por zona: relleno con el color cuando la zona está completa.
class _MarcaZona extends StatelessWidget {
  const _MarcaZona({required this.color, required this.hecha});

  final Color color;
  final bool hecha;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: hecha ? color : Colors.transparent,
        border: Border.all(color: hecha ? Colors.black45 : color, width: 1.2),
      ),
    );
  }
}
