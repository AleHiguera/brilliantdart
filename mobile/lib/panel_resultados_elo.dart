import 'package:flutter/material.dart';
import 'package:brilliant_mobile/colores_zonas.dart';
import 'package:brilliant_mobile/datos_sala.dart';
import 'package:brilliant_mobile/etiqueta_elo.dart';
import 'package:brilliant_mobile/tabla_puntos_partida.dart';

/// Al terminar la partida: el ELO de cada jugador antes de jugar, cuánto ganó
/// o perdió y el nuevo. Van por el lugar en que terminaron para el ELO; quien
/// abandonó va al final.
class PanelResultadosElo extends StatelessWidget {
  const PanelResultadosElo({
    super.key,
    required this.resultados,
    required this.usuario,
  });

  final Map<String, ResultadoEloJugador> resultados;
  final String? usuario;

  /// En orden de lugar; con el mismo lugar, en el orden en que llegaron.
  List<(String, ResultadoEloJugador)> get _enOrden {
    final filas =
        [
          for (final (indice, MapEntry(:key, :value))
              in resultados.entries.indexed)
            (indice, key, value),
        ]..sort((a, b) {
          final porLugar = a.$3.lugar.compareTo(b.$3.lugar);
          return porLugar != 0 ? porLugar : a.$1.compareTo(b.$1);
        });
    return [for (final (_, jugador, resultado) in filas) (jugador, resultado)];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('resultados-elo'),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: decoracionTarjeta(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const EncabezadoTarjeta(
            icono: Icons.trending_up,
            titulo: 'ELO de la partida',
          ),
          const SizedBox(height: 4),
          for (final (jugador, resultado) in _enOrden)
            _FilaElo(
              key: Key('elo-$jugador'),
              jugador: jugador,
              resultado: resultado,
              soyYo: jugador == usuario,
            ),
        ],
      ),
    );
  }
}

class _FilaElo extends StatelessWidget {
  const _FilaElo({
    super.key,
    required this.jugador,
    required this.resultado,
    required this.soyYo,
  });

  final String jugador;
  final ResultadoEloJugador resultado;
  final bool soyYo;

  @override
  Widget build(BuildContext context) {
    final peso = soyYo ? FontWeight.bold : FontWeight.normal;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              ordinalDeLugar(resultado.lugar),
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
          Expanded(
            child: Text(
              soyYo ? '@$jugador (tú)' : '@$jugador',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, fontWeight: peso),
            ),
          ),
          Text(
            '${resultado.antes} → ${resultado.despues}',
            key: Key('elo-antes-despues-$jugador'),
            style: TextStyle(fontSize: 12, fontWeight: peso),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 34,
            child: Align(
              alignment: Alignment.centerRight,
              child: CambioElo(
                key: Key('elo-cambio-$jugador'),
                cambio: resultado.cambio,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
