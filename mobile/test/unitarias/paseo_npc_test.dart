// Prueba unitaria: cómo pasean los personajitos del menú (caminar, dar la
// vuelta en las orillas y detenerse a saludar).

import 'package:brilliant_mobile/paseo_npc.dart';
import 'package:flutter_test/flutter_test.dart';

PaseoNpc paseo({
  double x = 50,
  int direccion = 1,
  double velocidad = 20,
  double caminata = 5,
  double saludo = 2,
}) => PaseoNpc(
  x: x,
  direccion: direccion,
  velocidad: velocidad,
  duracionCaminata: caminata,
  duracionSaludo: saludo,
);

/// Avanza [segundos] en pasos de 1/20 s, como lo haría la pantalla.
void andar(
  PaseoNpc npc,
  double segundos, {
  double ancho = 300,
  double tamano = 30,
}) {
  for (var t = 0.0; t < segundos - 1e-9; t += 0.05) {
    npc.avanzar(0.05, ancho: ancho, tamano: tamano);
  }
}

void main() {
  group('Unitarias: paseo de los personajitos, caminar', () {
    test('Empieza caminando, sin saludar', () {
      final npc = paseo();

      expect(npc.saludando, isFalse);
      expect(npc.reloj, 0);
    });

    test('Hacia la derecha avanza a su velocidad', () {
      final npc = paseo(x: 50, velocidad: 20);
      andar(npc, 1);

      expect(npc.x, closeTo(70, 0.01));
    });

    test('Hacia la izquierda retrocede a su velocidad', () {
      final npc = paseo(x: 100, direccion: -1, velocidad: 20);
      andar(npc, 1);

      expect(npc.x, closeTo(80, 0.01));
    });

    test('Al llegar a la orilla derecha se da la vuelta', () {
      final npc = paseo(x: 260, velocidad: 20);
      andar(npc, 1);

      expect(npc.direccion, -1);
      expect(npc.x, lessThanOrEqualTo(270));
    });

    test('Al llegar a la orilla izquierda se da la vuelta', () {
      final npc = paseo(x: 5, direccion: -1, velocidad: 20);
      andar(npc, 1);

      expect(npc.direccion, 1);
      expect(npc.x, greaterThanOrEqualTo(0));
    });

    test('Nunca se sale de la pantalla en un paseo largo', () {
      final npc = paseo(velocidad: 60, caminata: 3);
      for (var i = 0; i < 2000; i++) {
        npc.avanzar(0.05, ancho: 200, tamano: 30);
        expect(npc.x, inInclusiveRange(0, 170));
      }
    });

    test('Va y viene: en un paseo largo camina en las dos direcciones', () {
      final npc = paseo(velocidad: 60, caminata: 100);
      final direcciones = <int>{};
      for (var i = 0; i < 400; i++) {
        npc.avanzar(0.05, ancho: 200, tamano: 30);
        direcciones.add(npc.direccion);
      }

      expect(direcciones, {1, -1});
    });

    test('Mueve las piernas al caminar', () {
      final npc = paseo();
      final pasos = <double>{};
      for (var i = 0; i < 30; i++) {
        npc.avanzar(0.05, ancho: 300, tamano: 30);
        pasos.add(npc.paso);
      }

      expect(pasos.any((p) => p > 0.5), isTrue);
      expect(pasos.any((p) => p < -0.5), isTrue);
    });

    test('El paso y el rebote siempre están en su rango', () {
      final npc = paseo();
      for (var i = 0; i < 300; i++) {
        npc.avanzar(0.05, ancho: 300, tamano: 30);
        expect(npc.paso, inInclusiveRange(-1, 1));
        expect(npc.rebote, inInclusiveRange(0, 1));
      }
    });

    test('En un espacio más angosto que él, se queda en 0', () {
      final npc = paseo(x: 10);
      andar(npc, 1, ancho: 20, tamano: 30);

      expect(npc.x, 0);
    });
  });

  group('Unitarias: paseo de los personajitos, saludar', () {
    test('Después de caminar un rato se detiene a decir ¡Hola!', () {
      final npc = paseo(caminata: 5);
      andar(npc, 4.9);
      expect(npc.saludando, isFalse);

      andar(npc, 0.2);
      expect(npc.saludando, isTrue);
      expect(PaseoNpc.saludo, '¡Hola!');
    });

    test('Mientras saluda no se mueve', () {
      final npc = paseo(caminata: 1, saludo: 2);
      andar(npc, 1.05);
      expect(npc.saludando, isTrue);
      final donde = npc.x;

      andar(npc, 1);
      expect(npc.x, donde);
    });

    test('Mientras saluda las piernas están quietas', () {
      final npc = paseo(caminata: 1);
      andar(npc, 1.05);

      expect(npc.paso, 0);
      expect(npc.rebote, 0);
    });

    test('Después de saludar sigue caminando', () {
      final npc = paseo(caminata: 1, saludo: 2);
      andar(npc, 1.05);
      andar(npc, 2.05);

      expect(npc.saludando, isFalse);
      final donde = npc.x;
      andar(npc, 0.5);
      expect(npc.x, isNot(donde));
    });

    test('Sigue en la misma dirección después de saludar', () {
      final npc = paseo(x: 50, caminata: 1, saludo: 1);
      andar(npc, 1.05);
      andar(npc, 1.05);

      expect(npc.direccion, 1);
    });

    test('Saluda una y otra vez: camina, saluda, camina, saluda', () {
      final npc = paseo(caminata: 2, saludo: 1);
      var saludos = 0;
      var antes = false;
      for (var i = 0; i < 20 * 12; i++) {
        npc.avanzar(0.05, ancho: 1000, tamano: 30);
        if (npc.saludando && !antes) saludos++;
        antes = npc.saludando;
      }

      // 12 s con ciclos de 3 s: 4 saludos.
      expect(saludos, 4);
    });

    test('El reloj vuelve a 0 al cambiar de caminar a saludar', () {
      final npc = paseo(caminata: 1);
      andar(npc, 1.05);

      expect(npc.saludando, isTrue);
      expect(npc.reloj, lessThan(0.1));
    });
  });

  group('Unitarias: paseo de los personajitos, tiempos raros', () {
    test('Un tiempo de 0 o negativo no cambia nada', () {
      final npc = paseo(x: 50);
      npc
        ..avanzar(0, ancho: 300, tamano: 30)
        ..avanzar(-3, ancho: 300, tamano: 30);

      expect(npc.x, 50);
      expect(npc.reloj, 0);
    });

    test('Un salto grande de tiempo (volver al menú) no lo teletransporta', () {
      final npc = paseo(x: 50, velocidad: 20);
      npc.avanzar(60, ancho: 1000, tamano: 30);

      expect(npc.x, closeTo(52, 0.01));
      expect(npc.saludando, isFalse);
    });

    test('Si la pantalla se achica, vuelve a quedar dentro', () {
      final npc = paseo(x: 280, caminata: 1);
      andar(npc, 1.05, ancho: 1000);
      expect(npc.saludando, isTrue);

      npc.avanzar(0.05, ancho: 200, tamano: 30);
      expect(npc.x, lessThanOrEqualTo(170));
    });
  });
}
