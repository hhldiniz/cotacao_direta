import 'dart:math';

import 'package:cotacao_direta/ai/math/statistics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('mean', () {
    test('devolve a média aritmética', () {
      expect(mean([1, 2, 3, 4]), 2.5);
    });

    test('recusa lista vazia', () {
      expect(() => mean([]), throwsArgumentError);
    });
  });

  group('variance e standardDeviation', () {
    test('usam o divisor n-1 por padrão', () {
      // Desvios ±1 e ±1 em torno de 3: soma dos quadrados 4, dividida por 3.
      expect(variance([2, 4, 4, 2]), closeTo(4 / 3, 1e-12));
    });

    test('com sample falso usam o divisor n', () {
      expect(variance([2, 4, 4, 2], sample: false), 1);
      expect(standardDeviation([2, 4, 4, 2], sample: false), 1);
    });

    test('um único ponto não tem dispersão', () {
      expect(variance([7]), 0);
      expect(standardDeviation([7]), 0);
    });

    test('série constante tem desvio zero', () {
      expect(standardDeviation([3, 3, 3, 3]), 0);
    });
  });

  group('logReturns', () {
    test('devolve um retorno a menos que o número de preços', () {
      expect(logReturns([1, 2, 4]).length, 2);
    });

    test('calcula o logaritmo da razão entre dias consecutivos', () {
      final returns = logReturns([100, 110]);

      expect(returns.single, closeTo(log(1.1), 1e-12));
    });

    test('somam-se ao longo do tempo', () {
      final returns = logReturns([10, 12, 9, 15]);
      final total = returns.reduce((a, b) => a + b);

      expect(total, closeTo(log(15 / 10), 1e-12));
    });

    test('ignora pares com preço não positivo', () {
      expect(logReturns([10, 0, 12]), isEmpty);
    });

    test('série de um ponto não tem retorno', () {
      expect(logReturns([10]), isEmpty);
    });
  });

  group('linearFit', () {
    test('recupera exatamente uma reta', () {
      final fit = linearFit([0, 1, 2, 3], [1, 3, 5, 7]);

      expect(fit.slope, closeTo(2, 1e-12));
      expect(fit.intercept, closeTo(1, 1e-12));
      expect(fit.rSquared, closeTo(1, 1e-12));
      expect(fit.predict(4), closeTo(9, 1e-12));
    });

    test('inclinação negativa para série que cai', () {
      expect(linearFit([0, 1, 2], [9, 6, 3]).slope, closeTo(-3, 1e-12));
    });

    test('R² baixo quando os pontos não seguem reta nenhuma', () {
      final fit = linearFit([0, 1, 2, 3], [1, 5, 5, 1]);

      expect(fit.rSquared, lessThan(0.05));
    });

    test('sem variação em y o R² é zero', () {
      final fit = linearFit([0, 1, 2], [4, 4, 4]);

      expect(fit.slope, closeTo(0, 1e-12));
      expect(fit.rSquared, 0);
    });

    test('menos de dois pontos devolve reta nula', () {
      expect(linearFit([1], [2]).slope, 0);
    });

    test('recusa listas de tamanhos diferentes', () {
      expect(() => linearFit([1, 2], [1]), throwsArgumentError);
    });
  });
}
