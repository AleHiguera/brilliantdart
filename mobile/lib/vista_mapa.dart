import 'package:flutter/material.dart';
import 'package:brilliantdart/mapa.dart';
import 'package:brilliant_mobile/colores_zonas.dart' as estilo;

/// Miniatura de los colores de un mapa, para reconocerlo antes de jugarlo.
class VistaPreviaMapa extends StatelessWidget {
  const VistaPreviaMapa({super.key, required this.mapa});

  final Mapa mapa;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
        ),
        itemCount: 49,
        itemBuilder: (context, index) => DecoratedBox(
          key: Key('map-preview-cell-$index'),
          decoration: BoxDecoration(
            color: estilo.coloresZonas[mapa.tipoEn(index ~/ 7, index % 7)],
            border: Border.all(color: Colors.black12, width: 0.3),
          ),
        ),
      ),
    );
  }
}
