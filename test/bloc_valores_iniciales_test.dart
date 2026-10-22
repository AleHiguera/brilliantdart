import 'package:test/test.dart';

import 'package:brilliantdart/bloc_valores_iniciales.dart';
import 'package:brilliantdart/mapa_uno.dart';
import 'package:brilliantdart/tablero.dart';

void main() {
  void colocarIniciales(BlocValoresIniciales bloc, List<int?> valores) {
    for (var i = 0; i < valores.length; i++) {
      final (fila, columna) = mapaUno.celdasIniciales[i];
      bloc.colocarValorInicial(fila, columna, valores[i]);
    }
  }

  group('BlocValoresIniciales', () {
    test('Empieza bloqueado y sin valores iniciales', () {
      final bloc = BlocValoresIniciales(
        Tablero(),
        celdasIniciales: mapaUno.celdasIniciales,
      );

      expect(bloc.estado, EstadoInicialPartida.bloqueado);
      expect(bloc.bloqueado, isTrue);
      expect(bloc.puedeIniciar, isFalse);
      expect(bloc.jugando, isFalse);
      expect(bloc.obtenerValoresIniciales(), isEmpty);
    });

    test('Hay exactamente seis celdas iniciales distintas', () {
      expect(mapaUno.celdasIniciales, hasLength(6));
      expect(mapaUno.celdasIniciales.toSet(), hasLength(6));
    });

    test('Rechaza celdas que no son iniciales', () {
      final tablero = Tablero();
      final bloc = BlocValoresIniciales(
        tablero,
        celdasIniciales: mapaUno.celdasIniciales,
      );

      expect(() => bloc.colocarValorInicial(1, 1, 3), throwsArgumentError);
      expect(tablero.obtenerCelda(0, 0).valor, isNull);
    });

    test('Rechaza números fuera del rango 1 a 6', () {
      final tablero = Tablero();
      final bloc = BlocValoresIniciales(
        tablero,
        celdasIniciales: mapaUno.celdasIniciales,
      );

      expect(() => bloc.colocarValorInicial(1, 3, 0), throwsArgumentError);
      expect(() => bloc.colocarValorInicial(1, 3, 7), throwsArgumentError);
      expect(tablero.obtenerCelda(0, 2).valor, isNull);
    });

    test('Coloca el número en la celda del tablero (filas desde 1)', () {
      final tablero = Tablero();
      final bloc = BlocValoresIniciales(
        tablero,
        celdasIniciales: mapaUno.celdasIniciales,
      );

      bloc.colocarValorInicial(7, 5, 6);

      expect(tablero.obtenerCelda(6, 4).valor, 6);
    });

    test('Con cinco de seis números sigue bloqueado', () {
      final bloc = BlocValoresIniciales(
        Tablero(),
        celdasIniciales: mapaUno.celdasIniciales,
      );

      colocarIniciales(bloc, [1, 2, 3, 4, 5]);

      expect(bloc.bloqueado, isTrue);
      expect(bloc.obtenerValoresIniciales(), isEmpty);
    });

    test('Con los números del 1 al 6 queda listo para iniciar', () {
      final bloc = BlocValoresIniciales(
        Tablero(),
        celdasIniciales: mapaUno.celdasIniciales,
      );

      colocarIniciales(bloc, [1, 2, 3, 4, 5, 6]);

      expect(bloc.estado, EstadoInicialPartida.inicializado);
      expect(bloc.puedeIniciar, isTrue);
      expect(bloc.obtenerValoresIniciales(), [1, 2, 3, 4, 5, 6]);
      expect(() => bloc.validarAntesDeIniciar(), returnsNormally);
    });

    test('Cualquier orden de los números del 1 al 6 es válido', () {
      final bloc = BlocValoresIniciales(
        Tablero(),
        celdasIniciales: mapaUno.celdasIniciales,
      );

      colocarIniciales(bloc, [6, 4, 2, 5, 3, 1]);

      expect(bloc.puedeIniciar, isTrue);
      expect(bloc.obtenerValoresIniciales(), [6, 4, 2, 5, 3, 1]);
    });

    test('Repetir un número lo quita de la otra celda inicial', () {
      final tablero = Tablero();
      final bloc = BlocValoresIniciales(
        tablero,
        celdasIniciales: mapaUno.celdasIniciales,
      );
      colocarIniciales(bloc, [1, 2, 3, 4, 5, 6]);

      bloc.colocarValorInicial(1, 3, 6);

      expect(tablero.obtenerCelda(0, 2).valor, 6);
      expect(tablero.obtenerCelda(6, 4).valor, isNull);
      expect(bloc.bloqueado, isTrue);
    });

    test('Volver a poner el mismo número en la misma celda no la vacía', () {
      final tablero = Tablero();
      final bloc = BlocValoresIniciales(
        tablero,
        celdasIniciales: mapaUno.celdasIniciales,
      );

      bloc.colocarValorInicial(1, 3, 4);
      bloc.colocarValorInicial(1, 3, 4);

      expect(tablero.obtenerCelda(0, 2).valor, 4);
    });

    test('Vaciar una celda inicial vuelve a bloquear la partida', () {
      final tablero = Tablero();
      final bloc = BlocValoresIniciales(
        tablero,
        celdasIniciales: mapaUno.celdasIniciales,
      );
      colocarIniciales(bloc, [1, 2, 3, 4, 5, 6]);

      bloc.colocarValorInicial(4, 2, null);

      expect(tablero.obtenerCelda(3, 1).valor, isNull);
      expect(bloc.bloqueado, isTrue);
    });

    test('No permite iniciar la partida mientras está bloqueado', () {
      final bloc = BlocValoresIniciales(
        Tablero(),
        celdasIniciales: mapaUno.celdasIniciales,
      );
      colocarIniciales(bloc, [1, 2, 3]);

      expect(() => bloc.iniciarPartida(), throwsStateError);
      expect(() => bloc.validarAntesDeIniciar(), throwsStateError);
      expect(bloc.jugando, isFalse);
    });

    test('Iniciar la partida cambia el estado a jugando', () {
      final bloc = BlocValoresIniciales(
        Tablero(),
        celdasIniciales: mapaUno.celdasIniciales,
      );
      colocarIniciales(bloc, [1, 2, 3, 4, 5, 6]);

      bloc.iniciarPartida();

      expect(bloc.estado, EstadoInicialPartida.jugando);
      expect(bloc.jugando, isTrue);
      expect(bloc.puedeIniciar, isFalse);
    });

    test('No se puede iniciar dos veces la misma partida', () {
      final bloc = BlocValoresIniciales(
        Tablero(),
        celdasIniciales: mapaUno.celdasIniciales,
      );
      colocarIniciales(bloc, [1, 2, 3, 4, 5, 6]);
      bloc.iniciarPartida();

      expect(() => bloc.iniciarPartida(), throwsStateError);
    });

    test('Reiniciar sale del modo jugando', () {
      final bloc = BlocValoresIniciales(
        Tablero(),
        celdasIniciales: mapaUno.celdasIniciales,
      );
      colocarIniciales(bloc, [1, 2, 3, 4, 5, 6]);
      bloc.iniciarPartida();

      bloc.reiniciar();

      expect(bloc.jugando, isFalse);
      expect(bloc.puedeIniciar, isTrue);
    });
  });

  group('BlocValoresIniciales con celdas de cualquier mapa', () {
    const otrasCeldas = [(1, 1), (1, 7), (4, 4), (5, 2), (7, 1), (7, 7)];

    test('Guarda las celdas iniciales que recibe', () {
      final bloc = BlocValoresIniciales(
        Tablero(),
        celdasIniciales: otrasCeldas,
      );

      expect(bloc.celdasIniciales, otrasCeldas);
    });

    test('Acepta números en sus celdas y rechaza las del Mapa 1', () {
      final tablero = Tablero();
      final bloc = BlocValoresIniciales(tablero, celdasIniciales: otrasCeldas);

      bloc.colocarValorInicial(4, 4, 3);

      expect(tablero.obtenerCelda(3, 3).valor, 3);
      expect(() => bloc.colocarValorInicial(1, 3, 1), throwsArgumentError);
    });

    test('Con sus 6 celdas llenas del 1 al 6 queda listo', () {
      final bloc = BlocValoresIniciales(
        Tablero(),
        celdasIniciales: otrasCeldas,
      );
      for (var i = 0; i < 6; i++) {
        final (fila, columna) = otrasCeldas[i];
        bloc.colocarValorInicial(fila, columna, i + 1);
      }

      expect(bloc.puedeIniciar, isTrue);
    });

    test('Rechaza una lista con menos de 6 celdas', () {
      expect(
        () => BlocValoresIniciales(
          Tablero(),
          celdasIniciales: otrasCeldas.sublist(0, 5),
        ),
        throwsArgumentError,
      );
    });

    test('Rechaza una lista con más de 6 celdas', () {
      expect(
        () => BlocValoresIniciales(
          Tablero(),
          celdasIniciales: [...otrasCeldas, (2, 2)],
        ),
        throwsArgumentError,
      );
    });

    test('Rechaza celdas repetidas', () {
      expect(
        () => BlocValoresIniciales(
          Tablero(),
          celdasIniciales: [...otrasCeldas.sublist(0, 5), (1, 1)],
        ),
        throwsArgumentError,
      );
    });

    test('Las celdas no se pueden cambiar desde fuera', () {
      final bloc = BlocValoresIniciales(
        Tablero(),
        celdasIniciales: otrasCeldas,
      );

      expect(() => bloc.celdasIniciales.add((2, 2)), throwsUnsupportedError);
    });

    test('Cambiar la lista original no cambia las del bloc', () {
      final celdas = [...otrasCeldas];
      final bloc = BlocValoresIniciales(Tablero(), celdasIniciales: celdas);

      celdas[0] = (2, 2);

      expect(bloc.celdasIniciales.first, (1, 1));
    });
  });
}
