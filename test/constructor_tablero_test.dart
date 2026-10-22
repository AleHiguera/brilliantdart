import 'package:test/test.dart';

import 'package:brilliantdart/constructor_tablero.dart';
import 'package:brilliantdart/mapa_uno.dart';
import 'package:brilliantdart/region.dart';
import 'package:brilliantdart/tablero.dart';
import 'package:brilliantdart/tipoo.dart';

void main() {
  Tipo tipoDePrueba(TipoZona tipo) =>
      Tipo(tipo: tipo, color: tipo.name, regla: 'regla', puntuacion: 1);

  /// Dibujo de 7x7 donde [colorEn] decide el color de cada celda.
  List<List<TipoZona>> dibujo(
    TipoZona Function(int fila, int columna) colorEn,
  ) =>
      List.generate(7, (fila) => List.generate(7, (col) => colorEn(fila, col)));

  Tablero construir(
    List<List<TipoZona>> tipos, {
    Set<TipoZona> unidos = const {},
  }) => ConstructorTablero(
    tiposPorCelda: tipos,
    crearTipo: tipoDePrueba,
    tiposUnidos: unidos,
  ).construir();

  Set<(int, int)> posiciones(Region zona) =>
      zona.coordenadas.map((celda) => (celda.x, celda.y)).toSet();

  group('ConstructorTablero', () {
    test('Un dibujo de un solo color forma una única zona de 49 celdas', () {
      final tablero = construir(dibujo((_, _) => TipoZona.verde));

      expect(tablero.regiones, hasLength(1));
      expect(tablero.regiones.single.tamanoRegion, 49);
      expect(tablero.regiones.single.tipo.tipo, TipoZona.verde);
    });

    test('Dos mitades de distinto color forman dos zonas', () {
      final tablero = construir(
        dibujo((_, columna) => columna < 3 ? TipoZona.verde : TipoZona.rojo),
      );

      expect(tablero.regiones, hasLength(2));
      expect(tablero.regiones[0].tipo.tipo, TipoZona.verde);
      expect(tablero.regiones[0].tamanoRegion, 21);
      expect(tablero.regiones[1].tipo.tipo, TipoZona.rojo);
      expect(tablero.regiones[1].tamanoRegion, 28);
    });

    test('Dos bloques del mismo color separados son zonas distintas', () {
      final tablero = construir(
        dibujo((_, columna) => columna == 3 ? TipoZona.rojo : TipoZona.verde),
      );

      final verdes = tablero.regiones.where(
        (zona) => zona.tipo.tipo == TipoZona.verde,
      );
      expect(verdes, hasLength(2));
      expect(verdes.map((zona) => zona.tamanoRegion), [21, 21]);
    });

    test('Las celdas en diagonal no se unen', () {
      final tablero = construir(
        dibujo(
          (fila, columna) =>
              (fila, columna) == (0, 0) || (fila, columna) == (1, 1)
              ? TipoZona.rojo
              : TipoZona.verde,
        ),
      );

      final rojas = tablero.regiones.where(
        (zona) => zona.tipo.tipo == TipoZona.rojo,
      );
      expect(rojas, hasLength(2));
    });

    test('Un color unido junta todas sus celdas aunque estén separadas', () {
      bool esEsquina(int fila, int columna) =>
          (fila == 0 || fila == 6) && (columna == 0 || columna == 6);
      final tipos = dibujo(
        (fila, columna) =>
            esEsquina(fila, columna) ? TipoZona.amarillo : TipoZona.verde,
      );

      final unido = construir(tipos, unidos: {TipoZona.amarillo});
      final amarillas = unido.regiones
          .where((zona) => zona.tipo.tipo == TipoZona.amarillo)
          .toList();
      expect(amarillas, hasLength(1));
      expect(posiciones(amarillas.single), {(0, 0), (0, 6), (6, 0), (6, 6)});

      final separado = construir(tipos);
      expect(
        separado.regiones.where((zona) => zona.tipo.tipo == TipoZona.amarillo),
        hasLength(4),
      );
    });

    test('Dos colores unidos no se mezclan entre sí', () {
      final tipos = dibujo(
        (fila, columna) => switch ((fila, columna)) {
          (0, 0) || (6, 6) => TipoZona.amarillo,
          (0, 6) || (6, 0) => TipoZona.azul,
          _ => TipoZona.verde,
        },
      );

      final tablero = construir(
        tipos,
        unidos: {TipoZona.amarillo, TipoZona.azul},
      );

      final amarilla = tablero.regiones.singleWhere(
        (zona) => zona.tipo.tipo == TipoZona.amarillo,
      );
      final azul = tablero.regiones.singleWhere(
        (zona) => zona.tipo.tipo == TipoZona.azul,
      );
      expect(posiciones(amarilla), {(0, 0), (6, 6)});
      expect(posiciones(azul), {(0, 6), (6, 0)});
    });

    test('Los ids empiezan en 1 y van seguidos', () {
      final tablero = construir(dibujo((fila, _) => TipoZona.values[fila % 5]));

      expect(tablero.regiones.map((zona) => zona.id).toList(), [
        for (var id = 1; id <= tablero.regiones.length; id++) id,
      ]);
    });

    test('La primera zona es la de la celda de arriba a la izquierda', () {
      final tablero = construir(
        dibujo(
          (fila, columna) =>
              (fila, columna) == (0, 0) ? TipoZona.morado : TipoZona.verde,
        ),
      );

      expect(tablero.regiones.first.id, 1);
      expect(posiciones(tablero.regiones.first), {(0, 0)});
    });

    test('Cada zona recibe el tipo del color de sus celdas', () {
      final tipos = mapaUno.tiposPorCelda;
      final tablero = construir(tipos, unidos: {TipoZona.amarillo});

      for (final zona in tablero.regiones) {
        for (final celda in zona.coordenadas) {
          expect(tipos[celda.x][celda.y], zona.tipo.tipo);
        }
      }
    });

    test('Cada celda queda en exactamente una zona', () {
      final tablero = construir(
        mapaUno.tiposPorCelda,
        unidos: {TipoZona.amarillo},
      );

      for (final celda in tablero.celdas) {
        expect(
          tablero.regiones.where(
            (zona) => zona.contieneCoordenada(celda.x, celda.y),
          ),
          hasLength(1),
        );
      }
    });

    test('Las zonas usan las mismas celdas del tablero', () {
      final tablero = construir(dibujo((_, _) => TipoZona.verde));

      for (final celda in tablero.regiones.single.coordenadas) {
        expect(
          identical(celda, tablero.obtenerCelda(celda.x, celda.y)),
          isTrue,
        );
      }
    });

    test('Usa la función crearTipo para cada zona', () {
      final pedidos = <TipoZona>[];
      ConstructorTablero(
        tiposPorCelda: dibujo(
          (_, columna) => columna < 3 ? TipoZona.azul : TipoZona.rojo,
        ),
        crearTipo: (tipo) {
          pedidos.add(tipo);
          return tipoDePrueba(tipo);
        },
      ).construir();

      expect(pedidos, [TipoZona.azul, TipoZona.rojo]);
    });

    test('Cada llamada crea un tablero nuevo e independiente', () {
      final constructor = ConstructorTablero(
        tiposPorCelda: dibujo((_, _) => TipoZona.verde),
        crearTipo: tipoDePrueba,
      );

      final primero = constructor.construir()..colocarDato(0, 0, 4);
      final segundo = constructor.construir();

      expect(identical(primero, segundo), isFalse);
      expect(segundo.obtenerCelda(0, 0).valor, isNull);
    });

    test('Rechaza un dibujo con menos de 7 filas', () {
      final tipos = dibujo((_, _) => TipoZona.verde).sublist(0, 6);

      expect(() => construir(tipos), throwsArgumentError);
    });

    test('Rechaza un dibujo con una fila de otro largo', () {
      final tipos = dibujo((_, _) => TipoZona.verde);
      tipos[3] = [...tipos[3], TipoZona.verde];

      expect(() => construir(tipos), throwsArgumentError);
    });

    test('Con el dibujo del mapa uno da las mismas zonas que MapaUno', () {
      final esperado = mapaUno.crearTablero();
      final construido = construir(
        mapaUno.tiposPorCelda,
        unidos: {TipoZona.amarillo},
      );

      expect(construido.regiones, hasLength(esperado.regiones.length));
      for (var i = 0; i < esperado.regiones.length; i++) {
        expect(construido.regiones[i].id, esperado.regiones[i].id);
        expect(
          construido.regiones[i].tipo.tipo,
          esperado.regiones[i].tipo.tipo,
        );
        expect(
          posiciones(construido.regiones[i]),
          posiciones(esperado.regiones[i]),
        );
      }
    });
  });
}
