import 'package:test/test.dart';
import '../lib/tablero.dart';
import '../lib/tipoo.dart';
import '../lib/zona.dart';

void main() {
  Tipo tipoVerde() {
    return Tipo(
      tipo: TipoZona.verde,
      color: 'Verde',
      regla: 'Los numeros pueden repetirse',
      puntuacion: 4,
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
  });
}