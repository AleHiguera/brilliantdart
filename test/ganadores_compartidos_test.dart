// El servidor elige al ganador en Java (Puntuacion.ganadores) y la app arma la
// clasificación en Dart (Clasificacion). Los dos deben coincidir.
//
// Estos casos están copiados tal cual en PruebasPuntuacion.CASOS_COMPARTIDOS
// del servidor (RegistroClientes): si se cambia uno, hay que cambiar el otro.
// Cada caso es: mapa | zona:jugador=ronda,...;zona:... | jugadores | ganadores

import 'package:brilliantdart/catalogo_mapas.dart';
import 'package:brilliantdart/clasificacion.dart';
import 'package:brilliantdart/puntuacion_multijugador.dart';
import 'package:test/test.dart';

const List<String> casosCompartidos = [
  // Luis: azul 7 + amarilla 2.º lugar 6 = 13; Ana 8; Eva 7.
  '1|1:ana=1,luis=2;3:luis=1,eva=1|ana,luis,eva|luis',
  // Mismos puntos: ganan los dos.
  '1|1:ana=1,luis=1|ana,luis,eva|ana,luis',
  // Quien salió conserva sus puntos y puede ganar.
  '1|1:salio=1|ana|salio',
  // Nadie completó nada: empatan todos los que siguen.
  '1||ana,luis|ana,luis',
  // Mapa 3: gris 8, 6, 4 y verde 6, 5, 4. Ana: 6 + 6 = 12; Eva: 8.
  '3|3:eva=2,ana=5;6:ana=1|ana,eva|ana',
  // Mapa 4: el empate en la amarilla no gasta lugares. C: 6 + azul 8 = 14.
  '4|2:a=1,b=1,c=2;4:c=1|a,b,c|c',
  // El 4.º lugar no da puntos: D solo suma su azul (7).
  '1|1:a=1,b=2,c=3,d=4;9:d=1|a,b,c,d|a',
];

typedef Caso = ({
  int mapa,
  Map<int, Map<String, int>> zonas,
  List<String> jugadores,
  List<String> ganadores,
});

Caso leer(String caso) {
  final [mapa, zonas, jugadores, ganadores] = caso.split('|');
  return (
    mapa: int.parse(mapa),
    zonas: {
      if (zonas.isNotEmpty)
        for (final zona in zonas.split(';'))
          int.parse(zona.split(':')[0]): {
            for (final par in zona.split(':')[1].split(','))
              par.split('=')[0]: int.parse(par.split('=')[1]),
          },
    },
    jugadores: jugadores.split(','),
    ganadores: ganadores.split(','),
  );
}

void main() {
  group('Ganadores: el servidor y la app coinciden', () {
    for (final texto in casosCompartidos) {
      test(texto, () {
        final caso = leer(texto);
        final puntos = PuntuacionMultijugador(
          mapaNumero(caso.mapa),
          caso.zonas,
        ).puntos;

        final primeros = Clasificacion(
          puntos: puntos,
          jugadores: caso.jugadores,
        ).puestos.where((puesto) => puesto.lugar == 1);

        expect(primeros.map((puesto) => puesto.jugador), caso.ganadores);
      });
    }

    test('Se lee bien un caso', () {
      final caso = leer('1|1:ana=1,luis=2;3:luis=1|ana,luis|luis');

      expect(caso.mapa, 1);
      expect(caso.zonas, {
        1: {'ana': 1, 'luis': 2},
        3: {'luis': 1},
      });
      expect(caso.jugadores, ['ana', 'luis']);
      expect(caso.ganadores, ['luis']);
    });
  });
}
