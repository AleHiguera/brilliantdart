import 'package:test/test.dart';

import 'package:brilliantdart/bloc_valores_iniciales.dart';
import 'package:brilliantdart/mapa.dart';
import 'package:brilliantdart/mapa_uno.dart';
import 'package:brilliantdart/tipoo.dart';

/// Mapa inventado solo para las pruebas: todo verde salvo una fila roja, con
/// celdas iniciales distintas a las del Mapa 1.
class MapaDePrueba extends Mapa {
  const MapaDePrueba();

  @override
  int get numero => 99;

  @override
  List<List<TipoZona>> get tiposPorCelda => List.generate(
    7,
    (fila) => List.filled(7, fila == 3 ? TipoZona.rojo : TipoZona.verde),
  );

  @override
  List<(int, int)> get celdasIniciales => const [
    (1, 1),
    (1, 3),
    (1, 5),
    (7, 1),
    (7, 3),
    (7, 5),
  ];

  @override
  Set<TipoZona> get tiposUnidos => const {};

  @override
  Tipo crearTipo(TipoZona tipo) =>
      Tipo(tipo: tipo, color: tipo.name, regla: 'prueba', puntuacion: 10);
}

void main() {
  group('Mapa uno como Mapa', () {
    test('mapaUno es un Mapa', () {
      expect(mapaUno, isA<Mapa>());
    });

    test('Es el mapa número 1', () {
      expect(mapaUno.numero, 1);
    });

    test('Su dibujo es de 7 por 7', () {
      expect(mapaUno.tiposPorCelda, hasLength(7));
      for (final fila in mapaUno.tiposPorCelda) {
        expect(fila, hasLength(7));
      }
    });

    test('tipoEn devuelve el color de cada celda del dibujo', () {
      for (var fila = 0; fila < 7; fila++) {
        for (var columna = 0; columna < 7; columna++) {
          expect(
            mapaUno.tipoEn(fila, columna),
            mapaUno.tiposPorCelda[fila][columna],
          );
        }
      }
    });

    test('Tiene las 6 celdas iniciales de siempre', () {
      expect(mapaUno.celdasIniciales, [
        (1, 3),
        (2, 6),
        (4, 2),
        (4, 5),
        (6, 3),
        (7, 5),
      ]);
    });

    test('Solo el amarillo va unido', () {
      expect(mapaUno.tiposUnidos, {TipoZona.amarillo});
    });

    test('Cada color tiene la regla de su tipo', () {
      for (final tipo in TipoZona.values) {
        expect(mapaUno.crearTipo(tipo).tipo, tipo);
      }
    });

    test('Puntos: amarillo 8, verde 4, morado 6, azul 7 y rojo 6', () {
      expect(mapaUno.crearTipo(TipoZona.amarillo).puntuacion, 8);
      expect(mapaUno.crearTipo(TipoZona.verde).puntuacion, 4);
      expect(mapaUno.crearTipo(TipoZona.morado).puntuacion, 6);
      expect(mapaUno.crearTipo(TipoZona.azul).puntuacion, 7);
      expect(mapaUno.crearTipo(TipoZona.rojo).puntuacion, 6);
    });

    test('crearTablero entrega un tablero nuevo cada vez', () {
      final primero = mapaUno.crearTablero()..colocarDato(0, 0, 3);
      final segundo = mapaUno.crearTablero();

      expect(primero.obtenerCelda(0, 0).valor, 3);
      expect(segundo.obtenerCelda(0, 0).valor, isNull);
    });

    test('const MapaUno() es el mismo objeto que mapaUno', () {
      expect(identical(const MapaUno(), mapaUno), isTrue);
    });
  });

  group('Cualquier Mapa funciona con el resto del juego', () {
    const mapa = MapaDePrueba();

    test('Arma su tablero con sus propias zonas', () {
      final tablero = mapa.crearTablero();

      expect(tablero.regiones, hasLength(3));
      expect(tablero.regiones.map((zona) => zona.tipo.tipo).toList(), [
        TipoZona.verde,
        TipoZona.rojo,
        TipoZona.verde,
      ]);
    });

    test('Usa sus propios puntos', () {
      final tablero = mapa.crearTablero();

      for (final zona in tablero.regiones) {
        expect(zona.tipo.puntuacion, 10);
      }
    });

    test('Su máximo de puntos es la suma de sus zonas', () {
      final maximo = mapa.crearTablero().regiones.fold(
        0,
        (total, zona) => total + zona.tipo.puntuacion,
      );

      expect(maximo, 30);
    });

    test('El bloc acepta sus celdas iniciales', () {
      final tablero = mapa.crearTablero();
      final bloc = BlocValoresIniciales(
        tablero,
        celdasIniciales: mapa.celdasIniciales,
      );

      for (var i = 0; i < 6; i++) {
        final (fila, columna) = mapa.celdasIniciales[i];
        bloc.colocarValorInicial(fila, columna, i + 1);
      }

      expect(bloc.puedeIniciar, isTrue);
      expect(bloc.obtenerValoresIniciales(), [1, 2, 3, 4, 5, 6]);
    });

    test('El bloc rechaza las celdas del Mapa 1 si no son de este mapa', () {
      final bloc = BlocValoresIniciales(
        mapa.crearTablero(),
        celdasIniciales: mapa.celdasIniciales,
      );

      expect(() => bloc.colocarValorInicial(2, 6, 1), throwsArgumentError);
    });
  });
}
