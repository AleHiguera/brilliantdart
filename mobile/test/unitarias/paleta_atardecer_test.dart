// Prueba unitaria: la paleta de atardecer que reemplaza al blanco y negro
// sobre la imagen de fondo.

import 'package:brilliant_mobile/colores_zonas.dart';
import 'package:brilliant_mobile/paleta_atardecer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Contraste entre dos colores opacos (1 a 21), como en las pautas WCAG.
double contraste(Color a, Color b) {
  final (claro, oscuro) = a.computeLuminance() > b.computeLuminance()
      ? (a, b)
      : (b, a);
  return (claro.computeLuminance() + 0.05) / (oscuro.computeLuminance() + 0.05);
}

/// Un color translúcido puesto sobre otro, como se vería en pantalla.
Color sobre(Color arriba, Color abajo) => Color.alphaBlend(arriba, abajo);

bool calido(Color color) => color.r > color.b;

void main() {
  group('Unitarias: paleta de atardecer, tarjetas', () {
    test('Las tarjetas ya no son blancas', () {
      expect(PaletaAtardecer.tarjeta.withValues(alpha: 1), isNot(Colors.white));
      expect(colorTarjeta, PaletaAtardecer.tarjeta);
    });

    test('Las tarjetas son de un tono cálido (crema)', () {
      expect(calido(PaletaAtardecer.tarjeta), isTrue);
      expect(calido(PaletaAtardecer.cremaClaro), isTrue);
      expect(calido(PaletaAtardecer.durazno), isTrue);
    });

    test('Dejan ver un poquito el fondo, pero casi opacas para leer', () {
      for (final color in [
        PaletaAtardecer.tarjeta,
        PaletaAtardecer.cremaClaro,
        PaletaAtardecer.durazno,
      ]) {
        expect(color.a, inInclusiveRange(0.85, 0.99));
      }
    });

    test('El texto negro se lee de sobra en una tarjeta, aun sobre el '
        'verde oscuro del dibujo', () {
      const verdeOscuro = Color(0xFF2E6B2E);
      final tarjeta = sobre(PaletaAtardecer.tarjeta, verdeOscuro);
      expect(contraste(Colors.black, tarjeta), greaterThan(7));
    });

    test('El borde es durazno, no gris ni negro', () {
      expect(colorBordeTarjeta, PaletaAtardecer.borde);
      expect(calido(PaletaAtardecer.borde), isTrue);
      expect(PaletaAtardecer.borde.computeLuminance(), greaterThan(0.5));
    });

    test('La tarjeta tiene esquinas redondeadas y sombra cálida', () {
      final tarjeta = decoracionTarjeta();
      expect(tarjeta.borderRadius, BorderRadius.circular(12));
      expect(tarjeta.boxShadow!.single.color, PaletaAtardecer.sombra);
      expect(calido(PaletaAtardecer.sombra), isTrue);
      expect(PaletaAtardecer.sombra.a, lessThan(0.3));
    });

    test('La tarjeta destacada va de crema claro a durazno', () {
      expect(PaletaAtardecer.tarjetaDestacada.colors, [
        PaletaAtardecer.cremaClaro,
        PaletaAtardecer.durazno,
      ]);
      expect(
        PaletaAtardecer.cremaClaro.computeLuminance(),
        greaterThan(PaletaAtardecer.durazno.computeLuminance()),
      );
    });
  });

  group('Unitarias: paleta de atardecer, barra y botones', () {
    test('La barra va del durazno al salmón, no blanca', () {
      final colores = PaletaAtardecer.barra.colors;
      expect(colores.length, 2);
      for (final color in colores) {
        expect(color.withValues(alpha: 1), isNot(Colors.white));
        expect(calido(color), isTrue);
        expect(color.a, greaterThan(0.9));
      }
      expect(colores.first, isNot(colores.last));
    });

    test('El título negro de la barra se lee bien', () {
      for (final color in PaletaAtardecer.barra.colors) {
        expect(
          contraste(Colors.black, color.withValues(alpha: 1)),
          greaterThan(10),
        );
      }
    });

    test('La línea bajo la barra es suave', () {
      expect(PaletaAtardecer.lineaBarra.a, lessThan(0.7));
      expect(calido(PaletaAtardecer.lineaBarra), isTrue);
    });

    test('Las flechas son terracota en vez de negras', () {
      expect(PaletaAtardecer.botonRedondo.colors, [
        PaletaAtardecer.terracotaClara,
        PaletaAtardecer.terracota,
      ]);
      expect(PaletaAtardecer.terracota, isNot(Colors.black));
      expect(calido(PaletaAtardecer.terracota), isTrue);
    });

    test('La flecha blanca se ve sobre la terracota', () {
      expect(
        contraste(Colors.white, PaletaAtardecer.terracota),
        greaterThan(4.5),
      );
    });

    test(
      'Los colores fijos son opacos (solo tarjetas y barra son translúcidas)',
      () {
        expect(PaletaAtardecer.borde.a, 1);
        expect(PaletaAtardecer.terracota.a, 1);
        expect(PaletaAtardecer.terracotaClara.a, 1);
      },
    );
  });
}
