import 'package:flutter/material.dart';
import 'package:brilliantdart/clasificacion.dart';
import 'package:brilliantdart/mapa.dart';
import 'package:brilliantdart/tablero_texto.dart';
import 'package:brilliant_mobile/colores_zonas.dart';
import 'package:brilliant_mobile/tabla_puntos_partida.dart';

/// Al terminar la partida, el tablero de cada jugador tal como quedó, el
/// propio incluido. Van en el orden de la clasificación; quien abandonó sin
/// puntos va al final.
class TablerosFinales extends StatelessWidget {
  const TablerosFinales({
    super.key,
    required this.mapa,
    required this.tableros,
    required this.puestos,
    required this.usuario,
  });

  final Mapa mapa;

  /// Jugador → su tablero (ver [TableroTexto]).
  final Map<String, String> tableros;
  final List<Puesto> puestos;
  final String? usuario;

  /// Cada tablero con lo que se dice debajo de su nombre, en orden.
  List<({String jugador, String detalle, bool gano})> get _enOrden {
    final conPuesto = {for (final puesto in puestos) puesto.jugador: puesto};
    String detalle(Puesto puesto) => puesto.salio
        ? 'Abandonó · ${puesto.puntos} pts'
        : '${ordinalDeLugar(puesto.lugar)} lugar · ${puesto.puntos} pts';
    return [
      for (final puesto in puestos)
        if (tableros.containsKey(puesto.jugador))
          (
            jugador: puesto.jugador,
            detalle: detalle(puesto),
            gano: puesto.lugar == 1 && !puesto.salio,
          ),
      for (final jugador in tableros.keys)
        if (!conPuesto.containsKey(jugador))
          (jugador: jugador, detalle: 'Abandonó · 0 pts', gano: false),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final enOrden = _enOrden;
    if (enOrden.isEmpty) return const SizedBox.shrink();

    return Column(
      key: const Key('tableros-finales'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Así quedaron los tableros',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, limites) {
            const separacion = 10.0;
            final columnas = limites.maxWidth >= 520 ? 3 : 2;
            final ancho =
                (limites.maxWidth - separacion * (columnas - 1)) / columnas;
            return Wrap(
              spacing: separacion,
              runSpacing: separacion,
              children: [
                for (final tablero in enOrden)
                  SizedBox(
                    width: ancho,
                    child: _TarjetaTablero(
                      mapa: mapa,
                      jugador: tablero.jugador,
                      detalle: tablero.detalle,
                      gano: tablero.gano,
                      soyYo: tablero.jugador == usuario,
                      numeros: TableroTexto.leer(tableros[tablero.jugador]!)!,
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _TarjetaTablero extends StatelessWidget {
  const _TarjetaTablero({
    required this.mapa,
    required this.jugador,
    required this.detalle,
    required this.gano,
    required this.soyYo,
    required this.numeros,
  });

  final Mapa mapa;
  final String jugador;
  final String detalle;
  final bool gano;
  final bool soyYo;
  final List<int?> numeros;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: Key('tablero-final-$jugador'),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: gano ? const Color(0xFFE0B100) : colorBordeTarjeta,
          width: gano ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (gano)
                const Padding(
                  padding: EdgeInsets.only(right: 3),
                  child: Icon(
                    Icons.emoji_events,
                    size: 15,
                    color: Color(0xFF7A5C00),
                  ),
                ),
              Expanded(
                child: Text(
                  soyYo ? '@$jugador (tú)' : '@$jugador',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Text(
            detalle,
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
          const SizedBox(height: 4),
          TableroMini(mapa: mapa, numeros: numeros),
        ],
      ),
    );
  }
}

/// Un tablero pequeño: los colores del mapa con los números puestos.
class TableroMini extends StatelessWidget {
  const TableroMini({super.key, required this.mapa, required this.numeros});

  final Mapa mapa;

  /// Celda por celda, fila por fila; null si está vacía.
  final List<int?> numeros;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Column(
          children: [
            for (var fila = 0; fila < TableroTexto.lado; fila++)
              Expanded(
                child: Row(
                  children: [
                    for (
                      var columna = 0;
                      columna < TableroTexto.lado;
                      columna++
                    )
                      Expanded(child: _celda(fila, columna)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _celda(int fila, int columna) {
    final color = coloresZonas[mapa.tipoEn(fila, columna)]!;
    final numero = numeros[fila * TableroTexto.lado + columna];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: Colors.black26, width: 0.5),
      ),
      child: numero == null
          ? null
          : Center(
              child: FittedBox(
                child: Padding(
                  padding: const EdgeInsets.all(1),
                  child: Text(
                    '$numero',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color.computeLuminance() > 0.5
                          ? Colors.black
                          : Colors.white,
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
