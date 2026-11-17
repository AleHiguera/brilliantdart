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

  /// Llena todas las celdas libres junto a los [valor] del tablero, así ese
  /// número ya no puede servir de ancla.
  void encerrar(Tablero tablero, int valor) {
    final anclas = tablero.celdas.where((c) => c.valor == valor).toList();
    for (final ancla in anclas) {
      for (final vecina in tablero.obtenerPosicionesAdyacentes(
        ancla.x,
        ancla.y,
      )) {
        if (vecina.valor == null) tablero.colocarDato(vecina.x, vecina.y, 5);
      }
    }
  }

  (int, int) deOpcion(OpcionAncla opcion) =>
      (opcion.ancla, opcion.numeroAColocar);

  group('Opciones jugables de los dados', () {
    test('Si las dos opciones se pueden jugar, se ofrecen las dos', () {
      final validador = ValidadorAnclas(tableroInicial());

      expect(validador.obtenerOpcionesJugables(1, 3).map(deOpcion), [
        (1, 3),
        (3, 1),
      ]);
    });

    test('Con dobles se ofrece una sola', () {
      final validador = ValidadorAnclas(tableroInicial());

      expect(validador.obtenerOpcionesJugables(2, 2).map(deOpcion), [(2, 2)]);
    });

    test('Si el ancla no tiene dónde poner el número, esa opción no sale', () {
      final tablero = tableroInicial();
      encerrar(tablero, 1);
      final validador = ValidadorAnclas(tablero);

      // El 1 está en el tablero, pero ya no tiene celdas libres al lado.
      expect(validador.puedeSerAncla(1), isTrue);
      expect(validador.obtenerOpcionesJugables(1, 3).map(deOpcion), [(3, 1)]);
    });

    test('Si el ancla no está en el tablero, esa opción no sale', () {
      final tablero = tableroInicial();
      final unos = tablero.celdas.where((c) => c.valor == 1).toList();
      for (final celda in unos) {
        tablero.colocarDato(celda.x, celda.y, null);
      }
      final validador = ValidadorAnclas(tablero);

      expect(validador.obtenerOpcionesJugables(1, 3).map(deOpcion), [(3, 1)]);
    });

    test('Si ninguna se puede jugar, no se ofrece ninguna', () {
      final tablero = tableroInicial();
      encerrar(tablero, 1);
      encerrar(tablero, 3);
      final validador = ValidadorAnclas(tablero);

      expect(validador.obtenerOpcionesJugables(1, 3), isEmpty);
    });

    test('Toda opción ofrecida tiene al menos un movimiento', () {
      final tablero = tableroInicial();
      encerrar(tablero, 4);
      final validador = ValidadorAnclas(tablero);

      for (var dado1 = 1; dado1 <= 6; dado1++) {
        for (var dado2 = 1; dado2 <= 6; dado2++) {
          for (final opcion in validador.obtenerOpcionesJugables(
            dado1,
            dado2,
          )) {
            expect(
              validador.obtenerMovimientosPosibles(opcion),
              isNotEmpty,
              reason: '($dado1, $dado2)',
            );
          }
        }
      }
    });

    test('No cambia el tablero', () {
      final tablero = tableroInicial();
      final antes = tablero.extraerDatos();

      ValidadorAnclas(tablero).obtenerOpcionesJugables(1, 3);

      expect(tablero.extraerDatos(), antes);
    });
  });
}
