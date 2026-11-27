import 'package:flutter/material.dart';
import 'package:brilliantdart/leyenda_reglas.dart';
import 'package:brilliantdart/marcas_zonas.dart';
import 'package:brilliant_mobile/colores_zonas.dart';
import 'package:brilliant_mobile/marca_zona_chip.dart';

/// Las reglas del mapa junto al tablero: un cuadro del color de cada zona con
/// el signo de su regla adentro. Al dejar el dedo encima se lee la regla.
///
/// Debajo explica las marcas del tablero: qué pedazos cuentan como una sola
/// zona y qué zonas del mismo color puntúan aparte.
class PanelReglas extends StatelessWidget {
  const PanelReglas({
    super.key,
    required this.reglas,
    this.explicaciones = const [],
  });

  final List<ReglaVisible> reglas;
  final List<ExplicacionColor> explicaciones;

  static const String ayudaResaltar =
      'Mantén presionado un cuadro del tablero para ver toda su zona.';

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
      decoration: decoracionTarjeta(context),
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
          if (explicaciones.isNotEmpty)
            _ZonasDelMapa(explicaciones: explicaciones),
        ],
      ),
    );
  }
}

/// «Zonas del mapa»: plegable como el historial, para no ocupar espacio en
/// el celular. Un toque la abre y otro la cierra.
class _ZonasDelMapa extends StatefulWidget {
  const _ZonasDelMapa({required this.explicaciones});

  final List<ExplicacionColor> explicaciones;

  @override
  State<_ZonasDelMapa> createState() => _ZonasDelMapaState();
}

class _ZonasDelMapaState extends State<_ZonasDelMapa> {
  bool _abierta = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        InkWell(
          key: const Key('zonas-toggle'),
          onTap: () => setState(() => _abierta = !_abierta),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                const Text(
                  'Zonas del mapa',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 6),
                // Las marcas a la vista aunque esté cerrada.
                Expanded(
                  child: Wrap(
                    spacing: 3,
                    runSpacing: 3,
                    children: [
                      for (final explicacion in widget.explicaciones)
                        for (final marca in explicacion.marcas)
                          MarcaZonaChip(
                            texto: marca,
                            color: coloresZonas[explicacion.tipo],
                          ),
                    ],
                  ),
                ),
                Icon(
                  _abierta ? Icons.expand_less : Icons.expand_more,
                  key: const Key('zonas-chevron'),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (_abierta) ...[
          const SizedBox(height: 4),
          for (final explicacion in widget.explicaciones)
            _LineaZonas(explicacion: explicacion),
          const SizedBox(height: 2),
          const Text(
            PanelReglas.ayudaResaltar,
            key: Key('reglas-ayuda-resaltar'),
            style: TextStyle(fontSize: 11, color: Colors.black54),
          ),
        ],
      ],
    );
  }
}

/// Una línea de la lista: las marcas de un color y qué significan.
class _LineaZonas extends StatelessWidget {
  const _LineaZonas({required this.explicacion});

  final ExplicacionColor explicacion;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: Key('zonas-${explicacion.tipo.name}'),
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final marca in explicacion.marcas)
            Padding(
              padding: const EdgeInsets.only(right: 3),
              child: MarcaZonaChip(
                texto: marca,
                color: coloresZonas[explicacion.tipo],
                tamanoLetra: 11,
              ),
            ),
          const SizedBox(width: 3),
          Expanded(
            child: Text(
              explicacion.texto,
              style: const TextStyle(fontSize: 12, height: 1.25),
            ),
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
