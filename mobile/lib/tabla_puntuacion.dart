import 'package:flutter/material.dart';
import 'package:brilliantdart/tablero.dart';
import 'package:brilliantdart/tipoo.dart';

class TablaPuntuacion extends StatelessWidget {
  const TablaPuntuacion({super.key, required this.tablero});

  final Tablero tablero;

  static const Map<TipoZona, String> _nombres = {
    TipoZona.morado: 'Morada',
    TipoZona.amarillo: 'Amarilla',
    TipoZona.verde: 'Verde',
    TipoZona.azul: 'Azul',
    TipoZona.rojo: 'Roja',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('score-table'),
      width: double.infinity,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        border: Border.all(color: const Color(0xFFBDBDBD)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Puntuación',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          const Row(
            children: [
              Expanded(child: Text('Zona', style: TextStyle(fontSize: 11))),
              SizedBox(
                width: 48,
                child: Text('Hechas', textAlign: TextAlign.center, style: TextStyle(fontSize: 10)),
              ),
              SizedBox(
                width: 34,
                child: Text('Pts', textAlign: TextAlign.right, style: TextStyle(fontSize: 10)),
              ),
            ],
          ),
          const Divider(height: 2),
          for (final tipo in TipoZona.values)
            Row(
              key: Key('score-row-${tipo.name}'),
              children: [
                Expanded(
                  child: Text(
                    _nombres[tipo]!,
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
                SizedBox(
                  width: 48,
                  child: Text(
                    '${tablero.zonasCompletadasPorTipo(tipo)}/'
                    '${tablero.regiones.where((zona) => zona.tipo.tipo == tipo).length}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
                SizedBox(
                  width: 34,
                  child: Text(
                    '${tablero.puntuacionPorTipo(tipo)}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              ],
            ),
          const Divider(height: 3),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Total',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                '${tablero.puntuacionTotal} pts',
                key: const Key('score-total'),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
