import 'package:test/test.dart';

import 'package:brilliantdart/constructor_tablero.dart';
import 'package:brilliantdart/region.dart';
import 'package:brilliantdart/tablero.dart';
import 'package:brilliantdart/tipoo.dart';

void main() {
  Tipo crear(TipoZona tipo, {int puntuacion = 3}) => Tipo(
        tipo: tipo,
        color: tipo.name,
        regla: 'Todos los numeros deben ser iguales',
        puntuacion: puntuacion,
      );

  group('Tipo gris', () {
    test('La fábrica crea un TipoGris', () {
      expect(crear(TipoZona.gris), isA<TipoGris>());
    });

    test('Recuerda que es gris', () {
      expect(crear(TipoZona.gris).tipo, TipoZona.gris);
    });

    test('Conserva color, regla y puntuación', () {
      final gris = crear(TipoZona.gris, puntuacion: 3);

      expect(gris.color, 'gris');
      expect(gris.regla, 'Todos los numeros deben ser iguales');
      expect(gris.puntuacion, 3);
    });

    test('Sus puntos por lugar son 3, 2 y 1', () {
      final gris = crear(TipoZona.gris);

      expect(gris.puntuaciones, {1: 3, 2: 2, 3: 1});
      expect(gris.calcularPuntuacion(), 3);
      expect(gris.calcularPuntuacion(2), 2);
      expect(gris.calcularPuntuacion(3), 1);
    });

    test('Un cuarto lugar no es válido', () {
      expect(() => crear(TipoZona.gris).calcularPuntuacion(4),
          throwsArgumentError);
    });

    test('Acepta cualquier número si está vacío', () {
      for (var numero = 1; numero <= 6; numero++) {
        expect(crear(TipoZona.gris).esPosibleAgregar([], numero), isTrue);
      }
    });

    test('Solo acepta el mismo número que ya tiene', () {
      final gris = crear(TipoZona.gris);

      expect(gris.esPosibleAgregar([4], 4), isTrue);
      expect(gris.esPosibleAgregar([4, 4, 4], 4), isTrue);
      for (final otro in [1, 2, 3, 5, 6]) {
        expect(gris.esPosibleAgregar([4, 4], otro), isFalse);
      }
    });

    test('Es válido solo si todos los números son iguales', () {
      final gris = crear(TipoZona.gris);

      expect(gris.validarMovimiento([]), isTrue);
      expect(gris.validarMovimiento([2]), isTrue);
      expect(gris.validarMovimiento([2, 2, 2, 2]), isTrue);
      expect(gris.validarMovimiento([2, 2, 3]), isFalse);
      expect(gris.validarMovimiento([1, 6]), isFalse);
    });

    test('Tiene la misma regla que el azul', () {
      final gris = crear(TipoZona.gris);
      final azul = crear(TipoZona.azul);
      const casos = [
        <int>[],
        [3],
        [3, 3],
        [3, 4],
        [5, 5, 5, 1],
      ];

      for (final valores in casos) {
        expect(gris.validarMovimiento(valores),
            azul.validarMovimiento(valores));
        for (var numero = 1; numero <= 6; numero++) {
          expect(gris.esPosibleAgregar(valores, numero),
              azul.esPosibleAgregar(valores, numero));
        }
      }
    });

    test('esPosibleAgregar no modifica la lista recibida', () {
      final actuales = [2, 2];

      crear(TipoZona.gris).esPosibleAgregar(actuales, 5);

      expect(actuales, [2, 2]);
    });
  });

  group('Grises separados en el tablero', () {
    // Dibujo todo verde con 3 celdas grises separadas entre sí.
    const grises = [(0, 3), (3, 0), (6, 6)];

    Tablero construir() => ConstructorTablero(
          tiposPorCelda: List.generate(
            7,
            (fila) => List.generate(
              7,
              (columna) => grises.contains((fila, columna))
                  ? TipoZona.gris
                  : TipoZona.verde,
            ),
          ),
          crearTipo: (tipo) =>
              crear(tipo, puntuacion: tipo == TipoZona.gris ? 3 : 4),
          tiposUnidos: const {TipoZona.gris},
        ).construir();

    Region zonaGris(Tablero tablero) => tablero.regiones
        .singleWhere((zona) => zona.tipo.tipo == TipoZona.gris);

    test('Todas las celdas grises forman una sola zona', () {
      final zona = zonaGris(construir());

      expect(zona.tamanoRegion, 3);
      expect(
        zona.coordenadas.map((celda) => (celda.x, celda.y)).toSet(),
        grises.toSet(),
      );
    });

    test('Si el gris no va unido, cada celda es una zona aparte', () {
      final tablero = ConstructorTablero(
        tiposPorCelda: List.generate(
          7,
          (fila) => List.generate(
            7,
            (columna) => grises.contains((fila, columna))
                ? TipoZona.gris
                : TipoZona.verde,
          ),
        ),
        crearTipo: crear,
      ).construir();

      expect(
        tablero.regiones.where((zona) => zona.tipo.tipo == TipoZona.gris),
        hasLength(3),
      );
    });

    test('Una celda gris lejana debe llevar el mismo número', () {
      final tablero = construir();
      tablero.colocarDato(0, 3, 5);

      expect(tablero.puedeColocarDato(6, 6, 5), isTrue);
      expect(tablero.puedeColocarDato(6, 6, 2), isFalse);
      expect(tablero.puedeColocarDato(3, 0, 1), isFalse);
    });

    test('Con todos los grises iguales la zona suma sus puntos', () {
      final tablero = construir();
      for (final (fila, columna) in grises) {
        tablero.colocarDato(fila, columna, 6);
      }

      expect(zonaGris(tablero).completado, isTrue);
      expect(tablero.puntuacionPorTipo(TipoZona.gris), 3);
      expect(tablero.zonasCompletadasPorTipo(TipoZona.gris), 1);
      expect(tablero.puntuacionTotal, 3);
    });

    test('Con un gris distinto la zona no suma', () {
      final tablero = construir()
        ..colocarDato(0, 3, 6)
        ..colocarDato(3, 0, 6)
        ..colocarDato(6, 6, 2);

      expect(zonaGris(tablero).completado, isFalse);
      expect(tablero.puntuacionPorTipo(TipoZona.gris), 0);
    });

    test('A falta de un gris la zona todavía no suma', () {
      final tablero = construir()
        ..colocarDato(0, 3, 6)
        ..colocarDato(3, 0, 6);

      expect(zonaGris(tablero).completado, isFalse);
      expect(tablero.puntuacionTotal, 0);
    });
  });
}
