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

  group('exponentiallyWeightedMean', () {
    test('série constante devolve o próprio valor', () {
      expect(exponentiallyWeightedMean([5, 5, 5, 5]), closeTo(5, 1e-12));
    });

    test('pesa mais o fim da série que o começo', () {
      // A estimativa é semeada pelo primeiro ponto, então o peso do começo só
      // some numa série longa — que é o caso de uso real (meses de cotação).
      final subindo = exponentiallyWeightedMean(
          [...List<double>.filled(29, 0), 1]);
      final descendo =
          exponentiallyWeightedMean([1, ...List<double>.filled(29, 0)]);

      expect(subindo, greaterThan(descendo));
    });

    test('alpha maior aproxima mais do último ponto', () {
      final serie = [...List<double>.filled(29, 0.0), 1.0];
      final lento = exponentiallyWeightedMean(serie, alpha: 0.1);
      final rapido = exponentiallyWeightedMean(serie, alpha: 0.9);

      expect(rapido, greaterThan(lento));
      expect(rapido, closeTo(0.9, 1e-9));
    });

    test('recusa lista vazia', () {
      expect(() => exponentiallyWeightedMean([]), throwsArgumentError);
    });
  });

  group('meanSquaredError', () {
    test('previsão exata tem erro zero', () {
      expect(meanSquaredError([1, 2, 3], [1, 2, 3]), 0);
    });

    test('é a média dos quadrados das diferenças', () {
      expect(meanSquaredError([1, 2], [2, 4]), closeTo((1 + 4) / 2, 1e-12));
    });

    test('recusa listas de tamanhos diferentes', () {
      expect(() => meanSquaredError([1], [1, 2]), throwsArgumentError);
    });
  });

  group('normalQuantile', () {
    test('a mediana da normal é zero', () {
      expect(normalQuantile(0.5), closeTo(0, 1e-9));
    });

    test('reproduz os quantis conhecidos', () {
      expect(normalQuantile(0.975), closeTo(1.959964, 1e-5));
      expect(normalQuantile(0.9), closeTo(1.281552, 1e-5));
      expect(normalQuantile(0.99), closeTo(2.326348, 1e-5));
    });

    test('é simétrica em torno da mediana', () {
      expect(normalQuantile(0.2), closeTo(-normalQuantile(0.8), 1e-6));
    });

    test('vale também nas caudas extremas', () {
      expect(normalQuantile(0.001), closeTo(-3.090232, 1e-4));
      expect(normalQuantile(0.999), closeTo(3.090232, 1e-4));
    });

    test('recusa probabilidade fora de (0, 1)', () {
      expect(() => normalQuantile(0), throwsArgumentError);
      expect(() => normalQuantile(1), throwsArgumentError);
    });
  });

  group('confidenceMultiplier', () {
    test('95% de confiança dá o 1,96 de sempre', () {
      expect(confidenceMultiplier(0.95), closeTo(1.959964, 1e-5));
    });

    test('80% de confiança dá 1,28', () {
      expect(confidenceMultiplier(0.8), closeTo(1.281552, 1e-5));
    });

    test('mais confiança pede faixa mais larga', () {
      expect(confidenceMultiplier(0.99),
          greaterThan(confidenceMultiplier(0.8)));
    });

    test('recusa nível fora de (0, 1)', () {
      expect(() => confidenceMultiplier(1), throwsArgumentError);
    });
  });
}
