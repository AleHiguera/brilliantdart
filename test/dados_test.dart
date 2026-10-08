import 'dart:math';

import 'package:test/test.dart';

import 'package:brilliantdart/dados.dart';

void main() {
  group('Dados', () {
    test('Siempre contiene dos dados con valores entre 1 y 6', () {
      final dados = Dados(random: Random(42));

      expect(dados.dados, hasLength(2));
      expect(dados.dado1.valor, inInclusiveRange(1, 6));
      expect(dados.dado2.valor, inInclusiveRange(1, 6));
    });

    test('Cada lanzamiento genera dos valores válidos', () {
      final dados = Dados(random: Random(42));

      final (valorDado1, valorDado2) = dados.lanzar();

      expect(valorDado1, inInclusiveRange(1, 6));
      expect(valorDado2, inInclusiveRange(1, 6));
      expect(dados.dado1.valor, valorDado1);
      expect(dados.dado2.valor, valorDado2);

      expect(dados.historial.lanzamientos, hasLength(1));
      expect(dados.historial.lanzamientos.single.numeroLanzamiento, 1);
      expect(dados.historial.lanzamientos.single.resultadoDado1, valorDado1);
      expect(dados.historial.lanzamientos.single.resultadoDado2, valorDado2);
    });

    test('Permite realizar múltiples lanzamientos', () {
      final dados = Dados(random: Random(42));

      for (var lanzamiento = 0; lanzamiento < 100; lanzamiento++) {
        final valores = dados.lanzar();

        expect(valores.$1, inInclusiveRange(1, 6));
        expect(valores.$2, inInclusiveRange(1, 6));
        expect(dados.dados, hasLength(2));
        final registro = dados.historial.lanzamientos[lanzamiento];
        expect(registro.numeroLanzamiento, lanzamiento + 1);
        expect(registro.resultadoDado1, valores.$1);
        expect(registro.resultadoDado2, valores.$2);
      }

      expect(dados.historial.lanzamientos, hasLength(100));
    });
  });
}