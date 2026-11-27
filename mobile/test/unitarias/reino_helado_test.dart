// Prueba unitaria: el tema del Reino Helado (Mapa 1), la nieve que cae y el
// copo de los números iniciales.

import 'dart:math' as math;

import 'package:brilliant_mobile/copo_progreso.dart';
import 'package:brilliant_mobile/nevada.dart';
import 'package:brilliant_mobile/paleta_atardecer.dart';
import 'package:brilliant_mobile/tema_mapa.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

bool azulado(Color color) => color.b > color.r;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Unitarias: nombres de los mapas', () {
    test('El Mapa 1 se llama Reino Helado', () {
      expect(TemaMapa.de(1).nombre, 'Reino Helado');
      expect(TemaMapa.de(1), same(TemaMapa.reinoHelado));
    });

    test('Los demás siguen llamándose Mapa N', () {
      for (final n in [2, 3, 4]) {
        expect(TemaMapa.de(n).nombre, 'Mapa $n');
        expect(TemaMapa.de(n).numero, n);
      }
    });

    test('Solo el Reino Helado tiene nombre propio', () {
      expect(TemaMapa.de(1).tieneNombrePropio, isTrue);
      for (final n in [2, 3, 4]) {
        expect(TemaMapa.de(n).tieneNombrePropio, isFalse);
      }
    });

    test('El Reino Helado sigue siendo el número 1', () {
      expect(TemaMapa.reinoHelado.numero, 1);
    });
  });

  group('Unitarias: temática del Reino Helado', () {
    test('Tiene su propio fondo, que viene dentro de la app', () async {
      final imagen = TemaMapa.reinoHelado.imagenFondo!;
      final datos = await rootBundle.load(imagen);
      expect(imagen, startsWith('assets/imagenes/'));
      expect(datos.lengthInBytes, inExclusiveRange(0, 1024 * 1024));
    });

    test('Los demás mapas no tienen fondo propio', () {
      for (final n in [2, 3, 4]) {
        expect(TemaMapa.de(n).imagenFondo, isNull);
        expect(TemaMapa.de(n).veloFondo, isNull);
      }
    });

    test('Nieva y usa el copo de nieve; los demás mapas no', () {
      expect(TemaMapa.reinoHelado.nieve, isTrue);
      expect(TemaMapa.reinoHelado.copoDeNieve, isTrue);
      for (final n in [2, 3, 4]) {
        expect(TemaMapa.de(n).nieve, isFalse);
        expect(TemaMapa.de(n).copoDeNieve, isFalse);
      }
    });

    test('Sus tarjetas son blanco hielo y su borde azul', () {
      final tema = TemaMapa.reinoHelado;
      expect(azulado(tema.tarjeta), isTrue);
      expect(tema.tarjeta.computeLuminance(), greaterThan(0.85));
      expect(azulado(tema.bordeTarjeta), isTrue);
      expect(azulado(tema.sombraTarjeta), isTrue);
    });

    test('Su barra va en azules claros', () {
      for (final color in TemaMapa.reinoHelado.barra.colors) {
        expect(azulado(color), isTrue);
        expect(color.computeLuminance(), greaterThan(0.7));
      }
    });

    test('Su tarjeta en el menú y su flecha son azules', () {
      final tema = TemaMapa.reinoHelado;
      expect(
        tema.tarjetaDestacada.colors.last.b,
        greaterThan(tema.tarjetaDestacada.colors.last.r),
      );
      for (final color in tema.botonRedondo.colors) {
        expect(azulado(color), isTrue);
      }
    });

    test('El velo deja ver bien la imagen (más ligero que el de la app)', () {
      for (final color in TemaMapa.reinoHelado.veloFondo!.colors) {
        expect(color.a, lessThan(0.35));
      }
    });

    test('Mientras carga se ve el azul de su cielo', () {
      expect(azulado(TemaMapa.reinoHelado.colorCielo), isTrue);
    });

    test('Los mapas sin temática usan la paleta de atardecer', () {
      final tema = TemaMapa.de(2);
      expect(tema.tarjeta, PaletaAtardecer.tarjeta);
      expect(tema.bordeTarjeta, PaletaAtardecer.borde);
      expect(tema.barra, PaletaAtardecer.barra);
      expect(tema.botonRedondo, PaletaAtardecer.botonRedondo);
    });
  });

  group('Unitarias: nieve', () {
    test('Hay tantos copos como se piden', () {
      expect(Nevada(cantidad: 10).copos.length, 10);
      expect(Nevada().copos.length, 36);
    });

    test('Empiezan repartidos por toda la pantalla', () {
      final nevada = Nevada(cantidad: 200);
      for (final copo in nevada.copos) {
        expect(copo.x, inInclusiveRange(0, 1));
        expect(copo.y, inInclusiveRange(0, 1));
      }
      expect(nevada.copos.any((c) => c.y < 0.3), isTrue);
      expect(nevada.copos.any((c) => c.y > 0.7), isTrue);
    });

    test('Tienen distintos tamaños y velocidades, dentro de su rango', () {
      final nevada = Nevada(cantidad: 100);
      for (final copo in nevada.copos) {
        expect(
          copo.tamano,
          inInclusiveRange(Nevada.tamanoMinimo, Nevada.tamanoMaximo),
        );
        expect(
          copo.velocidad,
          inInclusiveRange(Nevada.velocidadMinima, Nevada.velocidadMaxima),
        );
      }
      expect(nevada.copos.map((c) => c.tamano).toSet().length, greaterThan(50));
    });

    test('Con la misma semilla salen igual', () {
      final a = Nevada(semilla: 3).copos.map((c) => (c.x, c.y)).toList();
      final b = Nevada(semilla: 3).copos.map((c) => (c.x, c.y)).toList();
      expect(a, b);
    });

    test('Caen hacia abajo con el tiempo', () {
      final nevada = Nevada(cantidad: 1)..copos.single.y = 0.2;
      final copo = nevada.copos.single;
      nevada.avanzar(0.1);

      expect(copo.y, closeTo(0.2 + copo.velocidad * 0.1, 1e-9));
    });

    test('Al salir por abajo vuelven a caer desde arriba', () {
      final nevada = Nevada(cantidad: 1);
      final copo = nevada.copos.single..y = 1.049;
      for (var i = 0; i < 10; i++) {
        nevada.avanzar(0.1);
      }

      expect(copo.y, lessThan(0.2));
      expect(copo.x, inInclusiveRange(0, 1));
    });

    test('Nieva sin parar: en un minuto ninguno se pierde', () {
      final nevada = Nevada(cantidad: 50);
      for (var i = 0; i < 600; i++) {
        nevada.avanzar(0.1);
        for (final copo in nevada.copos) {
          expect(copo.y, inInclusiveRange(Nevada.arriba, Nevada.abajo));
        }
      }
      expect(nevada.copos.length, 50);
    });

    test('Se mecen de lado a lado un poquito', () {
      final copo = Nevada(cantidad: 1).copos.single;
      final posiciones = <double>[];
      final nevada = Nevada(cantidad: 1);
      for (var i = 0; i < 60; i++) {
        nevada.avanzar(0.1);
        posiciones.add(nevada.copos.single.xVisible - nevada.copos.single.x);
      }

      expect(posiciones.any((p) => p > 0.005), isTrue);
      expect(posiciones.any((p) => p < -0.005), isTrue);
      expect(
        posiciones.every((p) => p.abs() <= CopoNieve.vaiven + 1e-9),
        isTrue,
      );
      expect(copo.giro, copo.fase * 0.6);
    });

    test('Un tiempo de 0 o negativo no mueve nada', () {
      final nevada = Nevada(cantidad: 5);
      final antes = nevada.copos.map((c) => c.y).toList();
      nevada
        ..avanzar(0)
        ..avanzar(-1);

      expect(nevada.copos.map((c) => c.y).toList(), antes);
    });

    test('Un salto grande de tiempo no los hace caer de golpe', () {
      final nevada = Nevada(cantidad: 1)..copos.single.y = 0.5;
      nevada.avanzar(30);

      expect(
        nevada.copos.single.y,
        closeTo(0.5 + nevada.copos.single.velocidad * 0.1, 1e-9),
      );
    });
  });

  group('Unitarias: copo de los números iniciales', () {
    test('Sin números, ningún brazo está lleno', () {
      expect(llenadoBrazos(0), [0, 0, 0, 0, 0, 0]);
    });

    test('Con 3 números, los 3 primeros brazos llenos', () {
      expect(llenadoBrazos(3), [1, 1, 1, 0, 0, 0]);
    });

    test('Con los 6, el copo completo', () {
      expect(llenadoBrazos(6), [1, 1, 1, 1, 1, 1]);
    });

    test('Mientras se anima, el brazo que sigue va a medias', () {
      expect(llenadoBrazos(2.5), [1, 1, 0.5, 0, 0, 0]);
    });

    test('Nunca se pasa de lleno ni baja de vacío', () {
      expect(llenadoBrazos(9), [1, 1, 1, 1, 1, 1]);
      expect(llenadoBrazos(-2), [0, 0, 0, 0, 0, 0]);
    });

    test('Tiene 6 brazos, uno por número, con los colores de la rueda', () {
      expect(coloresBrazosCopo.length, 6);
      expect(coloresBrazosCopo.toSet().length, 6);
      expect(coloresBrazosCopo.first, const Color(0xFFFFEB3B));
    });

    test('El primer brazo apunta hacia arriba y se reparten parejos', () {
      expect(PintorCopoProgreso.anguloBrazo(0), closeTo(-math.pi / 2, 1e-9));
      for (var i = 1; i < 6; i++) {
        expect(
          PintorCopoProgreso.anguloBrazo(i) -
              PintorCopoProgreso.anguloBrazo(i - 1),
          closeTo(math.pi / 3, 1e-9),
        );
      }
    });

    test('Solo se vuelve a pintar si cambió el avance', () {
      expect(
        PintorCopoProgreso(2).shouldRepaint(PintorCopoProgreso(2)),
        isFalse,
      );
      expect(
        PintorCopoProgreso(2).shouldRepaint(PintorCopoProgreso(3)),
        isTrue,
      );
    });
  });
}
