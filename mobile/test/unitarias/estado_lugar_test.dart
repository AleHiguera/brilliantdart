// Prueba unitaria: qué lugares de una zona ya se ganaron, cuál sigue y cuál
// es del propio jugador, para marcarlos en la tabla de valores.

import 'package:brilliant_mobile/tabla_puntos_partida.dart';
import 'package:brilliantdart/lugares_de_zona.dart';
import 'package:brilliantdart/mapa_uno.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final amarilla = mapaUno.crearTablero().regiones.firstWhere(
    (region) => region.id == 1,
  );

  List<EstadoLugar> estados(
    Map<String, int> rondas, {
    int ronda = 9,
    String usuario = 'ana',
  }) => [
    for (var lugar = 1; lugar <= lugaresConPuntos; lugar++)
      estadoDeLugar(
        LugaresDeZona(amarilla.tipo, rondas),
        lugar,
        ronda: ronda,
        usuario: usuario,
      ),
  ];

  const siguiente = EstadoLugar.siguiente;
  const libre = EstadoLugar.libre;
  const ganado = EstadoLugar.ganado;
  const mio = EstadoLugar.mio;

  group('Estado de cada lugar', () {
    test('Zona vacía: el 1.º es el siguiente', () {
      expect(estados({}), [siguiente, libre, libre]);
    });

    test('Ejemplo de 4: cada lugar ganado se marca y avanza el siguiente', () {
      expect(estados({'pepe': 1}), [ganado, siguiente, libre]);
      expect(estados({'pepe': 1, 'luis': 2}), [ganado, ganado, siguiente]);
      expect(estados({'pepe': 1, 'luis': 2, 'eva': 3}), [
        ganado,
        ganado,
        ganado,
      ]);
    });

    test('Visto por cada uno de los que la llenaron', () {
      final rondas = {'pepe': 1, 'luis': 2, 'eva': 3};

      expect(estados(rondas, usuario: 'pepe'), [mio, ganado, ganado]);
      expect(estados(rondas, usuario: 'luis'), [ganado, mio, ganado]);
      expect(estados(rondas, usuario: 'eva'), [ganado, ganado, mio]);
    });

    test('Un empate gana un solo lugar para los dos', () {
      final rondas = {'ana': 1, 'luis': 1};

      // Ellos ya la llenaron: para ellos no hay siguiente.
      expect(estados(rondas), [mio, libre, libre]);
      expect(estados(rondas, usuario: 'luis'), [mio, libre, libre]);
      expect(estados(rondas, usuario: 'eva'), [ganado, siguiente, libre]);
    });

    test('Lo de la ronda en juego todavía se puede empatar', () {
      expect(estados({'luis': 3}, ronda: 3), [siguiente, libre, libre]);
      expect(estados({'luis': 3}, ronda: 4), [ganado, siguiente, libre]);
    });

    test('Quien ya la llenó no tiene siguiente', () {
      expect(estados({'ana': 1}).contains(siguiente), isFalse);
    });
  });
}
