import 'package:flutter/material.dart';
import 'package:brilliant_mobile/datos_salon_fama.dart';

/// El ELO del Salón de la Fama: el número con comas resaltado y «ELO» más
/// pequeño al lado. Se lee como «2,450 ELO».
class TextoEloSalon extends StatelessWidget {
  const TextoEloSalon({
    super.key,
    required this.elo,
    this.color = Colors.black87,
    this.tamano = 15,
  });

  final int elo;
  final Color color;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: eloConComas(elo),
            style: TextStyle(
              fontSize: tamano,
              fontWeight: FontWeight.w800,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          TextSpan(
            text: ' ELO',
            style: TextStyle(
              fontSize: tamano * 0.68,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: color.withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
