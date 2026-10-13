import 'dart:math';

import 'package:test/test.dart';

import 'package:brilliantdart/dados.dart';

void main() {
  group('Un dado', () {
    test('Empieza mostrando una cara del 1 al 6', () {
      for (var semilla = 0; semilla < 50; semilla++) {
        expect(Dado(Random(semilla)).valor, inInclusiveRange(1, 6));
      }
    });

    test('lanzar devuelve un número del 1 al 6', () {
      final dado = Dado(Random(1));

      for (var i = 0; i < 200; i++) {
        expect(dado.lanzar(), inInclusiveRange(1, 6));
      }
    });

    test('lanzar actualiza el valor que muestra el dado', () {
      final dado = Dado(Random(2));

      for (var i = 0; i < 20; i++) {
        final resultado = dado.lanzar();
        expect(dado.valor, resultado);
      }
    });

    test('Nunca sale 0 ni 7', () {
      final dado = Dado(Random(3));
      final caras = {for (var i = 0; i < 1000; i++) dado.lanzar()};

      expect(caras, isNot(contains(0)));
      expect(caras, isNot(contains(7)));
    });

    test('Con suficientes lanzamientos salen las seis caras', () {
      final dado = Dado(Random(4));
      final caras = {for (var i = 0; i < 300; i++) dado.lanzar()};

      expect(caras, {1, 2, 3, 4, 5, 6});
    });

    test('Ninguna cara sale muchísimo más que otra', () {
      final dado = Dado(Random(5));
      final conteo = {for (var cara = 1; cara <= 6; cara++) cara: 0};
      for (var i = 0; i < 6000; i++) {
        final cara = dado.lanzar();
        conteo[cara] = conteo[cara]! + 1;
      }

      for (final veces in conteo.values) {
        expect(veces, inInclusiveRange(800, 1200));
      }
    });

    test('Dos dados con la misma semilla dan los mismos resultados', () {
      final primero = Dado(Random(9));
      final segundo = Dado(Random(9));

      expect(primero.valor, segundo.valor);
      for (var i = 0; i < 30; i++) {
        expect(primero.lanzar(), segundo.lanzar());
      }
    });
  });

  group('Par de dados', () {
    test('Tiene exactamente dos dados distintos', () {
      final dados = Dados(random: Random(1));

      expect(dados.dados, hasLength(2));
      expect(identical(dados.dado1, dados.dado2), isFalse);
    });

    test('La lista de dados contiene dado1 y dado2 en ese orden', () {
      final dados = Dados(random: Random(1));

      expect(identical(dados.dados[0], dados.dado1), isTrue);
      expect(identical(dados.dados[1], dados.dado2), isTrue);
    });

    test('El historial empieza vacío', () {
      expect(Dados(random: Random(1)).historial.lanzamientos, isEmpty);
    });

    test('Funciona también sin darle una semilla', () {
      final dados = Dados();
      final (valor1, valor2) = dados.lanzar();

      expect(valor1, inInclusiveRange(1, 6));
      expect(valor2, inInclusiveRange(1, 6));
    });

    test('lanzar devuelve los valores de dado1 y dado2', () {
      final dados = Dados(random: Random(6));

      for (var i = 0; i < 20; i++) {
        final (valor1, valor2) = dados.lanzar();
        expect(valor1, dados.dado1.valor);
        expect(valor2, dados.dado2.valor);
      }
    });

    test('Cada lanzamiento agrega exactamente un registro', () {
      final dados = Dados(random: Random(7));

      for (var i = 1; i <= 10; i++) {
        dados.lanzar();
        expect(dados.historial.lanzamientos, hasLength(i));
      }
    });

    test('El historial guarda lo mismo que devolvió lanzar', () {
      final dados = Dados(random: Random(8));
      final resultados = [for (var i = 0; i < 15; i++) dados.lanzar()];

      expect(
        dados.historial.lanzamientos
            .map((l) => (l.resultadoDado1, l.resultadoDado2))
            .toList(),
        resultados,
      );
    });

    test('Pueden salir dobles', () {
      final dados = Dados(random: Random(10));
      final dobles = [
        for (var i = 0; i < 200; i++) dados.lanzar(),
      ].where((tiro) => tiro.$1 == tiro.$2);

      expect(dobles, isNotEmpty);
    });

    test('Los dos dados no salen siempre iguales', () {
      final dados = Dados(random: Random(11));
      final distintos = [
        for (var i = 0; i < 50; i++) dados.lanzar(),
      ].where((tiro) => tiro.$1 != tiro.$2);

      expect(distintos, isNotEmpty);
    });
  });
}
