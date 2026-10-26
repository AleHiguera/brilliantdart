import 'package:test/test.dart';

import 'package:brilliantdart/bloc_valores_iniciales.dart';
import 'package:brilliantdart/mapa_cuatro.dart';
import 'package:brilliantdart/mapa_dos.dart';
import 'package:brilliantdart/mapa_tres.dart';
import 'package:brilliantdart/mapa_uno.dart';
import 'package:brilliantdart/tablero.dart';

void main() {
  BlocValoresIniciales blocDelMapaCuatro([Tablero? tablero]) =>
      BlocValoresIniciales(
        tablero ?? mapaCuatro.crearTablero(),
        celdasIniciales: mapaCuatro.celdasIniciales,
      );

  group('Números permitidos en las celdas iniciales del Mapa 4', () {
    test('La (1, 5), del naranja alto, solo permite 4, 5 y 6', () {
      expect(blocDelMapaCuatro().valoresPermitidos(1, 5), {4, 5, 6});
    });

    test('La (7, 2), del naranja bajo, solo permite 1, 2 y 3', () {
      expect(blocDelMapaCuatro().valoresPermitidos(7, 2), {1, 2, 3});
    });

    test('Las demás celdas iniciales permiten del 1 al 6', () {
      final bloc = blocDelMapaCuatro();

      for (final (fila, columna) in [(3, 3), (3, 6), (4, 1), (6, 5)]) {
        expect(bloc.valoresPermitidos(fila, columna), {1, 2, 3, 4, 5, 6});
      }
    });

    test('Poner un 2 en la (1, 5) es un error y no cambia el tablero', () {
      final tablero = mapaCuatro.crearTablero();
      final bloc = blocDelMapaCuatro(tablero);

      expect(() => bloc.colocarValorInicial(1, 5, 2), throwsArgumentError);
      expect(tablero.obtenerCelda(0, 4).valor, isNull);
    });

    test('Poner un 5 en la (7, 2) es un error y no cambia el tablero', () {
      final tablero = mapaCuatro.crearTablero();
      final bloc = blocDelMapaCuatro(tablero);

      expect(() => bloc.colocarValorInicial(7, 2, 5), throwsArgumentError);
      expect(tablero.obtenerCelda(6, 1).valor, isNull);
    });

    test('Un número del rango sí se coloca', () {
      final tablero = mapaCuatro.crearTablero();
      final bloc = blocDelMapaCuatro(tablero)
        ..colocarValorInicial(1, 5, 6)
        ..colocarValorInicial(7, 2, 1);

      expect(tablero.obtenerCelda(0, 4).valor, 6);
      expect(tablero.obtenerCelda(6, 1).valor, 1);
      expect(bloc.puedeSerValorInicial(1, 5, 4), isTrue);
    });

    test('Vaciar una celda naranja siempre se puede', () {
      final tablero = mapaCuatro.crearTablero();
      blocDelMapaCuatro(tablero)
        ..colocarValorInicial(1, 5, 5)
        ..colocarValorInicial(1, 5, null);

      expect(tablero.obtenerCelda(0, 4).valor, isNull);
    });

    test('Mover un número a la naranja vacía la otra celda inicial', () {
      final tablero = mapaCuatro.crearTablero();
      blocDelMapaCuatro(tablero)
        ..colocarValorInicial(3, 3, 5)
        ..colocarValorInicial(1, 5, 5);

      expect(tablero.obtenerCelda(0, 4).valor, 5);
      expect(tablero.obtenerCelda(2, 2).valor, isNull);
    });

    test('Se puede completar respetando los rangos y comenzar', () {
      final bloc = blocDelMapaCuatro();
      const valores = [6, 2, 3, 4, 5, 1];

      for (var i = 0; i < 6; i++) {
        final (fila, columna) = mapaCuatro.celdasIniciales[i];
        bloc.colocarValorInicial(fila, columna, valores[i]);
      }

      expect(bloc.puedeIniciar, isTrue);
    });
  });

  group('Números permitidos en los otros mapas', () {
    test('En los mapas 1, 2 y 3 todas las celdas iniciales permiten 1 a 6', () {
      for (final mapa in [mapaUno, mapaDos, mapaTres]) {
        final bloc = BlocValoresIniciales(
          mapa.crearTablero(),
          celdasIniciales: mapa.celdasIniciales,
        );
        for (final (fila, columna) in mapa.celdasIniciales) {
          expect(bloc.valoresPermitidos(fila, columna), {
            1,
            2,
            3,
            4,
            5,
            6,
          }, reason: 'Mapa ${mapa.numero}, celda ($fila, $columna)');
        }
      }
    });

    test('En un tablero sin zonas se permite del 1 al 6', () {
      final bloc = BlocValoresIniciales(
        Tablero(),
        celdasIniciales: mapaUno.celdasIniciales,
      );

      expect(bloc.valoresPermitidos(1, 3), {1, 2, 3, 4, 5, 6});
    });

    test('La regla de la zona cuenta los números que ya tiene', () {
      // En el Mapa 1 la (4, 2) es roja: si su zona ya tiene un 4, no acepta
      // otro 4 como número inicial.
      final tablero = mapaUno.crearTablero();
      final bloc = BlocValoresIniciales(
        tablero,
        celdasIniciales: mapaUno.celdasIniciales,
      );
      final roja = tablero.regiones.firstWhere(
        (zona) => zona.coordenadas.any((c) => c.x == 3 && c.y == 1),
      );
      final otra = roja.coordenadas.firstWhere((c) => !(c.x == 3 && c.y == 1));
      tablero.colocarDato(otra.x, otra.y, 4);

      expect(bloc.puedeSerValorInicial(4, 2, 4), isFalse);
      expect(bloc.puedeSerValorInicial(4, 2, 5), isTrue);
    });
  });
}
