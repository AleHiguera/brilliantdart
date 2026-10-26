import 'package:test/test.dart';

import 'package:brilliantdart/mapa_dos.dart';
import 'package:brilliantdart/mapa_uno.dart';
import 'package:brilliantdart/tipoo.dart';

/// Cada color decide su propia regla (responsabilidad única): la clase base
/// Tipo ya no tiene un switch con las reglas de todos los colores.
void main() {
  Tipo crear(TipoZona tipo) =>
      Tipo(tipo: tipo, color: tipo.name, regla: 'regla', puntuacion: 1);

  /// Zonas llenas de ejemplo y si cada color las acepta.
  const casos = <List<int>, Map<TipoZona, bool>>{
    [3, 3, 3]: {
      TipoZona.azul: true,
      TipoZona.gris: true,
      TipoZona.rojo: false,
      TipoZona.amarillo: false,
      TipoZona.verde: true,
      TipoZona.morado: false,
      TipoZona.naranja: true,
    },
    [1, 2, 3]: {
      TipoZona.azul: false,
      TipoZona.gris: false,
      TipoZona.rojo: true,
      TipoZona.amarillo: true,
      TipoZona.verde: true,
      TipoZona.morado: false,
      TipoZona.naranja: true,
    },
    [2, 5, 2, 5]: {
      TipoZona.azul: false,
      TipoZona.gris: false,
      TipoZona.rojo: false,
      TipoZona.amarillo: false,
      TipoZona.verde: true,
      TipoZona.morado: true,
      TipoZona.naranja: true,
    },
    [4, 4, 6]: {
      TipoZona.azul: false,
      TipoZona.gris: false,
      TipoZona.rojo: false,
      TipoZona.amarillo: false,
      TipoZona.verde: true,
      TipoZona.morado: true,
      TipoZona.naranja: true,
    },
    [6]: {
      TipoZona.azul: true,
      TipoZona.gris: true,
      TipoZona.rojo: true,
      TipoZona.amarillo: true,
      TipoZona.verde: true,
      TipoZona.morado: false,
      TipoZona.naranja: true,
    },
  };

  group('Cada color valida su propia regla', () {
    for (final MapEntry(key: valores, value: esperado) in casos.entries) {
      for (final MapEntry(key: tipo, value: valido) in esperado.entries) {
        test(
          '${tipo.name} con $valores es ${valido ? 'válido' : 'inválido'}',
          () {
            expect(crear(tipo).validarMovimiento(valores), valido);
          },
        );
      }
    }

    test('Los casos cubren los 7 colores', () {
      for (final esperado in casos.values) {
        expect(esperado.keys.toSet(), TipoZona.values.toSet());
      }
    });

    test('Cada color es su propia clase', () {
      final clases = {
        for (final tipo in TipoZona.values) crear(tipo).runtimeType,
      };

      expect(clases, hasLength(TipoZona.values.length));
    });

    test('validarMovimiento no modifica la lista recibida', () {
      for (final tipo in TipoZona.values) {
        final valores = [2, 2, 5];

        crear(tipo).validarMovimiento(valores);

        expect(valores, [2, 2, 5]);
      }
    });
  });

  group('Amarillo: la regla se cumple también al validar la zona llena', () {
    test('Antes aceptaba repetidos; ahora no', () {
      expect(crear(TipoZona.amarillo).validarMovimiento([1, 1]), isFalse);
    });

    test('Mapa 1: amarillo lleno con repetidos no suma puntos', () {
      final tablero = mapaUno.crearTablero();
      final amarilla = tablero.regiones.singleWhere(
        (zona) => zona.tipo.tipo == TipoZona.amarillo,
      );

      for (final celda in amarilla.coordenadas) {
        tablero.colocarDato(celda.x, celda.y, 3);
      }

      expect(amarilla.completado, isFalse);
      expect(tablero.puntuacionPorTipo(TipoZona.amarillo), 0);
    });

    test('Mapa 2: amarillo lleno con repetidos no suma puntos', () {
      final tablero = mapaDos.crearTablero()
        ..colocarDato(1, 1, 1)
        ..colocarDato(1, 5, 2)
        ..colocarDato(3, 3, 3)
        ..colocarDato(5, 1, 4)
        ..colocarDato(5, 5, 1);

      expect(tablero.puntuacionPorTipo(TipoZona.amarillo), 0);
    });

    test('Mapa 2: amarillo lleno sin repetir sí suma 6', () {
      final tablero = mapaDos.crearTablero()
        ..colocarDato(1, 1, 1)
        ..colocarDato(1, 5, 2)
        ..colocarDato(3, 3, 3)
        ..colocarDato(5, 1, 4)
        ..colocarDato(5, 5, 5);

      expect(tablero.puntuacionPorTipo(TipoZona.amarillo), 6);
    });
  });
}
