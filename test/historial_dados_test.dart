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
  });
}