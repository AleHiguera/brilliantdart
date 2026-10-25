import 'package:test/test.dart';

import 'package:brilliantdart/constructor_tablero.dart';
import 'package:brilliantdart/dibujo_mapa.dart';
import 'package:brilliantdart/mapa.dart';
import 'package:brilliantdart/mapa_dos.dart';
import 'package:brilliantdart/mapa_tres.dart';
import 'package:brilliantdart/mapa_uno.dart';
import 'package:brilliantdart/region.dart';
import 'package:brilliantdart/tablero.dart';
import 'package:brilliantdart/tipoo.dart';

/// Todo verde con una fila naranja arriba y otra abajo.
final dibujo = leerDibujo([
  'NNNNNNN',
  for (var fila = 0; fila < 5; fila++) 'VVVVVVV',
  'NNNNNNN',
]);

Tipo tipoDeColor(TipoZona tipo) =>
    Tipo(tipo: tipo, color: tipo.name, regla: 'regla', puntuacion: 2);

/// El naranja de la fila 0 acepta del 4 al 6 y el otro del 1 al 3.
Tipo tipoDeZona(TipoZona tipo, List<(int, int)> posiciones) {
  if (tipo != TipoZona.naranja) return tipoDeColor(tipo);
  final arriba = posiciones.first.$1 == 0;
  return TipoNaranja(
    color: 'Naranja',
    regla: arriba ? 'Del 4 al 6' : 'Del 1 al 3',
    puntuacion: 6,
    minimo: arriba ? 4 : 1,
    maximo: arriba ? 6 : 3,
  );
}

List<Region> naranjas(Tablero tablero) => tablero.regiones
    .where((zona) => zona.tipo.tipo == TipoZona.naranja)
    .toList();

/// Mapa de prueba con dos naranjas de reglas distintas (celdas desde 1).
class MapaConDosNaranjas extends Mapa {
  const MapaConDosNaranjas();

  @override
  int get numero => 97;

  @override
  List<List<TipoZona>> get tiposPorCelda => dibujo;

  @override
  List<(int, int)> get celdasIniciales => const [
    (2, 1),
    (2, 3),
    (2, 5),
    (4, 1),
    (4, 3),
    (4, 5),
  ];

  @override
  Set<TipoZona> get tiposUnidos => const {};

  @override
  Tipo crearTipo(TipoZona tipo) => tipoDeColor(tipo);

  @override
  Tipo crearTipoDeZona(TipoZona tipo, List<(int, int)> celdas) {
    if (tipo != TipoZona.naranja) return crearTipo(tipo);
    final arriba = celdas.first.$1 == 1;
    return TipoNaranja(
      color: 'Naranja',
      regla: 'rango',
      puntuacion: 6,
      minimo: arriba ? 4 : 1,
      maximo: arriba ? 6 : 3,
    );
  }
}

