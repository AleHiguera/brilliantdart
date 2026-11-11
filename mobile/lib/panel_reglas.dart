import 'package:flutter/material.dart';
import 'package:brilliantdart/leyenda_reglas.dart';
import 'package:brilliant_mobile/colores_zonas.dart';

/// Las reglas del mapa junto al tablero: un cuadro del color de cada zona con
/// el signo de su regla adentro. Al dejar el dedo encima se lee la regla.
class PanelReglas extends StatelessWidget {
  const PanelReglas({super.key, required this.reglas});

  final List<ReglaVisible> reglas;

  /// Lo que se lee al dejar el dedo encima; dice de qué zona es si la flecha
  /// la distingue.
  static String explicacion(ReglaVisible regla) => switch (regla.flecha) {
    '↑' => 'Zona de arriba: ${regla.regla}',
    '↓' => 'Zona de abajo: ${regla.regla}',
    _ => regla.regla,
  };

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
          // Todos en una fila: si no caben, los cuadros se achican un poco
          // (sin bajar de [CuadroRegla.ladoMinimo]).
          LayoutBuilder(
            builder: (context, limites) {
              final lado = CuadroRegla.ladoPara(
                limites.maxWidth,
                reglas.length,
              );
              return Wrap(
                spacing: CuadroRegla.separacion,
                runSpacing: CuadroRegla.separacion,
                children: [
                  for (final regla in reglas)
                    Tooltip(
                      message: explicacion(regla),
                      child: CuadroRegla(regla: regla, lado: lado),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class CuadroRegla extends StatelessWidget {
  CuadroRegla({required this.regla, this.lado = ladoMaximo})
    : super(key: Key('regla-${regla.tipo.name}-${regla.simbolo}'));

  static const double ladoMaximo = 34;
  static const double ladoMinimo = 24;
  static const double separacion = 6;

  /// El lado para que [cantidad] cuadros quepan en [ancho], entre el mínimo y
  /// el máximo.
  static double ladoPara(double ancho, int cantidad) {
    if (cantidad == 0 || !ancho.isFinite) return ladoMaximo;
    final justo = (ancho - separacion * (cantidad - 1)) / cantidad;
    return justo.clamp(ladoMinimo, ladoMaximo).floorToDouble();
  }

  final ReglaVisible regla;
  final double lado;

  @override
  Widget build(BuildContext context) {
    final color = coloresZonas[regla.tipo]!;
    final oscuro =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark;
    final estilo = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      height: 1.1,
      color: oscuro ? Colors.white : Colors.black87,
    );

    return Semantics(
      label: '${regla.tipo.name}: ${PanelReglas.explicacion(regla)}',
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (regla.flecha case final flecha?)
                Text(
                  flecha,
                  key: Key('flecha-${regla.tipo.name}-${regla.simbolo}'),
                  style: estilo.copyWith(fontSize: 11, height: 1),
                ),
              Text(regla.simbolo, style: estilo),
            ],
          ),
        ),
      ),
    );
  }
}
