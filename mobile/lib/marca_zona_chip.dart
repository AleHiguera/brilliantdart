import 'package:flutter/material.dart';

/// La marca de una zona (R1, V2, N↑). En el tablero va oscura en la esquina
/// de cada pedazo, para leerse sobre cualquier color; en la lista de reglas
/// lleva el [color] de su zona.
class MarcaZonaChip extends StatelessWidget {
  const MarcaZonaChip({
    super.key,
    required this.texto,
    this.color,
    this.tamanoLetra = 9,
  });

  final String texto;
  final Color? color;
  final double tamanoLetra;

  @override
  Widget build(BuildContext context) {
    final fondo = color ?? const Color(0xCC1A1A1A);
    final letra = ThemeData.estimateBrightnessForColor(fondo) == Brightness.dark
        ? Colors.white
        : Colors.black87;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(4),
        border: color == null ? null : Border.all(color: Colors.black26),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: letra,
          fontSize: tamanoLetra,
          fontWeight: FontWeight.bold,
          height: 1.1,
        ),
      ),
    );
  }
}
