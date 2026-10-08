import 'package:test/test.dart';
import 'package:brilliantdart/bloc_valores_iniciales.dart';
import 'package:brilliantdart/tablero.dart';
import 'package:brilliantdart/tipoo.dart';
import 'package:brilliantdart/zona.dart';

void main() {
  Tipo tipoVerde() {
    return Tipo(
      tipo: TipoZona.verde,
      color: 'Verde',
      regla: 'Los numeros pueden repetirse',
      puntuacion: 4,
    );
  }

  Tipo tipoRojo() {
    return Tipo(
      tipo: TipoZona.rojo,
      color: 'Rojo',
      regla: 'Todos los numeros deben ser diferentes',
      puntuacion: 6,
    );
  }

  group('Pruebas de Tablero', () {
    test('El tablero tiene 7 filas y 7 columnas', () {
      final tablero = Tablero();

      expect(Tablero.filas, equals(7));
      expect(Tablero.columnas, equals(7));
      expect(tablero.celdas, hasLength(49));
    });

    test('Permite guardar datos en las celdas', () {
      final tablero = Tablero();

      tablero.colocarDato(0, 6, 9);
      tablero.colocarDato(6, 0, 4);

      expect(tablero.obtenerCelda(0, 6).valor, equals(9));
      expect(tablero.obtenerCelda(6, 0).valor, equals(4));
    });

    test('Extrae de derecha a izquierda y de arriba hacia abajo', () {
      final tablero = Tablero();

      tablero.colocarDato(0, 6, 1);
      tablero.colocarDato(0, 5, 2);
      tablero.colocarDato(1, 6, 3);

      final datos = tablero.extraerDatos();

      expect(datos[0], equals(1));
      expect(datos[1], equals(2));
      expect(datos[7], equals(3));
    });

    test('La extracción conserva las celdas null', () {
      final tablero = Tablero();

      final datos = tablero.extraerDatos();

      expect(datos, hasLength(49));
      expect(datos.every((dato) => dato == null), isTrue);
    });

    test('Permite guardar una región sin asignarla a cada celda', () {
      final tablero = Tablero();
      final region = Zona(
        id: 1,
        tipo: tipoVerde(),
        coordenadas: [
          tablero.obtenerCelda(0, 0),
          tablero.obtenerCelda(0, 1),
        ],
      );

      tablero.agregarRegion(region);

      expect(tablero.regiones, contains(region));
      expect(tablero.obtenerCeldasDeRegion(region), hasLength(2));
    });

    test('No permite regiones con ids duplicados', () {
      final tablero = Tablero();
      final primera = Zona(
        id: 1,
        tipo: tipoVerde(),
        coordenadas: [tablero.obtenerCelda(0, 0)],
      );
      final segunda = Zona(
        id: 1,
        tipo: tipoVerde(),
        coordenadas: [tablero.obtenerCelda(1, 0)],
      );

      tablero.agregarRegion(primera);

      expect(
        () => tablero.agregarRegion(segunda),
        throwsArgumentError,
      );
    });

    test('Rechaza coordenadas fuera del tablero', () {
      final tablero = Tablero();

      expect(
        () => tablero.obtenerCelda(7, 0),
        throwsRangeError,
      );
    });

    test('Obtiene las cuatro posiciones ortogonales de una celda central', () {
      final tablero = Tablero();
      tablero.colocarDato(2, 4, 6);

      final posiciones = tablero.obtenerPosicionesAdyacentes(3, 4);

      expect(
        posiciones.map((celda) => (celda.x + 1, celda.y + 1)),
        [(3, 5), (5, 5), (4, 4), (4, 6)],
      );
    });

    test('Rechaza un repetido en rojo y no modifica la posicion destino', () {
      final tablero = Tablero();
      final ancla = tablero.obtenerCelda(3, 1);
      final destino = tablero.obtenerCelda(2, 1);
      ancla.valor = 5;
      tablero.agregarRegion(
        Zona(
          id: 1,
          tipo: tipoRojo(),
          coordenadas: [ancla, destino],
        ),
      );

      expect(tablero.puedeColocarDato(2, 1, 5), isFalse);
      expect(tablero.puedeColocarDato(2, 1, 4), isTrue);
      expect(destino.valor, isNull);
    });

    test('No permite colocar en celdas sin zona ni fuera del tablero', () {
      final tablero = Tablero();

      expect(tablero.puedeColocarDato(0, 0, 3), isFalse);
      expect(tablero.puedeColocarDato(7, 0, 3), isFalse);
    });

    test('En una esquina solo devuelve vecinos dentro del tablero', () {
      final tablero = Tablero();

      final posiciones = tablero.obtenerPosicionesAdyacentes(0, 0);

      expect(
        posiciones.map((celda) => (celda.x + 1, celda.y + 1)),
        [(2, 1), (1, 2)],
      );
    });

    test('El juego se bloquea hasta completar las 6 celdas iniciales con 1..6 sin repetir', () {
      final tablero = Tablero();
      final bloc = BlocValoresIniciales(tablero);

      const celdasIniciales = <(int, int)>[
        (1, 3),
        (2, 6),
        (4, 2),
        (4, 5),
        (6, 3),
        (7, 5),
      ];

      expect(bloc.puedeIniciar, isFalse);

      final valoresCorrectos = [1, 2, 3, 4, 5, 6];
      for (var i = 0; i < celdasIniciales.length; i++) {
        final (fila, columna) = celdasIniciales[i];
        tablero.colocarDato(fila - 1, columna - 1, valoresCorrectos[i]);
      }

      expect(bloc.puedeIniciar, isTrue);

      tablero.colocarDato(1, 5, 1);
      expect(bloc.puedeIniciar, isFalse);
    });

    test('Mover un numero inicial despeja su posicion anterior', () {
      final tablero = Tablero();
      final bloc = BlocValoresIniciales(tablero);

      bloc.colocarValorInicial(1, 3, 4);
      bloc.colocarValorInicial(6, 3, 4);

      expect(tablero.obtenerCelda(0, 2).valor, isNull);
      expect(tablero.obtenerCelda(5, 2).valor, 4);
      expect(bloc.puedeIniciar, isFalse);
    });
  });
}