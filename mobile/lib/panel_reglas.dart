import 'package:flutter/material.dart';
import 'package:brilliantdart/leyenda_reglas.dart';
import 'package:brilliant_mobile/colores_zonas.dart';

/// Las reglas del mapa junto al tablero: un cuadro del color de cada zona con
/// el signo de su regla adentro. Al dejar el dedo encima se lee la regla.
class PanelReglas extends StatelessWidget {
  const PanelReglas({super.key, required this.reglas});

  final List<ReglaVisible> reglas;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('reglas'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: decoracionTarjeta(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reglas',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final regla in reglas)
                Tooltip(
                  message: regla.regla,
                  child: CuadroRegla(regla: regla),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class CuadroRegla extends StatelessWidget {
  CuadroRegla({required this.regla})
    : super(key: Key('regla-${regla.tipo.name}-${regla.simbolo}'));

  static const double lado = 38;

  final ReglaVisible regla;

  @override
  Widget build(BuildContext context) {
    final color = coloresZonas[regla.tipo]!;
    final oscuro =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark;

    return Semantics(
      label: '${regla.tipo.name}: ${regla.regla}',
      child: Container(
        width: lado,
        height: lado,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.black26),
        ),
        child: FittedBox(
          child: Text(
            regla.simbolo,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: oscuro ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}
