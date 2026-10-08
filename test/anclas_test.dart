import 'package:test/test.dart';

import 'package:brilliantdart/bloc_valores_iniciales.dart';
import 'package:brilliantdart/tablero.dart';
import 'package:brilliantdart/validador_anclas.dart';

void main() {
  group('Validador de anclas', () {
    test('Los dos dados pueden ser anclas si ambos valores están en el tablero', () {
      final tablero = Tablero();
      final validador = ValidadorAnclas(tablero);
      tablero.colocarDato(0, 2, 6);
      tablero.colocarDato(1, 5, 1);

      expect(validador.obtenerAnclasPosibles(6, 1), [6, 1]);
      expect(
        validador.obtenerOpciones(6, 1).map((opcion) => (
              opcion.ancla,
              opcion.numeroAColocar,
              opcion.puedeSeleccionarse,
            )),
        [(6, 1, true), (1, 6, true)],
      );
    });

    test('Solo permite como ancla el valor de dado presente en el tablero', () {
      final tablero = Tablero();
      final validador = ValidadorAnclas(tablero);
      tablero.colocarDato(0, 0, 2);

      expect(validador.obtenerAnclasPosibles(2, 4), [2]);
      expect(
        validador.obtenerOpciones(2, 4).map((opcion) => (
              opcion.ancla,
              opcion.numeroAColocar,
              opcion.puedeSeleccionarse,
            )),
        [(2, 4, true), (4, 2, false)],
      );
    });

    test('Reconoce valores iniciales y valores agregados después', () {
      final tablero = Tablero();
      final bloc = BlocValoresIniciales(tablero);
      final validador = ValidadorAnclas(tablero);

      for (var index = 0;
          index < BlocValoresIniciales.celdasIniciales.length;
          index++) {
        final (fila, columna) = BlocValoresIniciales.celdasIniciales[index];
        bloc.colocarValorInicial(fila, columna, index + 1);
      }

      expect(tablero.valoresColocados, {1, 2, 3, 4, 5, 6});

      tablero.colocarDato(3, 4, null);
      expect(validador.obtenerAnclasPosibles(2, 4), [2]);

      tablero.colocarDato(0, 0, 4);
      expect(validador.obtenerAnclasPosibles(2, 4), [2, 4]);
    });

    test('Un mismo número mostrado en ambos dados aparece como una sola ancla', () {
      final tablero = Tablero()..colocarDato(0, 0, 3);
      final validador = ValidadorAnclas(tablero);

      expect(validador.obtenerAnclasPosibles(3, 3), [3]);
      expect(validador.obtenerOpciones(3, 3), hasLength(1));
    });
  });
}