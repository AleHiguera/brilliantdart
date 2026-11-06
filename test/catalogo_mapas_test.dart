import 'package:brilliantdart/catalogo_mapas.dart';
import 'package:brilliantdart/mapa_tres.dart';
import 'package:test/test.dart';

void main() {
  group('Catálogo de mapas', () {
    test('Ofrece los mapas del 1 al 4 en orden', () {
      expect(mapasDisponibles.map((mapa) => mapa.numero), [1, 2, 3, 4]);
    });

    test('Encuentra un mapa por su número', () {
      expect(mapaNumero(3), same(mapaTres));
    });

    test('Un número sin mapa es un error', () {
      expect(() => mapaNumero(5), throwsStateError);
    });
  });
}
