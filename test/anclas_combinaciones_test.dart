import 'package:test/test.dart';

import 'package:brilliantdart/bloc_valores_iniciales.dart';
import 'package:brilliantdart/mapa_uno.dart';
import 'package:brilliantdart/tablero.dart';
import 'package:brilliantdart/validador_anclas.dart';

void main() {
  /// Mapa uno con los 6 números iniciales colocados del 1 al 6.
  Tablero tableroInicial() {
    final tablero = mapaUno.crearTablero();
    final bloc = BlocValoresIniciales(
      tablero,
      celdasIniciales: mapaUno.celdasIniciales,
    );
    for (var i = 0; i < 6; i++) {
      final (fila, columna) = mapaUno.celdasIniciales[i];
      bloc.colocarValorInicial(fila, columna, i + 1);
    }
    return tablero;
  }

  final combinaciones = [
    for (var dado1 = 1; dado1 <= 6; dado1++)
      for (var dado2 = 1; dado2 <= 6; dado2++) (dado1, dado2),
  ];

  group('Las 36 combinaciones de dados', () {
    test('Son 36 combinaciones', () {
      expect(combinaciones, hasLength(36));
    });

    test('Con dados distintos hay dos opciones; con dobles, una', () {
      final validador = ValidadorAnclas(tableroInicial());

      for (final (dado1, dado2) in combinaciones) {
        expect(
          validador.obtenerOpciones(dado1, dado2),
          hasLength(dado1 == dado2 ? 1 : 2),
          reason: '($dado1, $dado2)',
        );
      }
    });

    test('Al empezar, todas las opciones se pueden elegir', () {
      final validador = ValidadorAnclas(tableroInicial());

      for (final (dado1, dado2) in combinaciones) {
        for (final opcion in validador.obtenerOpciones(dado1, dado2)) {
          expect(opcion.puedeSeleccionarse, isTrue, reason: '($dado1, $dado2)');
        }
      }
    });

    test('La primera opción usa el dado 1 como ancla', () {
      final validador = ValidadorAnclas(tableroInicial());

      for (final (dado1, dado2) in combinaciones) {
        final primera = validador.obtenerOpciones(dado1, dado2).first;
        expect((primera.ancla, primera.numeroAColocar), (dado1, dado2));
      }
    });

    test('La segunda opción intercambia los dados', () {
      final validador = ValidadorAnclas(tableroInicial());

      for (final (dado1, dado2) in combinaciones.where((c) => c.$1 != c.$2)) {
        final segunda = validador.obtenerOpciones(dado1, dado2).last;
        expect((segunda.ancla, segunda.numeroAColocar), (dado2, dado1));
      }
    });

    test('Al empezar, todas las combinaciones tienen algún movimiento', () {
      final validador = ValidadorAnclas(tableroInicial());

      for (final (dado1, dado2) in combinaciones) {
        final hayMovimiento = validador
            .obtenerOpciones(dado1, dado2)
            .any(
              (opcion) =>
                  validador.obtenerMovimientosPosibles(opcion).isNotEmpty,
            );
        expect(hayMovimiento, isTrue, reason: '($dado1, $dado2)');
      }
    });

    test('Todo movimiento ofrecido se puede colocar de verdad', () {
      final tablero = tableroInicial();
      final validador = ValidadorAnclas(tablero);

      for (final (dado1, dado2) in combinaciones) {
        for (final opcion in validador.obtenerOpciones(dado1, dado2)) {
          for (final movimiento in validador.obtenerMovimientosPosibles(
            opcion,
          )) {
            expect(
              tablero.puedeColocarDato(
                movimiento.destino.x,
                movimiento.destino.y,
                opcion.numeroAColocar,
              ),
              isTrue,
            );
          }
        }
      }
    });

    test('Todo movimiento va a una celda vacía junto al ancla', () {
      final validador = ValidadorAnclas(tableroInicial());

      for (final (dado1, dado2) in combinaciones) {
        for (final opcion in validador.obtenerOpciones(dado1, dado2)) {
          for (final movimiento in validador.obtenerMovimientosPosibles(
            opcion,
          )) {
            expect(movimiento.destino.valor, isNull);
            expect(movimiento.ancla.valor, opcion.ancla);
            expect(
              (movimiento.ancla.x - movimiento.destino.x).abs() +
                  (movimiento.ancla.y - movimiento.destino.y).abs(),
              1,
            );
          }
        }
      }
    });

    test('Calcular movimientos no cambia el tablero', () {
      final tablero = tableroInicial();
      final antes = tablero.extraerDatos();
      final validador = ValidadorAnclas(tablero);

      for (final (dado1, dado2) in combinaciones) {
        for (final opcion in validador.obtenerOpciones(dado1, dado2)) {
          validador.obtenerMovimientosPosibles(opcion);
        }
      }

      expect(tablero.extraerDatos(), antes);
    });
  });

  group('Casos extremos de anclas', () {
    test('En un tablero vacío ningún número puede ser ancla', () {
      final validador = ValidadorAnclas(Tablero());

      for (var numero = 1; numero <= 6; numero++) {
        expect(validador.puedeSerAncla(numero), isFalse);
      }
    });

    test('Con los iniciales puestos, todo número del 1 al 6 es ancla', () {
      final validador = ValidadorAnclas(tableroInicial());

      for (var numero = 1; numero <= 6; numero++) {
        expect(validador.puedeSerAncla(numero), isTrue);
      }
    });

    test('Ni el 0 ni el 7 pueden ser ancla', () {
      final validador = ValidadorAnclas(tableroInicial());

      expect(validador.puedeSerAncla(0), isFalse);
      expect(validador.puedeSerAncla(7), isFalse);
    });

    test('Con el tablero lleno no hay ningún movimiento', () {
      final tablero = mapaUno.crearTablero();
      for (final celda in tablero.celdas) {
        tablero.colocarDato(celda.x, celda.y, 1);
      }
      final validador = ValidadorAnclas(tablero);

      for (final (dado1, dado2) in combinaciones) {
        for (final opcion in validador.obtenerOpciones(dado1, dado2)) {
          expect(validador.obtenerMovimientosPosibles(opcion), isEmpty);
        }
      }
    });

    test('Un número suelto sin zonas alrededor no ofrece movimientos', () {
      final tablero = Tablero()..colocarDato(3, 3, 2);
      final validador = ValidadorAnclas(tablero);

      expect(validador.puedeSerAncla(2), isTrue);
      expect(
        validador.obtenerMovimientosPosibles(
          validador.obtenerOpciones(2, 4).first,
        ),
        isEmpty,
      );
    });

    test('Una OpcionAncla guarda sus tres datos', () {
      const opcion = OpcionAncla(
        ancla: 3,
        numeroAColocar: 5,
        puedeSeleccionarse: true,
      );

      expect(opcion.ancla, 3);
      expect(opcion.numeroAColocar, 5);
      expect(opcion.puedeSeleccionarse, isTrue);
    });

    test('Un MovimientoAncla guarda el ancla y el destino', () {
      final tablero = Tablero();
      final movimiento = MovimientoAncla(
        ancla: tablero.obtenerCelda(0, 0),
        destino: tablero.obtenerCelda(0, 1),
      );

      expect((movimiento.ancla.x, movimiento.ancla.y), (0, 0));
      expect((movimiento.destino.x, movimiento.destino.y), (0, 1));
    });
  });
}
