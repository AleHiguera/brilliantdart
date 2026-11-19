// Prueba unitaria: los sonidos del juego suenan de uno en uno, en orden, sin
// encimarse.

import 'package:brilliant_mobile/cola_sonidos.dart';
import 'package:brilliant_mobile/control_sonido.dart';
import 'package:brilliant_mobile/sonidos.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

/// Un sonido que falla al intentar sonar.
class SonidoRoto extends Sonido {
  @override
  Future<void> reproducir() async => throw StateError('sin audio');
}

void main() {
  group('Unitarias: cola de sonidos', () {
    late List<String> bitacora;
    late ColaSonidos cola;

    setUp(() {
      bitacora = [];
      cola = ColaSonidos();
    });

    SonidoLento lento(String nombre) => SonidoLento(nombre, bitacora);

    test('Si no suena nada, empieza enseguida', () async {
      final festejo = lento('festejo');

      cola.tocar(festejo);
      await pumpEventQueue();

      expect(bitacora, ['empieza festejo']);
      expect(cola.sonando, isTrue);
    });

    test('El segundo espera a que termine el primero', () async {
      final festejo = lento('festejo');
      final tristeza = lento('tristeza');

      cola
        ..tocar(festejo)
        ..tocar(tristeza);
      await pumpEventQueue();
      expect(bitacora, ['empieza festejo']);
      expect(cola.pendientes, 1);

      festejo.acabar();
      await pumpEventQueue();

      expect(bitacora, [
        'empieza festejo',
        'acaba festejo',
        'empieza tristeza',
      ]);
    });

    test('Suenan en el orden en que se pidieron', () async {
      final sonidos = [lento('a'), lento('b'), lento('c')];
      sonidos.forEach(cola.tocar);

      for (final sonido in sonidos) {
        await pumpEventQueue();
        sonido.acabar();
      }
      await pumpEventQueue();

      expect(bitacora.where((p) => p.startsWith('empieza')), [
        'empieza a',
        'empieza b',
        'empieza c',
      ]);
      expect(cola.sonando, isFalse);
    });

    test('Al terminar todos, uno nuevo vuelve a sonar enseguida', () async {
      final primero = lento('primero');
      cola.tocar(primero);
      await pumpEventQueue();
      primero.acabar();
      await pumpEventQueue();

      cola.tocar(lento('otro'));
      await pumpEventQueue();

      expect(bitacora.last, 'empieza otro');
    });

    test('Uno que falla no deja sin sonar a los demás', () async {
      final despues = lento('después');

      cola
        ..tocar(SonidoRoto())
        ..tocar(despues);
      await pumpEventQueue();

      expect(bitacora, ['empieza después']);
    });

    test('Un sonido cortado deja pasar al siguiente', () async {
      final festejo = lento('festejo');
      cola
        ..tocar(festejo)
        ..tocar(lento('tristeza'));
      await pumpEventQueue();

      await festejo.detener();
      await pumpEventQueue();

      expect(bitacora, [
        'empieza festejo',
        'corta festejo',
        'empieza tristeza',
      ]);
    });

    test('Al cerrar, lo que esperaba ya no suena', () async {
      final festejo = lento('festejo');
      cola
        ..tocar(festejo)
        ..tocar(lento('tristeza'));
      await pumpEventQueue();

      cola.cerrar();
      festejo.acabar();
      await pumpEventQueue();
      cola.tocar(lento('tarde'));
      await pumpEventQueue();

      expect(bitacora, ['empieza festejo', 'acaba festejo']);
    });

    test('En silencio los sonidos pasan sin esperar', () async {
      final control = ControlSonido()..silenciar(true);
      final festejo = lento('festejo');
      final tristeza = lento('tristeza');

      cola
        ..tocar(SonidoSilenciable(festejo, control))
        ..tocar(SonidoSilenciable(tristeza, control));
      await pumpEventQueue();

      expect(bitacora, isEmpty);
      expect(cola.sonando, isFalse);
    });
  });
}
