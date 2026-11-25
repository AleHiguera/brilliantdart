import 'package:flutter/material.dart';

/// El ELO de un jugador junto a su nombre: «ELO 1016».
class EtiquetaElo extends StatelessWidget {
  const EtiquetaElo({super.key, required this.elo, this.tamanoLetra = 11});

  final int elo;
  final double tamanoLetra;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xFFF1EDFA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD5CBEF)),
      ),
      child: Text(
        'ELO $elo',
        style: TextStyle(
          fontSize: tamanoLetra,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF4A3A85),
        ),
      ),
    );
  }
}

/// Cuánto cambió el ELO: «+16» en verde, «−16» en rojo, «±0» en gris.
class CambioElo extends StatelessWidget {
  const CambioElo({super.key, required this.cambio, this.tamanoLetra = 13});

  final int cambio;
  final double tamanoLetra;

  static String texto(int cambio) => cambio > 0
      ? '+$cambio'
      : cambio < 0
      ? '−${-cambio}'
      : '±0';

  static Color color(int cambio) => cambio > 0
      ? const Color(0xFF1E6B23)
      : cambio < 0
      ? const Color(0xFFB3261E)
      : Colors.black54;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto(cambio),
      style: TextStyle(
        fontSize: tamanoLetra,
        fontWeight: FontWeight.bold,
        color: color(cambio),
      ),
    );
  }
}
