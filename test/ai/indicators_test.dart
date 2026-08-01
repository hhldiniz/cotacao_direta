import 'dart:math';

import 'package:cotacao_direta/ai/math/indicators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('simpleMovingAverage', () {
    test('usa apenas os últimos pontos do período', () {
      expect(simpleMovingAverage([1, 2, 3, 10, 20, 30], 3), 20);
    });

    test('série mais curta que o período não tem média', () {
      expect(simpleMovingAverage([1, 2], 3), isNull);
    });

    test('recusa período não positivo', () {
      expect(() => simpleMovingAverage([1, 2], 0), throwsArgumentError);
    });
  });

  group('exponentialMovingAverage', () {
    test('série constante devolve o próprio valor', () {
      expect(exponentialMovingAverage([4, 4, 4, 4, 4], 3), closeTo(4, 1e-12));
    });

    test('reage mais rápido que a média simples numa virada', () {
      final prices = [1.0, 1.0, 1.0, 1.0, 5.0];

      expect(exponentialMovingAverage(prices, 4)!,
          greaterThan(simpleMovingAverage(prices, 4)!));
    });

    test('série mais curta que o período não tem média', () {
      expect(exponentialMovingAverage([1, 2], 5), isNull);
    });
  });

  group('relativeStrengthIndex', () {
    test('série sempre em alta satura em 100', () {
      final prices = List<double>.generate(30, (index) => 10.0 + index);

      expect(relativeStrengthIndex(prices), 100);
    });

    test('série sempre em baixa fica perto de zero', () {
      final prices = List<double>.generate(30, (index) => 50.0 - index);

      expect(relativeStrengthIndex(prices), closeTo(0, 1e-9));
    });

    test('série constante fica no meio da escala', () {
      final prices = List<double>.filled(30, 7);

      expect(relativeStrengthIndex(prices), 50);
    });

    test('alternância simétrica fica em torno de 50', () {
      final prices = List<double>.generate(
          40, (index) => index.isEven ? 10.0 : 11.0);

      expect(relativeStrengthIndex(prices), closeTo(50, 5));
    });

    test('precisa de mais preços que o período', () {
      expect(relativeStrengthIndex([1, 2, 3], period: 14), isNull);
      expect(relativeStrengthIndex([1, 2, 3, 4], period: 3), isNotNull);
    });
  });

  group('maxDrawdown', () {
    test('mede a queda do topo até o vale seguinte', () {
      expect(maxDrawdown([100, 120, 60, 90]), closeTo(0.5, 1e-12));
    });

    test('série que só sobe não tem queda', () {
      expect(maxDrawdown([1, 2, 3, 4]), 0);
    });

    test('ignora a recuperação posterior ao vale', () {
      expect(maxDrawdown([100, 50, 200]), closeTo(0.5, 1e-12));
    });

    test('série vazia devolve zero', () {
      expect(maxDrawdown([]), 0);
    });
  });

  group('annualizedVolatility', () {
    test('multiplica o desvio diário pela raiz do número de pregões', () {
      final returns = [0.01, -0.01, 0.01, -0.01];
      final expected = 0.011547005383792515 * sqrt(252);

      expect(annualizedVolatility(returns), closeTo(expected, 1e-6));
    });

    test('série sem variação tem volatilidade zero', () {
      expect(annualizedVolatility([0, 0, 0]), 0);
    });

    test('cripto usa o ano de 365 dias', () {
      final returns = [0.02, -0.02, 0.02, -0.02];

      expect(annualizedVolatility(returns, periodsPerYear: 365),
          greaterThan(annualizedVolatility(returns)));
    });

    test('menos de dois retornos não define volatilidade', () {
      expect(annualizedVolatility([0.01]), 0);
    });
  });

  group('momentum', () {
    test('devolve a variação percentual do período', () {
      expect(momentum([10, 11, 12, 20], 3), closeTo(1.0, 1e-12));
    });

    test('é negativo quando o preço cai', () {
      expect(momentum([10, 9, 8], 2), closeTo(-0.2, 1e-12));
    });

    test('precisa de mais pontos que o período', () {
      expect(momentum([10, 11], 5), isNull);
    });
  });

  group('compoundAnnualGrowthRate', () {
    test('dobrar em um ano é 100% ao ano', () {
      expect(
          compoundAnnualGrowthRate(
              initialPrice: 100, finalPrice: 200, spanInDays: 365),
          closeTo(1.0, 1e-9));
    });

    test('dobrar em dois anos rende bem menos que 100% ao ano', () {
      expect(
          compoundAnnualGrowthRate(
              initialPrice: 100, finalPrice: 200, spanInDays: 730),
          closeTo(sqrt(2) - 1, 1e-9));
    });

    test('sem intervalo de tempo devolve zero', () {
      expect(
          compoundAnnualGrowthRate(
              initialPrice: 100, finalPrice: 200, spanInDays: 0),
          0);
    });
  });

  group('bollingerZScore', () {
    test('preço na média tem z igual a zero', () {
      expect(bollingerZScore([1, 3, 1, 3, 2], 5), closeTo(0, 1e-12));
    });

    test('preço acima da média tem z positivo', () {
      expect(bollingerZScore([1, 1, 1, 1, 5], 5)!, greaterThan(0));
    });

    test('janela sem variação devolve zero', () {
      expect(bollingerZScore([2, 2, 2, 2], 4), 0);
    });

    test('série mais curta que a janela não tem z', () {
      expect(bollingerZScore([1, 2], 5), isNull);
    });
  });
}
