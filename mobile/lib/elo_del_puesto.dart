import 'package:flutter/material.dart';
import 'package:brilliant_mobile/datos_sala.dart';
import 'package:brilliant_mobile/etiqueta_elo.dart';

/// La línea de ELO de un jugador en la tabla final: con cuánto llegó, en
/// cuánto quedó y cuánto subió o bajó. Por ejemplo «ELO 1000 → 1017  +17».
class EloDelPuesto extends StatelessWidget {
  const EloDelPuesto({
    super.key,
    required this.jugador,
    required this.resultado,
    this.soyYo = false,
  });

  final String jugador;
  final ResultadoEloJugador resultado;
  final bool soyYo;

  @override
  Widget build(BuildContext context) {
    final peso = soyYo ? FontWeight.bold : FontWeight.w600;
    // En un celular angosto se achica en vez de desbordarse.
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'ELO ',
            style: TextStyle(fontSize: 11, color: Colors.black54),
          ),
          Text(
            '${resultado.antes} → ${resultado.despues}',
            key: Key('elo-antes-despues-$jugador'),
            style: TextStyle(fontSize: 11, fontWeight: peso),
          ),
          const SizedBox(width: 6),
          CambioElo(
            key: Key('elo-cambio-$jugador'),
            cambio: resultado.cambio,
            tamanoLetra: 12,
          ),
        ],
      ),
    );
  }
}