void main() {
  group('Una regla distinta para cada zona del mismo color', () {
    test('Sin crearTipoDeZona cada zona usa la regla de su color', () {
      final tablero = ConstructorTablero(
        tiposPorCelda: dibujo,
        crearTipo: tipoDeColor,
      ).construir();

      for (final zona in naranjas(tablero)) {
        expect((zona.tipo as TipoNaranja).minimo, 1);
        expect((zona.tipo as TipoNaranja).maximo, 6);
      }
    });

    test('Con crearTipoDeZona cada naranja tiene su propio rango', () {
      final tablero = ConstructorTablero(
        tiposPorCelda: dibujo,
        crearTipo: tipoDeColor,
        crearTipoDeZona: tipoDeZona,
      ).construir();
      final [arriba, abajo] = naranjas(tablero);

      expect((arriba.tipo as TipoNaranja).minimo, 4);
      expect((arriba.tipo as TipoNaranja).maximo, 6);
      expect((abajo.tipo as TipoNaranja).minimo, 1);
      expect((abajo.tipo as TipoNaranja).maximo, 3);
    });

    test('Recibe las celdas exactas de cada zona', () {
      final recibidas = <TipoZona, List<List<(int, int)>>>{};
      ConstructorTablero(
        tiposPorCelda: dibujo,
        crearTipo: tipoDeColor,
        crearTipoDeZona: (tipo, posiciones) {
          (recibidas[tipo] ??= []).add(posiciones);
          return tipoDeColor(tipo);
        },
      ).construir();

      expect(recibidas[TipoZona.naranja], [
        [for (var columna = 0; columna < 7; columna++) (0, columna)],
        [for (var columna = 0; columna < 7; columna++) (6, columna)],
      ]);
      expect(recibidas[TipoZona.verde]!.single, hasLength(35));
    });

    test('Se llama una vez por zona', () {
      var llamadas = 0;
      final tablero = ConstructorTablero(
        tiposPorCelda: dibujo,
        crearTipo: tipoDeColor,
        crearTipoDeZona: (tipo, posiciones) {
          llamadas++;
          return tipoDeColor(tipo);
        },
      ).construir();

      expect(llamadas, tablero.regiones.length);
      expect(llamadas, 3);
    });

    test('Las celdas que recibe no se pueden modificar', () {
      expect(
        () => ConstructorTablero(
          tiposPorCelda: dibujo,
          crearTipo: tipoDeColor,
          crearTipoDeZona: (tipo, posiciones) {
            posiciones.add((9, 9));
            return tipoDeColor(tipo);
          },
        ).construir(),
        throwsUnsupportedError,
      );
    });

    test('Cada naranja aplica su regla en el tablero', () {
      final tablero = ConstructorTablero(
        tiposPorCelda: dibujo,
        crearTipo: tipoDeColor,
        crearTipoDeZona: tipoDeZona,
      ).construir();

      expect(tablero.puedeColocarDato(0, 0, 5), isTrue);
      expect(tablero.puedeColocarDato(0, 0, 2), isFalse);
      expect(tablero.puedeColocarDato(6, 0, 2), isTrue);
      expect(tablero.puedeColocarDato(6, 0, 5), isFalse);
    });

    test('Cada naranja puntúa por separado', () {
      final tablero = ConstructorTablero(
        tiposPorCelda: dibujo,
        crearTipo: tipoDeColor,
        crearTipoDeZona: tipoDeZona,
      ).construir();
      for (var columna = 0; columna < 7; columna++) {
        tablero.colocarDato(0, columna, 6);
      }

      expect(tablero.zonasCompletadasPorTipo(TipoZona.naranja), 1);
      expect(tablero.puntuacionPorTipo(TipoZona.naranja), 6);

      for (var columna = 0; columna < 7; columna++) {
        tablero.colocarDato(6, columna, 1);
      }

      expect(tablero.zonasCompletadasPorTipo(TipoZona.naranja), 2);
      expect(tablero.puntuacionPorTipo(TipoZona.naranja), 12);
    });
  });

  group('crearTipoDeZona desde un Mapa', () {
    const mapa = MapaConDosNaranjas();

    test('El mapa recibe las celdas contando desde 1', () {
      final [arriba, abajo] = naranjas(mapa.crearTablero());

      expect((arriba.tipo as TipoNaranja).minimo, 4);
      expect((abajo.tipo as TipoNaranja).maximo, 3);
    });

    test('Por defecto un mapa usa la regla de su color', () {
      final tipo = mapaUno.crearTipoDeZona(TipoZona.azul, const [(1, 1)]);

      expect(tipo.tipo, TipoZona.azul);
      expect(tipo.puntuacion, mapaUno.crearTipo(TipoZona.azul).puntuacion);
    });

    test('Los mapas 1, 2 y 3 no cambian', () {
      expect(mapaUno.crearTablero().regiones, hasLength(9));
      expect(mapaDos.crearTablero().regiones, hasLength(10));
      expect(mapaTres.crearTablero().regiones, hasLength(8));
      expect(mapaUno.crearTablero().puntuacionMaxima, 54);
      expect(mapaDos.crearTablero().puntuacionMaxima, 55);
      expect(mapaTres.crearTablero().puntuacionMaxima, 54);
    });
  });
}
