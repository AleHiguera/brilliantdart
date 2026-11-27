// Prueba unitaria: el tema del Reino del Fuego (Mapa 2), las brasas que suben
// y la llama de los números iniciales.

import 'package:flutter/material.dart';

import 'package:brilliant_mobile/chispas.dart';
import 'package:brilliant_mobile/chispas_subiendo.dart';
import 'package:brilliant_mobile/copo_progreso.dart';
import 'package:brilliant_mobile/llama_progreso.dart';
import 'package:brilliant_mobile/tema_mapa.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';

bool calido(Color color) => color.r > color.b;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Unitarias: Reino del Fuego, nombre y temática', () {
    test('El Mapa 2 se llama Reino del Fuego', () {
      expect(TemaMapa.de(2).nombre, 'Reino del Fuego');
      expect(TemaMapa.de(2), same(TemaMapa.reinoDelFuego));
      expect(TemaMapa.reinoDelFuego.numero, 2);
      expect(TemaMapa.reinoDelFuego.tieneNombrePropio, isTrue);
    });

    test('Tiene su propio fondo, que viene dentro de la app', () async {
      final imagen = TemaMapa.reinoDelFuego.imagenFondo!;
      final datos = await rootBundle.load(imagen);

      expect(imagen, 'assets/imagenes/fondo_reino_fuego.jpg');
      expect(datos.lengthInBytes, inExclusiveRange(0, 1024 * 1024));
    });

    test('Suben brasas y usa la llama; no nieve ni copo', () {
      final tema = TemaMapa.reinoDelFuego;
      expect(tema.particulas, ParticulasMapa.brasas);
      expect(tema.brasas, isTrue);
      expect(tema.nieve, isFalse);
      expect(tema.indicador, IndicadorIniciales.llama);
      expect(tema.llama, isTrue);
      expect(tema.copoDeNieve, isFalse);
    });

    test('El Reino Helado sigue con nieve y copo, sin brasas ni llama', () {
      final tema = TemaMapa.reinoHelado;
      expect(tema.nieve, isTrue);
      expect(tema.brasas, isFalse);
      expect(tema.copoDeNieve, isTrue);
      expect(tema.llama, isFalse);
    });

    test('Los mapas 3 y 4 no tienen partículas y usan la rueda', () {
      for (final n in [3, 4]) {
        expect(TemaMapa.de(n).particulas, ParticulasMapa.ninguna);
        expect(TemaMapa.de(n).indicador, IndicadorIniciales.rueda);
        expect(TemaMapa.de(n).icono, isNull);
      }
    });

    test('Su icono en el menú es una llama naranja', () {
      expect(TemaMapa.reinoDelFuego.icono, Icons.local_fire_department);
      expect(TemaMapa.reinoDelFuego.colorIcono, ColoresFuego.naranja);
      expect(TemaMapa.reinoHelado.icono, Icons.ac_unit);
    });

    test('Sus tarjetas, bordes, barra y flecha son de tonos de fuego', () {
      final tema = TemaMapa.reinoDelFuego;
      for (final color in [
        tema.tarjeta,
        tema.bordeTarjeta,
        tema.sombraTarjeta,
        tema.lineaBarra,
        ...tema.barra.colors,
        ...tema.botonRedondo.colors,
        ...tema.tarjetaDestacada.colors,
      ]) {
        expect(calido(color), isTrue, reason: '$color');
      }
    });

    test('Las tarjetas son claras y casi opacas para leerse sobre el rojo', () {
      final tarjeta = TemaMapa.reinoDelFuego.tarjeta;
      expect(tarjeta.computeLuminance(), greaterThan(0.8));
      expect(tarjeta.a, greaterThan(0.9));
    });

    test('El título negro se lee bien en su barra', () {
      for (final color in TemaMapa.reinoDelFuego.barra.colors) {
        final opaco = color.withValues(alpha: 1);
        final contraste = (opaco.computeLuminance() + 0.05) / 0.05;
        expect(contraste, greaterThan(10));
      }
    });

    test('El velo es ligero: el dibujo se ve tal cual', () {
      for (final color in TemaMapa.reinoDelFuego.veloFondo!.colors) {
        expect(color.a, lessThan(0.2));
      }
    });

    test('Mientras carga se ve el rojo de su cielo', () {
      final cielo = TemaMapa.reinoDelFuego.colorCielo;
      expect(cielo.r, greaterThan(cielo.g));
      expect(cielo.r, greaterThan(cielo.b));
    });
  });

  group('Unitarias: brasas', () {
    test('Hay tantas como se piden, repartidas por toda la pantalla', () {
      final chispas = Chispas(cantidad: 200);
      expect(chispas.chispas.length, 200);
      for (final chispa in chispas.chispas) {
        expect(chispa.x, inInclusiveRange(0, 1));
        expect(chispa.y, inInclusiveRange(0, 1));
        expect(
          chispa.tamano,
          inInclusiveRange(Chispas.tamanoMinimo, Chispas.tamanoMaximo),
        );
        expect(
          chispa.velocidad,
          inInclusiveRange(Chispas.velocidadMinima, Chispas.velocidadMaxima),
        );
      }
      expect(Chispas().chispas.length, 30);
    });

    test('Suben con el tiempo', () {
      final chispas = Chispas(cantidad: 1)..chispas.single.y = 0.6;
      final chispa = chispas.chispas.single;
      chispas.avanzar(0.1);

      expect(chispa.y, closeTo(0.6 - chispa.velocidad * 0.1, 1e-9));
    });

    test('Al salir por arriba vuelven a salir desde abajo', () {
      final chispas = Chispas(cantidad: 1);
      final chispa = chispas.chispas.single..y = -0.049;
      for (var i = 0; i < 5; i++) {
        chispas.avanzar(0.1);
      }

      expect(chispa.y, greaterThan(0.9));
      expect(chispa.x, inInclusiveRange(0, 1));
    });

    test('Nunca se pierden: en un minuto siguen todas en su rango', () {
      final chispas = Chispas(cantidad: 40);
      for (var i = 0; i < 600; i++) {
        chispas.avanzar(0.1);
        for (final chispa in chispas.chispas) {
          expect(chispa.y, inInclusiveRange(Chispas.arriba, Chispas.abajo));
        }
      }
      expect(chispas.chispas.length, 40);
    });

    test('Titilan: el brillo sube y baja, siempre entre 0.35 y 1', () {
      final chispas = Chispas(cantidad: 1);
      final brillos = <double>[];
      for (var i = 0; i < 60; i++) {
        chispas.avanzar(0.05);
        brillos.add(chispas.chispas.single.brillo);
      }

      expect(brillos.any((b) => b > 0.9), isTrue);
      expect(brillos.any((b) => b < 0.5), isTrue);
      expect(brillos.every((b) => b >= 0.35 - 1e-9 && b <= 1 + 1e-9), isTrue);
    });

    test('Se mecen de lado a lado un poquito', () {
      final chispas = Chispas(cantidad: 1);
      final desvios = <double>[];
      for (var i = 0; i < 80; i++) {
        chispas.avanzar(0.1);
        final chispa = chispas.chispas.single;
        desvios.add(chispa.xVisible - chispa.x);
      }

      expect(desvios.any((d) => d > 0.005), isTrue);
      expect(desvios.any((d) => d < -0.005), isTrue);
      expect(desvios.every((d) => d.abs() <= Chispa.vaiven + 1e-9), isTrue);
    });

    test('Abajo están calientes y arriba se enfrían', () {
      final abajo = Chispa(x: 0.5, y: 1, tamano: 2, velocidad: 0.1, fase: 0);
      final arriba = Chispa(x: 0.5, y: 0, tamano: 2, velocidad: 0.1, fase: 0);

      expect(abajo.enfriamiento, 0);
      expect(arriba.enfriamiento, 1);
    });

    test('Su color va de amarillo a naranja a rojo', () {
      expect(PintorChispas.colorPara(0), PintorChispas.caliente);
      expect(PintorChispas.colorPara(0.5), PintorChispas.tibia);
      expect(PintorChispas.colorPara(1), PintorChispas.fria);
      for (var e = 0.0; e <= 1; e += 0.1) {
        expect(calido(PintorChispas.colorPara(e)), isTrue);
      }
    });

    test('Un tiempo de 0 o negativo no las mueve', () {
      final chispas = Chispas(cantidad: 5);
      final antes = chispas.chispas.map((c) => c.y).toList();
      chispas
        ..avanzar(0)
        ..avanzar(-2);

      expect(chispas.chispas.map((c) => c.y).toList(), antes);
    });

    test('Un salto grande de tiempo no las hace subir de golpe', () {
      final chispas = Chispas(cantidad: 1)..chispas.single.y = 0.5;
      chispas.avanzar(20);

      expect(
        chispas.chispas.single.y,
        closeTo(0.5 - chispas.chispas.single.velocidad * 0.1, 1e-9),
      );
    });

    test('Con la misma semilla salen igual', () {
      List<(double, double)> posiciones(Chispas c) =>
          c.chispas.map((x) => (x.x, x.y)).toList();
      expect(posiciones(Chispas(semilla: 2)), posiciones(Chispas(semilla: 2)));
    });
  });

  group('Unitarias: la llama de los números iniciales', () {
    test('Tiene 6 lenguas, una por número', () {
      expect(PintorLlamaProgreso.posiciones.length, 6);
      expect(PintorLlamaProgreso.inclinaciones.length, 6);
      expect(PintorLlamaProgreso.largos.length, 6);
    });

    test('Van lado a lado, de izquierda a derecha', () {
      final posiciones = PintorLlamaProgreso.posiciones;
      for (var i = 1; i < 6; i++) {
        expect(posiciones[i], greaterThan(posiciones[i - 1]));
      }
      expect(posiciones.first, greaterThan(0));
      expect(posiciones.last, lessThan(1));
    });

    test('Las del centro son las más altas', () {
      final largos = PintorLlamaProgreso.largos;
      expect(largos[2], greaterThan(largos[1]));
      expect(largos[1], greaterThan(largos[0]));
      expect(largos[3], greaterThan(largos[4]));
      expect(largos[4], greaterThan(largos[5]));
    });

    test('Las de la izquierda se abren a la izquierda y al revés', () {
      final inclinaciones = PintorLlamaProgreso.inclinaciones;
      for (var i = 0; i < 3; i++) {
        expect(inclinaciones[i], lessThan(0));
        expect(inclinaciones[5 - i], greaterThan(0));
      }
    });

    test('Se encienden igual que los brazos del copo', () {
      expect(llenadoBrazos(3), [1, 1, 1, 0, 0, 0]);
    });

    test('Cada lengua sale de su base y llega a su largo', () {
      const base = Offset(32, 50);
      final lengua = PintorLlamaProgreso.lengua(base, 0, 40, 5);
      final caja = lengua.getBounds();

      expect(caja.bottom, closeTo(50, 0.01));
      expect(caja.top, closeTo(10, 1));
      expect(lengua.contains(const Offset(32, 45)), isTrue);
    });

    test('La punta de una lengua a la izquierda se curva hacia el centro', () {
      const base = Offset(20, 50);
      final lengua = PintorLlamaProgreso.lengua(base, -0.42, 40, 5);
      // La punta (lo más alto) queda más al centro de lo que apuntaba recta.
      final recta = base.dx + 40 * -0.408; // sin(−0.42) ≈ −0.408
      expect(lengua.getBounds().center.dx, greaterThan(recta));
    });

    test('Una lengua a medio encender es más corta', () {
      const base = Offset(32, 50);
      final completa = PintorLlamaProgreso.lengua(base, 0, 40, 5).getBounds();
      final media = PintorLlamaProgreso.lengua(base, 0, 20, 5).getBounds();

      expect(media.height, lessThan(completa.height));
      expect(media.bottom, closeTo(completa.bottom, 0.01));
    });

    test('Solo se vuelve a pintar si cambió el avance', () {
      expect(
        PintorLlamaProgreso(2).shouldRepaint(PintorLlamaProgreso(2)),
        isFalse,
      );
      expect(
        PintorLlamaProgreso(2).shouldRepaint(PintorLlamaProgreso(4)),
        isTrue,
      );
    });

    test('Lo que falta por encender es durazno claro, de tono cálido', () {
      expect(calido(ColoresFuego.apagado), isTrue);
      expect(ColoresFuego.apagado.computeLuminance(), greaterThan(0.75));
    });
  });
}
