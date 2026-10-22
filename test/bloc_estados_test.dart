import 'package:test/test.dart';

import 'package:brilliantdart/bloc_valores_iniciales.dart';
import 'package:brilliantdart/mapa_uno.dart';
import 'package:brilliantdart/tablero.dart';

void main() {
  void colocarTodos(BlocValoresIniciales bloc, [List<int>? valores]) {
    final lista = valores ?? [1, 2, 3, 4, 5, 6];
    for (var i = 0; i < 6; i++) {
      final (fila, columna) = mapaUno.celdasIniciales[i];
      bloc.colocarValorInicial(fila, columna, lista[i]);
    }
  }

  group('Estados de la partida', () {
    test('Hay tres estados: bloqueado, inicializado y jugando', () {
      expect(EstadoInicialPartida.values, [
        EstadoInicialPartida.bloqueado,
        EstadoInicialPartida.inicializado,
        EstadoInicialPartida.jugando,
      ]);
    });

    test('Solo un indicador de estado es verdadero a la vez', () {
      final bloc = BlocValoresIniciales(
        Tablero(),
        celdasIniciales: mapaUno.celdasIniciales,
      );

      void comprobar() {
        final activos = [
          bloc.bloqueado,
          bloc.puedeIniciar,
          bloc.jugando,
        ].where((activo) => activo);
        expect(activos, hasLength(1));
      }

      comprobar();
      colocarTodos(bloc);
      comprobar();
      bloc.iniciarPartida();
      comprobar();
    });

    test('Las celdas iniciales están dentro del tablero (de 1 a 7)', () {
      for (final (fila, columna) in mapaUno.celdasIniciales) {
        expect(fila, inInclusiveRange(1, 7));
        expect(columna, inInclusiveRange(1, 7));
      }
    });

    test('Ninguna celda inicial está pegada a otra', () {
      final celdas = mapaUno.celdasIniciales;
      for (final (fila, columna) in celdas) {
        for (final (otraFila, otraColumna) in celdas) {
          if (fila == otraFila && columna == otraColumna) continue;
          final distancia =
              (fila - otraFila).abs() + (columna - otraColumna).abs();
          expect(distancia, greaterThan(1));
        }
      }
    });

    for (var i = 0; i < 6; i++) {
      final (fila, columna) = mapaUno.celdasIniciales[i];
      test('La celda inicial ($fila, $columna) acepta los números 1 a 6', () {
        for (var numero = 1; numero <= 6; numero++) {
          final tablero = Tablero();
          BlocValoresIniciales(
            tablero,
            celdasIniciales: mapaUno.celdasIniciales,
          ).colocarValorInicial(fila, columna, numero);
          expect(tablero.obtenerCelda(fila - 1, columna - 1).valor, numero);
        }
      });
    }

    test('Vaciar una celda inicial que ya está vacía no da error', () {
      final tablero = Tablero();
      final bloc = BlocValoresIniciales(
        tablero,
        celdasIniciales: mapaUno.celdasIniciales,
      );

      expect(() => bloc.colocarValorInicial(1, 3, null), returnsNormally);
      expect(tablero.obtenerCelda(0, 2).valor, isNull);
    });

    test('Rechaza la celda (1, 1) y la (7, 7)', () {
      final bloc = BlocValoresIniciales(
        Tablero(),
        celdasIniciales: mapaUno.celdasIniciales,
      );

      expect(() => bloc.colocarValorInicial(1, 1, 1), throwsArgumentError);
      expect(() => bloc.colocarValorInicial(7, 7, 1), throwsArgumentError);
    });

    test('Rechaza números negativos', () {
      final bloc = BlocValoresIniciales(
        Tablero(),
        celdasIniciales: mapaUno.celdasIniciales,
      );

      expect(() => bloc.colocarValorInicial(1, 3, -2), throwsArgumentError);
    });

    test('Seis números iguales no permiten empezar', () {
      final tablero = Tablero();
      final bloc = BlocValoresIniciales(
        tablero,
        celdasIniciales: mapaUno.celdasIniciales,
      );
      for (final (fila, columna) in mapaUno.celdasIniciales) {
        tablero.colocarDato(fila - 1, columna - 1, 3);
      }

      expect(bloc.puedeIniciar, isFalse);
    });

    test('Un número repetido puesto a mano bloquea la partida', () {
      final tablero = Tablero();
      final bloc = BlocValoresIniciales(
        tablero,
        celdasIniciales: mapaUno.celdasIniciales,
      );
      colocarTodos(bloc);

      tablero.colocarDato(0, 2, 2);

      expect(bloc.bloqueado, isTrue);
    });

    test('Números fuera de la celda inicial no afectan el estado', () {
      final tablero = Tablero();
      final bloc = BlocValoresIniciales(
        tablero,
        celdasIniciales: mapaUno.celdasIniciales,
      );
      colocarTodos(bloc);

      tablero.colocarDato(0, 0, 6);
      tablero.colocarDato(6, 6, 6);

      expect(bloc.puedeIniciar, isTrue);
      expect(bloc.obtenerValoresIniciales(), [1, 2, 3, 4, 5, 6]);
    });

    test('Si se rompe un inicial durante la partida, vuelve a bloqueado', () {
      final tablero = Tablero();
      final bloc = BlocValoresIniciales(
        tablero,
        celdasIniciales: mapaUno.celdasIniciales,
      );
      colocarTodos(bloc);
      bloc.iniciarPartida();

      tablero.colocarDato(0, 2, null);
      expect(bloc.estado, EstadoInicialPartida.bloqueado);

      tablero.colocarDato(0, 2, 1);
      expect(bloc.estado, EstadoInicialPartida.jugando);
    });

    test('Dos blocs sobre tableros distintos no se mezclan', () {
      final primero = BlocValoresIniciales(
        Tablero(),
        celdasIniciales: mapaUno.celdasIniciales,
      );
      final segundo = BlocValoresIniciales(
        Tablero(),
        celdasIniciales: mapaUno.celdasIniciales,
      );

      colocarTodos(primero);

      expect(primero.puedeIniciar, isTrue);
      expect(segundo.bloqueado, isTrue);
    });

    test('Se puede reiniciar y volver a iniciar', () {
      final bloc = BlocValoresIniciales(
        Tablero(),
        celdasIniciales: mapaUno.celdasIniciales,
      );
      colocarTodos(bloc);
      bloc.iniciarPartida();

      bloc.reiniciar();
      bloc.iniciarPartida();

      expect(bloc.jugando, isTrue);
    });

    test('Reiniciar un bloc bloqueado lo deja bloqueado', () {
      final bloc = BlocValoresIniciales(
        Tablero(),
        celdasIniciales: mapaUno.celdasIniciales,
      )..reiniciar();

      expect(bloc.bloqueado, isTrue);
    });
  });
}
