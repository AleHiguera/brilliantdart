import 'package:test/test.dart';

import 'package:brilliantdart/historial_dados.dart';

void main() {
  group('HistorialDados', () {
    test('Guarda resultados en orden y asigna números consecutivos', () {
      final historial = HistorialDados();

      historial.registrarLanzamiento(2, 6);
      historial.registrarLanzamiento(4, 1);

      expect(historial.lanzamientos, hasLength(2));
      expect(
        historial.lanzamientos
            .map((lanzamiento) => (
                  lanzamiento.numeroLanzamiento,
                  lanzamiento.resultadoDado1,
                  lanzamiento.resultadoDado2,
                )),
        [(1, 2, 6), (2, 4, 1)],
      );
    });

    test('No permite modificar la lista de lanzamientos expuesta', () {
      final historial = HistorialDados()..registrarLanzamiento(3, 5);

      expect(
        () => historial.lanzamientos.clear(),
        throwsUnsupportedError,
      );
    });

    test('Guarda una acción en el lanzamiento correspondiente', () {
      final historial = HistorialDados()
        ..registrarLanzamiento(2, 5)
        ..registrarLanzamiento(3, 6);

      historial.registrarAccion(1, '5 ancla -> coloca 2');

      expect(historial.lanzamientos[0].accionRealizada, '5 ancla -> coloca 2');
      expect(historial.lanzamientos[1].accionRealizada, isNull);

      expect(
        () => historial.registrarAccion(1, 'Otra acción'),
        throwsStateError,
      );
      expect(historial.lanzamientos[0].accionRealizada, '5 ancla -> coloca 2');
    });

    test('Rechaza acciones para números de lanzamiento inexistentes', () {
      final historial = HistorialDados();

      expect(
        () => historial.registrarAccion(1, 'Pasó turno'),
        throwsArgumentError,
      );
    });
  });
}