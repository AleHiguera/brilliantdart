// Prueba unitaria: lo que se guarda en la pestaña para que recargar la página
// no pierda la sesión ni la partida en juego.

import 'dart:convert';

import 'package:brilliant_mobile/almacen_pestana.dart';
import 'package:brilliant_mobile/guardado_partida.dart';
import 'package:brilliant_mobile/sesion_guardada.dart';
import 'package:brilliantdart/mapa_uno.dart';
import 'package:brilliantdart/tipoo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Almacén de la pestaña', () {
    test('Guarda, lee y borra', () {
      final almacen = AlmacenEnMemoria()..guardar('a', '1');

      expect(almacen.leer('a'), '1');
      almacen.borrar('a');
      expect(almacen.leer('a'), isNull);
    });

    test('Fuera del navegador es de memoria', () {
      expect(AlmacenPestana.deLaPestana(), isA<AlmacenEnMemoria>());
    });
  });

  group('Sesión guardada', () {
    const ana = (usuario: 'ana', nombre: 'Ana', token: 'abc');

    test('La sesión se lee igual que se guardó', () {
      final guardada = SesionGuardada(AlmacenEnMemoria())..guardarSesion(ana);

      expect(guardada.leerSesion(), ana);
    });

    test('Guardar ninguna sesión la borra', () {
      final guardada = SesionGuardada(AlmacenEnMemoria())
        ..guardarSesion(ana)
        ..guardarSesion(null);

      expect(guardada.leerSesion(), isNull);
      expect(guardada.almacen.leer(SesionGuardada.claveSesion), isNull);
    });

    test('Un texto dañado es como no tener sesión', () {
      final almacen = AlmacenEnMemoria()
        ..guardar(SesionGuardada.claveSesion, '{no es json');

      expect(SesionGuardada(almacen).leerSesion(), isNull);
    });

    test('Una sesión a la que le falta el token no sirve', () {
      final almacen = AlmacenEnMemoria()
        ..guardar(
          SesionGuardada.claveSesion,
          jsonEncode({'usuario': 'ana', 'nombre': 'Ana'}),
        );

      expect(SesionGuardada(almacen).leerSesion(), isNull);
    });

    test('Guarda y borra la partida en juego', () {
      final guardada = SesionGuardada(AlmacenEnMemoria())
        ..guardarPartida('ABC234');
      expect(guardada.leerPartida(), 'ABC234');

      guardada.guardarPartida(null);
      expect(guardada.leerPartida(), isNull);
    });

    test('Guarda y borra la sesión abandonada', () {
      final guardada = SesionGuardada(AlmacenEnMemoria())
        ..guardarTokenAbandonado('viejo');
      expect(guardada.leerTokenAbandonado(), 'viejo');

      guardada.guardarTokenAbandonado(null);
      expect(guardada.leerTokenAbandonado(), isNull);
    });
  });

  group('Partida guardada', () {
    test('Los números del tablero vuelven a sus celdas', () {
      final almacen = AlmacenEnMemoria();
      final original = mapaUno.crearTablero()
        ..colocarDato(0, 0, 3)
        ..colocarDato(6, 6, 5);
      GuardadoPartida(almacen, 'ABC234').guardarCeldas(original);

      final nuevo = mapaUno.crearTablero();
      expect(GuardadoPartida(almacen, 'ABC234').restaurarCeldas(nuevo), isTrue);

      expect(nuevo.obtenerCelda(0, 0).valor, 3);
      expect(nuevo.obtenerCelda(6, 6).valor, 5);
      expect(nuevo.celdas.where((celda) => celda.valor != null), hasLength(2));
    });

    test('Restaurar el tablero también completa sus zonas', () {
      final almacen = AlmacenEnMemoria();
      final original = mapaUno.crearTablero();
      final azul = original.regiones.firstWhere(
        (region) => region.tipo.tipo == TipoZona.azul,
      );
      for (final celda in azul.coordenadas) {
        original.colocarDato(celda.fila, celda.columna, 3);
      }
      GuardadoPartida(almacen, 'ABC234').guardarCeldas(original);

      final nuevo = mapaUno.crearTablero();
      GuardadoPartida(almacen, 'ABC234').restaurarCeldas(nuevo);

      final (fila, columna) = (
        azul.coordenadas.last.fila,
        azul.coordenadas.last.columna,
      );
      expect(nuevo.zonaCompletadaEn(fila, columna), azul.id);
    });

    test('El tablero de otra partida no se usa', () {
      final almacen = AlmacenEnMemoria();
      GuardadoPartida(
        almacen,
        'OTRA11',
      ).guardarCeldas(mapaUno.crearTablero()..colocarDato(0, 0, 3));

      final nuevo = mapaUno.crearTablero();
      expect(
        GuardadoPartida(almacen, 'ABC234').restaurarCeldas(nuevo),
        isFalse,
      );
      expect(nuevo.obtenerCelda(0, 0).valor, isNull);
    });

    test('Sin nada guardado no cambia el tablero', () {
      final nuevo = mapaUno.crearTablero();

      expect(
        GuardadoPartida(AlmacenEnMemoria(), 'ABC234').restaurarCeldas(nuevo),
        isFalse,
      );
      expect(nuevo.celdas.every((celda) => celda.valor == null), isTrue);
    });

    for (final (nombre, celdas) in [
      (
        'una fila fuera del tablero',
        [
          [7, 0, 3],
        ],
      ),
      (
        'un número que no es de dado',
        [
          [0, 0, 9],
        ],
      ),
      (
        'una celda incompleta',
        [
          [0, 0],
        ],
      ),
      (
        'un texto',
        [
          ['0', 0, 3],
        ],
      ),
    ]) {
      test('Con $nombre no se restaura nada', () {
        final almacen = AlmacenEnMemoria()
          ..guardar(
            GuardadoPartida.claveTablero,
            jsonEncode({
              'codigo': 'ABC234',
              'datos': [
                [1, 1, 2],
                ...celdas,
              ],
            }),
          );
        final nuevo = mapaUno.crearTablero();

        expect(
          GuardadoPartida(almacen, 'ABC234').restaurarCeldas(nuevo),
          isFalse,
        );
        expect(nuevo.obtenerCelda(1, 1).valor, isNull);
      });
    }

    test('Un texto dañado es como no tener nada', () {
      final almacen = AlmacenEnMemoria()
        ..guardar(GuardadoPartida.claveTablero, 'roto')
        ..guardar(GuardadoPartida.claveTurno, 'roto');
      final guardado = GuardadoPartida(almacen, 'ABC234');

      expect(guardado.restaurarCeldas(mapaUno.crearTablero()), isFalse);
      expect(guardado.leerTurno(), isNull);
    });

    test('El turno se lee igual que se guardó, con zona o sin ella', () {
      final guardado = GuardadoPartida(AlmacenEnMemoria(), 'ABC234');

      guardado.guardarTurno((ronda: 3, tableroLleno: false, zona: 4));
      expect(guardado.leerTurno(), (ronda: 3, tableroLleno: false, zona: 4));

      guardado.guardarTurno((ronda: 4, tableroLleno: true, zona: null));
      expect(guardado.leerTurno(), (ronda: 4, tableroLleno: true, zona: null));
    });

    test('El turno de otra partida no se usa', () {
      final almacen = AlmacenEnMemoria();
      GuardadoPartida(
        almacen,
        'OTRA11',
      ).guardarTurno((ronda: 2, tableroLleno: false, zona: null));

      expect(GuardadoPartida(almacen, 'ABC234').leerTurno(), isNull);
    });

    test('Borrar quita el tablero y el turno de la partida', () {
      final almacen = AlmacenEnMemoria();
      GuardadoPartida(almacen, 'ABC234')
        ..guardarCeldas(mapaUno.crearTablero()..colocarDato(0, 0, 3))
        ..guardarTurno((ronda: 1, tableroLleno: false, zona: null))
        ..borrar();

      expect(almacen.valores, isEmpty);
    });

    test('Borrar no toca lo guardado de otra partida', () {
      final almacen = AlmacenEnMemoria();
      GuardadoPartida(
        almacen,
        'OTRA11',
      ).guardarTurno((ronda: 1, tableroLleno: false, zona: null));

      GuardadoPartida(almacen, 'ABC234').borrar();

      expect(GuardadoPartida(almacen, 'OTRA11').leerTurno(), isNotNull);
    });
  });
}
