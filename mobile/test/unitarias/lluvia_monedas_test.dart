// Prueba unitaria: la lluvia de monedas al ganar ELO, el número que cuenta y
// el sonido de las monedas.

import 'dart:io';
import 'dart:typed_data';

import 'package:brilliant_mobile/celebracion_elo.dart';
import 'package:brilliant_mobile/lluvia_monedas.dart';
import 'package:brilliant_mobile/sonidos.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void andar(LluviaMonedas lluvia, double segundos) {
  for (var t = 0.0; t < segundos - 1e-9; t += 0.02) {
    lluvia.avanzar(0.02);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Unitarias: cuántas monedas', () {
    test('Sin ganar ELO no sale ninguna', () {
      expect(LluviaMonedas.cantidadPara(0), 0);
      expect(LluviaMonedas.cantidadPara(-16), 0);
    });

    test('Ganando poco salen al menos 6', () {
      expect(LluviaMonedas.cantidadPara(1), 6);
      expect(LluviaMonedas.cantidadPara(3), 6);
    });

    test('Más ELO, más monedas', () {
      expect(
        LluviaMonedas.cantidadPara(16),
        greaterThan(LluviaMonedas.cantidadPara(4)),
      );
      expect(LluviaMonedas.cantidadPara(16), 12);
    });

    test('Nunca más de 18', () {
      expect(LluviaMonedas.cantidadPara(32), 18);
      expect(LluviaMonedas.cantidadPara(500), 18);
    });
  });

  group('Unitarias: cómo saltan las monedas', () {
    test('Hay tantas monedas como se piden, todas en el origen', () {
      final lluvia = LluviaMonedas(cantidad: 8);

      expect(lluvia.monedas.length, 8);
      for (final moneda in lluvia.monedas) {
        expect((moneda.x, moneda.y), (0.0, 0.0));
      }
    });

    test('Salen una tras otra, no todas juntas', () {
      final lluvia = LluviaMonedas(cantidad: 5);
      final retrasos = lluvia.monedas.map((m) => m.retraso).toList();

      expect(retrasos.first, 0);
      for (var i = 1; i < retrasos.length; i++) {
        expect(retrasos[i], greaterThan(retrasos[i - 1]));
      }
    });

    test('Primero saltan hacia arriba', () {
      final lluvia = LluviaMonedas(cantidad: 1);
      andar(lluvia, 0.1);

      expect(lluvia.monedas.single.y, lessThan(0));
    });

    test('Luego caen por la gravedad', () {
      final lluvia = LluviaMonedas(cantidad: 1);
      andar(lluvia, 0.2);
      final arriba = lluvia.monedas.single.y;
      andar(lluvia, 0.8);

      expect(lluvia.monedas.single.y, greaterThan(arriba));
      expect(lluvia.monedas.single.vy, greaterThan(0));
    });

    test('Se reparten a los dos lados', () {
      final lluvia = LluviaMonedas(cantidad: 18);
      andar(lluvia, 0.5);

      expect(lluvia.monedas.any((m) => m.x < -10), isTrue);
      expect(lluvia.monedas.any((m) => m.x > 10), isTrue);
    });

    test('Giran: se ven de frente y de perfil', () {
      final lluvia = LluviaMonedas(cantidad: 1);
      final anchos = <double>[];
      for (var i = 0; i < 60; i++) {
        lluvia.avanzar(0.02);
        anchos.add(lluvia.monedas.single.anchoVisible);
      }

      expect(anchos.any((a) => a > 0.9), isTrue);
      expect(anchos.any((a) => a < 0.3), isTrue);
      expect(anchos.every((a) => a >= 0 && a <= 1), isTrue);
    });

    test('Una moneda que todavía no salta no se mueve', () {
      final lluvia = LluviaMonedas(cantidad: 5);
      lluvia.avanzar(0.02);
      final ultima = lluvia.monedas.last;

      expect(ultima.enElAire, isFalse);
      expect((ultima.x, ultima.y), (0.0, 0.0));
    });

    test('Terminan: todas caen fuera de la vista en poco tiempo', () {
      final lluvia = LluviaMonedas(cantidad: 18);
      expect(lluvia.terminada, isFalse);
      andar(lluvia, LluviaMonedas.duracionMaxima);

      expect(lluvia.terminada, isTrue);
    });

    test('Nunca dura más de lo máximo', () {
      final lluvia = LluviaMonedas(cantidad: 3);
      for (var i = 0; i < 1000; i++) {
        lluvia.avanzar(0.05);
      }

      expect(
        lluvia.tiempo,
        lessThanOrEqualTo(LluviaMonedas.duracionMaxima + 0.05),
      );
    });

    test('Sin monedas ya está terminada', () {
      expect(LluviaMonedas(cantidad: 0).terminada, isTrue);
    });

    test('Un tiempo de 0 o negativo no mueve nada', () {
      final lluvia = LluviaMonedas(cantidad: 2)
        ..avanzar(0)
        ..avanzar(-1);

      expect(lluvia.tiempo, 0);
      expect(lluvia.monedas.first.y, 0);
    });

    test('Con la misma semilla saltan igual', () {
      final a = LluviaMonedas(cantidad: 4, semilla: 9);
      final b = LluviaMonedas(cantidad: 4, semilla: 9);

      expect(
        a.monedas.map((m) => (m.vx, m.vy)).toList(),
        b.monedas.map((m) => (m.vx, m.vy)).toList(),
      );
    });
  });

  group('Unitarias: el número que cuenta', () {
    test('Empieza en el ELO de antes', () {
      expect(eloContado(1000, 1016, 0), 1000);
    });

    test('Termina en el ELO nuevo', () {
      expect(eloContado(1000, 1016, 1), 1016);
    });

    test('A la mitad va a la mitad', () {
      expect(eloContado(1000, 1016, 0.5), 1008);
    });

    test('Al perder cuenta hacia abajo', () {
      expect(eloContado(40, 32, 0), 40);
      expect(eloContado(40, 32, 0.5), 36);
      expect(eloContado(40, 32, 1), 32);
    });

    test('Nunca se pasa ni se queda corto', () {
      expect(eloContado(1000, 1016, 1.4), 1016);
      expect(eloContado(1000, 1016, -0.3), 1000);
    });

    test('Siempre es un número entero entre antes y después', () {
      for (var i = 0; i <= 100; i++) {
        final valor = eloContado(0, 16, i / 100);
        expect(valor, inInclusiveRange(0, 16));
      }
    });
  });

  group('Unitarias: la nubecita triste', () {
    test('Las gotas siempre van dentro de la nube y su lluvia', () {
      for (var t = 0.0; t < 5; t += 0.07) {
        for (var i = 0; i < 3; i++) {
          expect(PintorNubeTriste.alturaGota(t, i), inInclusiveRange(0, 1));
        }
      }
    });

    test('Las gotas caen con el tiempo', () {
      expect(
        PintorNubeTriste.alturaGota(0.1, 0),
        greaterThan(PintorNubeTriste.alturaGota(0, 0)),
      );
    });

    test('Cada gota va a distinta altura', () {
      final alturas = {
        for (var i = 0; i < 3; i++) PintorNubeTriste.alturaGota(0, i),
      };
      expect(alturas.length, 3);
    });
  });

  group('Unitarias: sonido de monedas', () {
    test('Está en la carpeta de sonidos', () {
      expect(Sonido.monedas, 'sonidos/monedas.wav');
    });

    test('Viene dentro de la app y es un WAV', () async {
      final bytes = (await rootBundle.load(
        'assets/${Sonido.monedas}',
      )).buffer.asUint8List();

      expect(String.fromCharCodes(bytes.sublist(0, 4)), 'RIFF');
      expect(String.fromCharCodes(bytes.sublist(8, 12)), 'WAVE');
    });

    test('Dura poco (menos de 2 segundos) y pesa poco', () async {
      final datos = await rootBundle.load('assets/${Sonido.monedas}');
      final bytes = datos.buffer.asByteData();
      final tasa = bytes.getUint32(24, Endian.little);
      final porSegundo = bytes.getUint32(28, Endian.little);
      final segundos = (datos.lengthInBytes - 44) / porSegundo;

      expect(tasa, 22050);
      expect(segundos, inExclusiveRange(0.5, 2));
      expect(datos.lengthInBytes, lessThan(200 * 1024));
    });

    test('Tiene el mismo formato que los demás sonidos', () {
      final propio = File('assets/sonidos/monedas.wav').readAsBytesSync();
      final otro = File('assets/sonidos/tristeza.wav').readAsBytesSync();

      // Canales, tasa y bits por muestra.
      expect(propio.sublist(22, 36), otro.sublist(22, 36));
    });
  });
}
