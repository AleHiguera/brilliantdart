import 'package:test/test.dart';

import 'package:brilliantdart/bloc_valores_iniciales.dart';
import 'package:brilliantdart/mapa_uno.dart';
import 'package:brilliantdart/tablero.dart';
import 'package:brilliantdart/validador_anclas.dart';

void main() {
  group('Validador de anclas', () {
    test(
      'Los dos dados pueden ser anclas si ambos valores están en el tablero',
      () {
        final tablero = Tablero();
        final validador = ValidadorAnclas(tablero);
        tablero.colocarDato(0, 2, 6);
        tablero.colocarDato(1, 5, 1);

        expect(validador.obtenerAnclasPosibles(6, 1), [6, 1]);
        expect(
          validador
              .obtenerOpciones(6, 1)
              .map(
                (opcion) => (
                  opcion.ancla,
                  opcion.numeroAColocar,
                  opcion.puedeSeleccionarse,
                ),
              ),
          [(6, 1, true), (1, 6, true)],
        );
      },
    );

    test('Solo permite como ancla el valor de dado presente en el tablero', () {
      final tablero = Tablero();
      final validador = ValidadorAnclas(tablero);
      tablero.colocarDato(0, 0, 2);

      expect(validador.obtenerAnclasPosibles(2, 4), [2]);
      expect(
        validador
            .obtenerOpciones(2, 4)
            .map(
              (opcion) => (
                opcion.ancla,
                opcion.numeroAColocar,
                opcion.puedeSeleccionarse,
              ),
            ),
        [(2, 4, true), (4, 2, false)],
      );
    });

    test('Reconoce valores iniciales y valores agregados después', () {
      final tablero = Tablero();
      final bloc = BlocValoresIniciales(
        tablero,
        celdasIniciales: mapaUno.celdasIniciales,
      );
      final validador = ValidadorAnclas(tablero);

      for (var index = 0; index < mapaUno.celdasIniciales.length; index++) {
        final (fila, columna) = mapaUno.celdasIniciales[index];
        bloc.colocarValorInicial(fila, columna, index + 1);
      }

      expect(tablero.valoresColocados, {1, 2, 3, 4, 5, 6});

      tablero.colocarDato(3, 4, null);
      expect(validador.obtenerAnclasPosibles(2, 4), [2]);

      tablero.colocarDato(0, 0, 4);
      expect(validador.obtenerAnclasPosibles(2, 4), [2, 4]);
    });

    test(
      'Un mismo número mostrado en ambos dados aparece como una sola ancla',
      () {
        final tablero = Tablero()..colocarDato(0, 0, 3);
        final validador = ValidadorAnclas(tablero);

        expect(validador.obtenerAnclasPosibles(3, 3), [3]);
        expect(validador.obtenerOpciones(3, 3), hasLength(1));
      },
    );

    test('Sin números en el tablero no hay ninguna ancla posible', () {
      final validador = ValidadorAnclas(mapaUno.crearTablero());

      expect(validador.obtenerAnclasPosibles(1, 2), isEmpty);
      for (final opcion in validador.obtenerOpciones(1, 2)) {
        expect(opcion.puedeSeleccionarse, isFalse);
        expect(validador.obtenerMovimientosPosibles(opcion), isEmpty);
      }
    });
  });

  group('Movimientos con ancla en el mapa uno', () {
    Set<(int, int)> destinos(List<MovimientoAncla> movimientos) =>
        movimientos.map((m) => (m.destino.x, m.destino.y)).toSet();

    test('Ofrece las cuatro celdas vacías alrededor del ancla', () {
      final tablero = mapaUno.crearTablero()..colocarDato(3, 3, 1);
      final validador = ValidadorAnclas(tablero);
      final opcion = validador.obtenerOpciones(1, 2).first;

      final movimientos = validador.obtenerMovimientosPosibles(opcion);

      expect(destinos(movimientos), {(2, 3), (4, 3), (3, 2), (3, 4)});
      for (final movimiento in movimientos) {
        expect(movimiento.ancla.valor, 1);
        expect(
          (movimiento.ancla.x - movimiento.destino.x).abs() +
              (movimiento.ancla.y - movimiento.destino.y).abs(),
          1,
        );
      }
    });

    test('No ofrece celdas ocupadas', () {
      final tablero = mapaUno.crearTablero()
        ..colocarDato(3, 3, 1)
        ..colocarDato(2, 3, 5);
      final validador = ValidadorAnclas(tablero);

      final movimientos = validador.obtenerMovimientosPosibles(
        validador.obtenerOpciones(1, 2).first,
      );

      expect(destinos(movimientos), {(4, 3), (3, 2), (3, 4)});
    });

    test('Descarta celdas donde el número rompe la regla de la zona', () {
      final tablero = mapaUno.crearTablero()..colocarDato(3, 1, 4);
      final validador = ValidadorAnclas(tablero);

      final movimientos = validador.obtenerMovimientosPosibles(
        validador.obtenerOpciones(4, 4).single,
      );

      // (2,1) y (4,1) son rojas y ya tienen un 4; (3,0) es verde y (3,2) morada.
      expect(destinos(movimientos), {(3, 0), (3, 2)});
    });

    test('Una celda junto a dos anclas aparece una sola vez', () {
      final tablero = mapaUno.crearTablero()
        ..colocarDato(2, 3, 1)
        ..colocarDato(4, 3, 1);
      final validador = ValidadorAnclas(tablero);

      final movimientos = validador.obtenerMovimientosPosibles(
        validador.obtenerOpciones(1, 2).first,
      );

      expect(
        movimientos.where((m) => m.destino.x == 3 && m.destino.y == 3),
        hasLength(1),
      );
    });

    test('Una opción marcada como no seleccionable no genera movimientos', () {
      final tablero = mapaUno.crearTablero()..colocarDato(3, 3, 1);
      final validador = ValidadorAnclas(tablero);

      expect(
        validador.obtenerMovimientosPosibles(
          const OpcionAncla(
            ancla: 1,
            numeroAColocar: 2,
            puedeSeleccionarse: false,
          ),
        ),
        isEmpty,
      );
    });

    test('La lista de movimientos no se puede modificar', () {
      final tablero = mapaUno.crearTablero()..colocarDato(3, 3, 1);
      final validador = ValidadorAnclas(tablero);
      final movimientos = validador.obtenerMovimientosPosibles(
        validador.obtenerOpciones(1, 2).first,
      );

      expect(() => movimientos.clear(), throwsUnsupportedError);
    });
  });
}
