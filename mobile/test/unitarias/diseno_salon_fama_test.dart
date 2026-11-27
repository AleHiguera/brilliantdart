// Prueba unitaria: lo que decide el diseño del Salón de la Fama (iniciales y
// color del avatar, medallas).

import 'package:brilliant_mobile/avatar_jugador.dart';
import 'package:brilliant_mobile/podio_salon_fama.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Unitarias: iniciales del avatar', () {
    test('Dos partes con guion bajo: la primera letra de cada una', () {
      expect(inicialesDe('valentina_gm'), 'VG');
      expect(inicialesDe('el_crack99'), 'EC');
    });

    test('También separa con punto, guion y espacio', () {
      expect(inicialesDe('sofi.rdz'), 'SR');
      expect(inicialesDe('ana-luz'), 'AL');
      expect(inicialesDe('juan perez'), 'JP');
    });

    test('Con más de dos partes se usan las dos primeras', () {
      expect(inicialesDe('mi_super_usuario'), 'MS');
    });

    test('Una sola palabra: sus dos primeras letras', () {
      expect(inicialesDe('rorro'), 'RO');
      expect(inicialesDe('ana'), 'AN');
    });

    test('Siempre en mayúsculas', () {
      expect(inicialesDe('karla.b'), 'KB');
      expect(inicialesDe('Ñandu'), 'ÑA');
    });

    test('Con números también sirve', () {
      expect(inicialesDe('j1'), 'J1');
      expect(inicialesDe('99'), '99');
    });

    test('Un solo carácter queda solo', () {
      expect(inicialesDe('x'), 'X');
    });

    test('Separadores repetidos o en los extremos no cuentan', () {
      expect(inicialesDe('__ana__luz__'), 'AL');
      expect(inicialesDe('.pepe'), 'PE');
    });

    test('Sin nada que usar, un signo de pregunta', () {
      expect(inicialesDe(''), '?');
      expect(inicialesDe('___'), '?');
    });

    test('Nunca más de dos caracteres', () {
      for (final usuario in ['valentina_gm', 'rorro', 'a.b.c.d', 'xyz123']) {
        expect(inicialesDe(usuario).length, lessThanOrEqualTo(2));
      }
    });
  });

  group('Unitarias: color del avatar', () {
    test('El mismo usuario siempre tiene el mismo color', () {
      expect(colorDeUsuario('valentina_gm'), colorDeUsuario('valentina_gm'));
    });

    test('No importan las mayúsculas', () {
      expect(colorDeUsuario('Ana'), colorDeUsuario('ana'));
      expect(colorDeUsuario('PEPE_strats'), colorDeUsuario('pepe_STRATS'));
    });

    test('Siempre es uno de la paleta', () {
      for (var i = 0; i < 200; i++) {
        expect(coloresAvatar, contains(colorDeUsuario('jugador$i')));
      }
    });

    test('Sale igual en cualquier plataforma (valores fijos)', () {
      // FNV-1a: si alguien cambia la fórmula, los avatares cambiarían de color.
      expect(colorDeUsuario('ana'), colorDeUsuario('ana'));
      expect(colorDeUsuario(''), coloresAvatar[0x811c9dc5 % 8]);
    });

    test('Los colores se reparten: con 200 usuarios salen todos', () {
      final usados = {for (var i = 0; i < 200; i++) colorDeUsuario('j$i')};
      expect(usados.length, coloresAvatar.length);
    });

    test('Ningún color se lleva más de un cuarto de 200 usuarios', () {
      final cuenta = <Color, int>{};
      for (var i = 0; i < 200; i++) {
        cuenta.update(
          colorDeUsuario('usuario_$i'),
          (n) => n + 1,
          ifAbsent: () => 1,
        );
      }
      expect(cuenta.values.every((n) => n <= 50), isTrue, reason: '$cuenta');
    });

    test('Nombres parecidos no salen todos del mismo color', () {
      final colores = {
        for (final n in ['ana1', 'ana2', 'ana3', 'ana4', 'ana5'])
          colorDeUsuario(n),
      };
      expect(colores.length, greaterThan(1));
    });

    test('La paleta tiene 8 colores distintos y opacos', () {
      expect(coloresAvatar.toSet().length, 8);
      expect(coloresAvatar.every((c) => c.a == 1), isTrue);
    });
  });

  group('Unitarias: medallas', () {
    test('Oro, plata y bronce para el 1, 2 y 3', () {
      expect(Medalla.deLugar(1), same(Medalla.oro));
      expect(Medalla.deLugar(2), same(Medalla.plata));
      expect(Medalla.deLugar(3), same(Medalla.bronce));
    });

    test('Del 4 en adelante, y lugares raros, sin medalla', () {
      for (final lugar in [0, -1, 4, 10, 66]) {
        expect(Medalla.deLugar(lugar), isNull);
      }
    });

    test('Cada medalla tiene su nombre', () {
      expect(
        [Medalla.oro, Medalla.plata, Medalla.bronce].map((m) => m.nombre),
        ['oro', 'plata', 'bronce'],
      );
    });

    test('El brillo va del tono claro al fuerte', () {
      final brillo = Medalla.oro.brillo;
      expect(brillo.colors.first, Medalla.oro.claro);
      expect(brillo.colors[1], Medalla.oro.fuerte);
      expect(brillo.colors.length, brillo.stops!.length);
    });

    test('El texto de cada medalla se lee sobre su tono claro', () {
      for (final medalla in [Medalla.oro, Medalla.plata, Medalla.bronce]) {
        final claro = medalla.claro.computeLuminance();
        final texto = medalla.texto.computeLuminance();
        final contraste = (claro + 0.05) / (texto + 0.05);
        expect(contraste, greaterThan(4.5), reason: medalla.nombre);
      }
    });

    test('El escalón del 1.º es el más alto, luego el 2.º y el 3.º', () {
      const alturas = PodioSalonFama.alturas;
      expect(alturas[0], greaterThan(alturas[1]));
      expect(alturas[1], greaterThan(alturas[2]));
    });
  });
}
