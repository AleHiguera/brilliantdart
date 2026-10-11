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

    test('Con la misma semilla los lanzamientos se repiten', () {
      final primeros = Dados(random: Random(7));
      final segundos = Dados(random: Random(7));

      for (var i = 0; i < 20; i++) {
        expect(primeros.lanzar(), segundos.lanzar());
      }
    });

    test('En muchos lanzamientos salen las seis caras en cada dado', () {
      final dados = Dados(random: Random(3));
      final caras1 = <int>{};
      final caras2 = <int>{};

      for (var i = 0; i < 600; i++) {
        final (valor1, valor2) = dados.lanzar();
        caras1.add(valor1);
        caras2.add(valor2);
      }

      expect(caras1, {1, 2, 3, 4, 5, 6});
      expect(caras2, {1, 2, 3, 4, 5, 6});
    });

    test('La lista de dados no se puede modificar', () {
      final dados = Dados(random: Random(1));

      expect(() => dados.dados.add(Dado(Random(1))), throwsUnsupportedError);
    });

    test('Un lanzamiento nuevo empieza sin acción registrada', () {
      final dados = Dados(random: Random(1));

      dados.lanzar();

      expect(dados.historial.lanzamientos.single.accionRealizada, isNull);
    });
  });
}