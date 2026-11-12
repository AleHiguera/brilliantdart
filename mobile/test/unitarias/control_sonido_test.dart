// Prueba unitaria: el silencio de los sonidos, que se recuerda, y el sonido
// que lo obedece.

import 'package:brilliant_mobile/almacen_pestana.dart';
import 'package:brilliant_mobile/control_sonido.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  group('Control del sonido', () {
    test('Empieza con sonido', () {
      expect(ControlSonido().silenciado, isFalse);
    });

    test('Alternar silencia y vuelve a activar', () {
      final control = ControlSonido()..alternar();
      expect(control.silenciado, isTrue);

      control.alternar();
      expect(control.silenciado, isFalse);
    });

    test('Recuerda el silencio al volver a abrir la app', () {
      final almacen = AlmacenEnMemoria();
      ControlSonido(almacen).silenciar(true);

      expect(ControlSonido(almacen).silenciado, isTrue);
    });

    test('Y también cuando se vuelve a activar', () {
      final almacen = AlmacenEnMemoria();
      ControlSonido(almacen)
        ..silenciar(true)
        ..silenciar(false);

      expect(ControlSonido(almacen).silenciado, isFalse);
      expect(almacen.valores, isEmpty);
    });

    test('Avisa a quien escucha cuando cambia', () {
      final control = ControlSonido();
      var avisos = 0;
      control.addListener(() => avisos++);

      control.alternar();

      expect(avisos, 1);
    });

    test('Fuera del navegador el almacén duradero es de memoria', () {
      expect(AlmacenPestana.duradero(), isA<AlmacenEnMemoria>());
    });
  });

  group('Sonido silenciable', () {
    test('Con sonido, suena', () async {
      final interno = SonidoFalso();
      await SonidoSilenciable(interno, ControlSonido()).reproducir();

      expect(interno.reproducciones, 1);
    });

    test('En silencio, no suena', () async {
      final interno = SonidoFalso();
      final control = ControlSonido()..silenciar(true);

      await SonidoSilenciable(interno, control).reproducir();

      expect(interno.reproducciones, 0);
    });

    test('Al silenciarlo mientras suena, se corta', () {
      final interno = SonidoFalso();
      final control = ControlSonido();
      SonidoSilenciable(interno, control);

      control.silenciar(true);

      expect(interno.cortes, 1);
    });

    test('Al volver a activar no se corta nada', () {
      final interno = SonidoFalso();
      final control = ControlSonido()..silenciar(true);
      SonidoSilenciable(interno, control);

      control.silenciar(false);

      expect(interno.cortes, 0);
    });

    test('Al cerrarlo, se cierra el sonido y deja de escuchar', () {
      final interno = SonidoFalso();
      final control = ControlSonido();
      SonidoSilenciable(interno, control).dispose();

      control.silenciar(true);

      expect(interno.cierres, 1);
      expect(interno.cortes, 0);
    });
  });
}
