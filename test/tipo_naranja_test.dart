import 'package:test/test.dart';

import 'package:brilliantdart/constructor_tablero.dart';
import 'package:brilliantdart/dibujo_mapa.dart';
import 'package:brilliantdart/mapa_dos.dart';
import 'package:brilliantdart/mapa_tres.dart';
import 'package:brilliantdart/mapa_uno.dart';
import 'package:brilliantdart/tablero.dart';
import 'package:brilliantdart/tipoo.dart';

void main() {
  TipoNaranja naranja({int minimo = 1, int maximo = 6}) => TipoNaranja(
    color: 'Naranja',
    regla: 'Solo números del $minimo al $maximo',
    puntuacion: 6,
    minimo: minimo,
    maximo: maximo,
  );

  group('Tipo naranja', () {
    test('La fábrica crea un TipoNaranja', () {
      final tipo = Tipo(
        tipo: TipoZona.naranja,
        color: 'Naranja',
        regla: 'regla',
        puntuacion: 6,
      );

      expect(tipo, isA<TipoNaranja>());
      expect(tipo.tipo, TipoZona.naranja);
    });

    test('Sin rango acepta del 1 al 6', () {
      final tipo = naranja();

      expect(tipo.minimo, 1);
      expect(tipo.maximo, 6);
      for (var numero = 1; numero <= 6; numero++) {
        expect(tipo.esPosibleAgregar([], numero), isTrue);
      }
    });

    test('Conserva color, regla y puntuación', () {
      final tipo = naranja(minimo: 4, maximo: 6);

      expect(tipo.color, 'Naranja');
      expect(tipo.regla, 'Solo números del 4 al 6');
      expect(tipo.puntuacion, 6);
    });

    test('Sus puntos por lugar son 6, 4 y 3', () {
      final tipo = naranja();

      expect(tipo.puntuaciones, {1: 6, 2: 4, 3: 3});
      expect(tipo.calcularPuntuacion(), 6);
    });

    test('Un rango al revés es un error', () {
      expect(() => naranja(minimo: 5, maximo: 2), throwsArgumentError);
    });

    test('Un rango fuera del 1 al 6 es un error', () {
      expect(() => naranja(minimo: 0, maximo: 3), throwsArgumentError);
      expect(() => naranja(minimo: 4, maximo: 7), throwsArgumentError);
    });

    test('Un rango de un solo número es válido', () {
      final tipo = naranja(minimo: 5, maximo: 5);

      expect(tipo.esPosibleAgregar([], 5), isTrue);
      expect(tipo.esPosibleAgregar([], 4), isFalse);
    });
  });

  group('Naranja del 4 al 6 (el de arriba del Mapa 4)', () {
    final alto = naranja(minimo: 4, maximo: 6);

    test('Acepta 4, 5 y 6', () {
      for (final numero in [4, 5, 6]) {
        expect(alto.esPosibleAgregar([], numero), isTrue);
      }
    });

    test('Rechaza 1, 2 y 3', () {
      for (final numero in [1, 2, 3]) {
        expect(alto.esPosibleAgregar([], numero), isFalse);
      }
    });

    test('Se pueden repetir números', () {
      expect(alto.esPosibleAgregar([4, 4, 4], 4), isTrue);
    });

    test('Cuatro 4 y tres 6, sin ningún 5, es válido', () {
      expect(alto.validarMovimiento([4, 4, 4, 4, 6, 6, 6]), isTrue);
    });

    test('Todos iguales es válido', () {
      expect(alto.validarMovimiento([5, 5, 5, 5, 5, 5, 5]), isTrue);
    });

    test('Un solo número fuera del rango lo hace inválido', () {
      expect(alto.validarMovimiento([4, 4, 4, 4, 6, 6, 3]), isFalse);
    });
  });

  group('Naranja del 1 al 3 (el de abajo del Mapa 4)', () {
    final bajo = naranja(minimo: 1, maximo: 3);

    test('Acepta 1, 2 y 3', () {
      for (final numero in [1, 2, 3]) {
        expect(bajo.esPosibleAgregar([], numero), isTrue);
      }
    });

    test('Rechaza 4, 5 y 6', () {
      for (final numero in [4, 5, 6]) {
        expect(bajo.esPosibleAgregar([], numero), isFalse);
      }
    });

    test('Repetidos y sin todos los números es válido', () {
      expect(bajo.validarMovimiento([1, 1, 1, 3, 3, 3, 3]), isTrue);
    });

    test('Un 6 lo hace inválido', () {
      expect(bajo.validarMovimiento([1, 2, 3, 1, 2, 3, 6]), isFalse);
    });

    test('esPosibleAgregar no modifica la lista recibida', () {
      final actuales = [1, 2];

      bajo.esPosibleAgregar(actuales, 3);

      expect(actuales, [1, 2]);
    });
  });

  group('Naranja en el tablero', () {
    /// Tablero todo verde con la fila de arriba naranja del 4 al 6.
    late Tablero tablero;
    setUp(
      () => tablero = ConstructorTablero(
        tiposPorCelda: leerDibujo([
          'NNNNNNN',
          for (var fila = 0; fila < 6; fila++) 'VVVVVVV',
        ]),
        crearTipo: (tipo) => tipo == TipoZona.naranja
            ? naranja(minimo: 4, maximo: 6)
            : Tipo(tipo: tipo, color: 'Verde', regla: 'libre', puntuacion: 3),
      ).construir(),
    );

    test('La fila naranja es una zona de 7', () {
      final zona = tablero.regiones.singleWhere(
        (zona) => zona.tipo.tipo == TipoZona.naranja,
      );

      expect(zona.tamanoRegion, 7);
    });

    test('Solo deja colocar números del rango', () {
      expect(tablero.puedeColocarDato(0, 0, 4), isTrue);
      expect(tablero.puedeColocarDato(0, 0, 2), isFalse);
    });

    test('Llena con 4 y 6 suma sus puntos', () {
      for (var columna = 0; columna < 7; columna++) {
        tablero.colocarDato(0, columna, columna < 4 ? 4 : 6);
      }

      expect(tablero.puntuacionPorTipo(TipoZona.naranja), 6);
    });
  });

  group('Los mapas sin naranja', () {
    test('La letra N es naranja', () {
      expect(letrasDeColores['N'], TipoZona.naranja);
    });

    test('Los mapas 1, 2 y 3 no tienen naranja', () {
      for (final mapa in [mapaUno, mapaDos, mapaTres]) {
        expect(mapa.tiposPresentes, isNot(contains(TipoZona.naranja)));
        expect(() => mapa.crearTipo(TipoZona.naranja), throwsArgumentError);
      }
    });
  });
}
