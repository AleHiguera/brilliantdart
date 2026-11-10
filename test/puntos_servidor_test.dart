// El servidor guarda una copia de los puntos de cada zona para elegir al
// ganador. Esta prueba genera esa copia desde los mapas: si falla, copia el
// texto nuevo en PuntosPorMapa.TABLA del servidor (RegistroClientes).

import 'package:brilliantdart/catalogo_mapas.dart';
import 'package:test/test.dart';

/// Lo mismo que PuntosPorMapa.TABLA en el servidor.
const String tablaDelServidor =
    '1:8,6,4|4,3,2|7,5,3|6,4,2|4,3,2|6,4,2|6,4,2|6,4,2|7,5,3;'
    '2:6,4,2|3,2,1|4,3,2|6,4,2|7,5,3|6,4,2|6,4,2|4,3,2|7,5,3|6,4,2;'
    '3:7,5,3|7,5,3|8,6,4|6,4,2|6,4,2|6,5,4|7,5,3|7,5,3;'
    '4:6,4,3|8,6,4|6,4,2|8,6,4|3,2,1|6,4,2|7,5,3|6,4,3';

String tablaDesdeLosMapas() => [
  for (final mapa in mapasDisponibles)
    '${mapa.numero}:${[
      for (final zona in [...mapa.crearTablero().regiones]..sort((a, b) => a.id.compareTo(b.id))) [
          for (final lugar in [1, 2, 3]) zona.tipo.puntosDeLugar(lugar),
        ].join(','),
    ].join('|')}',
].join(';');

void main() {
  test('La copia de puntos del servidor coincide con los mapas', () {
    expect(tablaDesdeLosMapas(), tablaDelServidor);
  });

  test(
    'Las zonas de cada mapa están numeradas del 1 en adelante, sin huecos',
    () {
      for (final mapa in mapasDisponibles) {
        final ids = mapa.crearTablero().regiones.map((zona) => zona.id).toList()
          ..sort();
        expect(ids, [for (var i = 1; i <= ids.length; i++) i]);
      }
    },
  );
}
