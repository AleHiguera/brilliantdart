import 'package:brilliantdart/catalogo_mapas.dart';
import 'package:brilliantdart/lugares_de_zona.dart';
import 'package:brilliantdart/tipoo.dart';
import 'package:test/test.dart';

/// El rojo vale 6, 4 y 2 en todos los mapas.
final Tipo rojo = mapaNumero(1)
    .crearTablero()
    .regiones
    .firstWhere((zona) => zona.tipo.tipo == TipoZona.rojo)
    .tipo;

LugaresDeZona zona(Map<String, int> rondaPorJugador) =>
    LugaresDeZona(rojo, rondaPorJugador);

void main() {
  group('Lugares de una zona', () {
    test('Sin nadie que la complete no hay lugares', () {
      expect(zona({}).lugares, isEmpty);
      expect(zona({}).puntos, isEmpty);
    });

    test('Rondas distintas dan lugares seguidos', () {
      final reparto = zona({'ana': 3, 'luis': 5, 'eva': 9});

      expect(reparto.lugares, {'ana': 1, 'luis': 2, 'eva': 3});
      expect(reparto.puntos, {'ana': 6, 'luis': 4, 'eva': 2});
    });

    test('El número de la ronda no importa, solo el orden', () {
      expect(
        zona({'ana': 1, 'luis': 2}).lugares,
        zona({'ana': 40, 'luis': 90}).lugares,
      );
    });

    test('El orden de la lista no importa, solo la ronda', () {
      expect(zona({'luis': 5, 'ana': 3}).lugares, {'ana': 1, 'luis': 2});
    });

    test('Dos en la misma ronda comparten el lugar y sus puntos completos', () {
      final reparto = zona({'ana': 4, 'luis': 4});

      expect(reparto.lugares, {'ana': 1, 'luis': 1});
      expect(reparto.puntos, {'ana': 6, 'luis': 6});
    });

    test('Un empate no gasta lugares: el tercero sigue libre', () {
      final reparto = zona({'ana': 2, 'luis': 5, 'eva': 5, 'sol': 8});

      expect(reparto.lugares, {'ana': 1, 'luis': 2, 'eva': 2, 'sol': 3});
      expect(reparto.puntos, {'ana': 6, 'luis': 4, 'eva': 4, 'sol': 2});
    });

    test('Dos en primero: el siguiente es segundo, no tercero', () {
      final reparto = zona({'ana': 2, 'luis': 2, 'eva': 6});

      expect(reparto.lugares['eva'], 2);
      expect(reparto.puntos['eva'], 4);
    });

    test('Pueden empatar tres o cuatro y todos reciben los puntos', () {
      expect(zona({'a': 3, 'b': 3, 'c': 3}).puntos, {'a': 6, 'b': 6, 'c': 6});
      expect(zona({'a': 7, 'b': 3, 'c': 3, 'd': 3, 'e': 3}).puntos, {
        'a': 4,
        'b': 6,
        'c': 6,
        'd': 6,
        'e': 6,
      });
    });

    test('Del cuarto lugar en adelante no se ganan puntos', () {
      final reparto = zona({'a': 1, 'b': 2, 'c': 3, 'd': 4, 'e': 5, 'f': 6});

      expect(reparto.lugares, {'a': 1, 'b': 2, 'c': 3, 'd': 4, 'e': 5, 'f': 6});
      expect(reparto.puntos, {'a': 6, 'b': 4, 'c': 2, 'd': 0, 'e': 0, 'f': 0});
    });

    test('Los empatados en cuarto tampoco ganan puntos', () {
      final reparto = zona({'a': 1, 'b': 2, 'c': 3, 'd': 4, 'e': 4});

      expect(reparto.lugares['d'], 4);
      expect(reparto.lugares['e'], 4);
      expect(reparto.puntos['d'], 0);
      expect(reparto.puntos['e'], 0);
    });

    test('Usa los puntos propios del mapa', () {
      final gris = mapaNumero(3)
          .crearTablero()
          .regiones
          .firstWhere((zona) => zona.tipo.tipo == TipoZona.gris)
          .tipo;

      expect(LugaresDeZona(gris, {'a': 1, 'b': 2, 'c': 3}).puntos, {
        'a': 8,
        'b': 6,
        'c': 4,
      });
    });
  });
}
