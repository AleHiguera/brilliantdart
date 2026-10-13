import 'package:test/test.dart';

import 'package:brilliantdart/historial_dados.dart';

void main() {
  group('RegistroLanzamiento', () {
    const registro = RegistroLanzamiento(
      numeroLanzamiento: 3,
      resultadoDado1: 2,
      resultadoDado2: 5,
    );

    test('Guarda el número de lanzamiento y los dos dados', () {
      expect(registro.numeroLanzamiento, 3);
      expect(registro.resultadoDado1, 2);
      expect(registro.resultadoDado2, 5);
    });

    test('Sin acción indicada, la acción queda vacía', () {
      expect(registro.accionRealizada, isNull);
    });

    test('conAccion devuelve un registro con la acción', () {
      final conAccion = registro.conAccion('Turno pasado');

      expect(conAccion.accionRealizada, 'Turno pasado');
    });

    test('conAccion conserva el número y los dados', () {
      final conAccion = registro.conAccion('2 ancla → coloca 5');

      expect(conAccion.numeroLanzamiento, 3);
      expect(conAccion.resultadoDado1, 2);
      expect(conAccion.resultadoDado2, 5);
    });

    test('conAccion no modifica el registro original', () {
      registro.conAccion('Turno pasado');

      expect(registro.accionRealizada, isNull);
    });

    test('No se puede poner una acción dos veces', () {
      final conAccion = registro.conAccion('Turno pasado');

      expect(() => conAccion.conAccion('Otra'), throwsStateError);
    });
  });

  group('HistorialDados', () {
    test('Empieza sin lanzamientos', () {
      expect(HistorialDados().lanzamientos, isEmpty);
    });

    test('El primer lanzamiento es el número 1', () {
      final historial = HistorialDados()..registrarLanzamiento(4, 4);

      expect(historial.lanzamientos.single.numeroLanzamiento, 1);
    });

    test('Numera 20 lanzamientos seguidos sin saltos', () {
      final historial = HistorialDados();
      for (var i = 0; i < 20; i++) {
        historial.registrarLanzamiento(1, 2);
      }

      expect(
        historial.lanzamientos.map((l) => l.numeroLanzamiento).toList(),
        [for (var n = 1; n <= 20; n++) n],
      );
    });

    test('Guarda los resultados en el orden en que llegan', () {
      final historial = HistorialDados()
        ..registrarLanzamiento(6, 1)
        ..registrarLanzamiento(3, 3)
        ..registrarLanzamiento(2, 5);

      expect(
        historial.lanzamientos
            .map((l) => (l.resultadoDado1, l.resultadoDado2))
            .toList(),
        [(6, 1), (3, 3), (2, 5)],
      );
    });

    test('Los lanzamientos nuevos empiezan sin acción', () {
      final historial = HistorialDados()
        ..registrarLanzamiento(1, 1)
        ..registrarLanzamiento(2, 2);

      expect(
        historial.lanzamientos.every((l) => l.accionRealizada == null),
        isTrue,
      );
    });

    test('Se puede registrar la acción de un lanzamiento antiguo', () {
      final historial = HistorialDados()
        ..registrarLanzamiento(1, 1)
        ..registrarLanzamiento(2, 2)
        ..registrarLanzamiento(3, 3);

      historial.registrarAccion(1, 'Movimiento inválido');

      expect(historial.lanzamientos[0].accionRealizada, 'Movimiento inválido');
      expect(historial.lanzamientos[1].accionRealizada, isNull);
      expect(historial.lanzamientos[2].accionRealizada, isNull);
    });

    test('Registrar una acción no cambia la cantidad de lanzamientos', () {
      final historial = HistorialDados()..registrarLanzamiento(1, 2);

      historial.registrarAccion(1, 'Turno pasado');

      expect(historial.lanzamientos, hasLength(1));
    });

    test('Registrar una acción conserva los dados del lanzamiento', () {
      final historial = HistorialDados()..registrarLanzamiento(4, 6);

      historial.registrarAccion(1, '4 ancla → coloca 6');

      expect(historial.lanzamientos.single.resultadoDado1, 4);
      expect(historial.lanzamientos.single.resultadoDado2, 6);
    });

    test('Rechaza el lanzamiento 0 y números negativos', () {
      final historial = HistorialDados()..registrarLanzamiento(1, 1);

      expect(() => historial.registrarAccion(0, 'x'), throwsArgumentError);
      expect(() => historial.registrarAccion(-1, 'x'), throwsArgumentError);
    });

    test('Rechaza un número de lanzamiento que aún no ocurrió', () {
      final historial = HistorialDados()..registrarLanzamiento(1, 1);

      expect(() => historial.registrarAccion(2, 'x'), throwsArgumentError);
    });

    test('Una lista obtenida antes no cambia con lanzamientos nuevos', () {
      final historial = HistorialDados()..registrarLanzamiento(1, 1);
      final foto = historial.lanzamientos;

      historial.registrarLanzamiento(2, 2);

      expect(foto, hasLength(1));
      expect(historial.lanzamientos, hasLength(2));
    });

    test('No se pueden borrar lanzamientos desde fuera', () {
      final historial = HistorialDados()..registrarLanzamiento(1, 1);

      expect(() => historial.lanzamientos.clear(), throwsUnsupportedError);
      expect(() => historial.lanzamientos.removeLast(), throwsUnsupportedError);
    });

    test('Dos historiales son independientes', () {
      final primero = HistorialDados()..registrarLanzamiento(1, 1);
      final segundo = HistorialDados();

      expect(primero.lanzamientos, hasLength(1));
      expect(segundo.lanzamientos, isEmpty);
    });
  });
}
