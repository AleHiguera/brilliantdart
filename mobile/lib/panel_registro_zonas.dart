import 'package:flutter/material.dart';
import 'package:brilliantdart/nombres_zonas.dart';
import 'package:brilliantdart/registro_zonas.dart';
import 'package:brilliant_mobile/colores_zonas.dart';
import 'package:brilliant_mobile/tabla_puntos_partida.dart';

/// Quién llenó cada zona en la partida, en qué ronda, qué lugar ganó y cuántos
/// puntos le dio. Lo más reciente va arriba.
class PanelRegistroZonas extends StatelessWidget {
  const PanelRegistroZonas({
    super.key,
    required this.entradas,
    required this.nombres,
    required this.usuario,
    this.maxAltura = 220,
  });

  final List<ZonaLograda> entradas;
  final NombresZonas nombres;
  final String? usuario;
  final double maxAltura;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('registro-zonas'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: decoracionTarjeta(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const EncabezadoTarjeta(
            icono: Icons.emoji_events_outlined,
            titulo: 'Zonas completadas',
          ),
          const SizedBox(height: 6),
          if (entradas.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Text(
                'Nadie ha llenado una zona todavía.',
                key: Key('registro-zonas-vacio'),
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxAltura),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: entradas.length,
                separatorBuilder: (context, index) => const SizedBox(height: 4),
                itemBuilder: (context, index) => _FilaZona(
                  entrada: entradas[index],
                  nombre: nombres.de(entradas[index].zona),
                  soyYo: entradas[index].jugador == usuario,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilaZona extends StatelessWidget {
  _FilaZona({required this.entrada, required this.nombre, required this.soyYo})
    : super(key: Key('registro-${entrada.zona}-${entrada.jugador}'));

  final ZonaLograda entrada;
  final String nombre;
  final bool soyYo;

  String get _lugar => entrada.puntos > 0
      ? '${ordinalDeLugar(entrada.lugar)} · ${entrada.puntos} pts'
      : '${ordinalDeLugar(entrada.lugar)} · sin puntos';

  @override
  Widget build(BuildContext context) {
    final jugador = soyYo ? '@${entrada.jugador} (tú)' : '@${entrada.jugador}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: coloresZonas[entrada.tipo],
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: Colors.black26),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$jugador llenó $nombre',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: soyYo ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                // Debajo, para que quepa también en una columna angosta.
                Wrap(
                  spacing: 6,
                  children: [
                    Text(
                      'Ronda ${entrada.ronda}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                    Text(
                      _lugar,
                      key: Key(
                        'registro-lugar-${entrada.zona}-${entrada.jugador}',
                      ),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
