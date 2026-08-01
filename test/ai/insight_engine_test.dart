import 'package:cotacao_direta/ai/insight_engine.dart';
import 'package:cotacao_direta/model/asset_series.dart';
import 'package:cotacao_direta/model/financial_analysis.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/series_test_helper.dart';

MarketStatistics _statistics({
  double lastPrice = 5.0,
  double? weeklyChange = 0.0,
  double? monthlyChange = 0.0,
  double annualizedVolatility = 0.10,
  double? relativeStrengthIndex = 50,
  double maxDrawdown = 0.05,
  double compoundAnnualGrowthRate = 0.0,
  int sampleCount = 120,
}) =>
    MarketStatistics(
      lastPrice: lastPrice,
      weeklyChange: weeklyChange,
      monthlyChange: monthlyChange,
      annualizedVolatility: annualizedVolatility,
      relativeStrengthIndex: relativeStrengthIndex,
      shortMovingAverage: lastPrice,
      longMovingAverage: lastPrice,
      maxDrawdown: maxDrawdown,
      compoundAnnualGrowthRate: compoundAnnualGrowthRate,
      trendSlopePerDay: 0,
      trendRSquared: 0.5,
      sampleCount: sampleCount,
    );

AssetForecast _forecast({
  double lastPrice = 5.0,
  double projectedPrice = 5.0,
  int horizonInDays = 15,
  ModelDiagnostics? diagnostics,
}) =>
    AssetForecast(
      lastPrice: lastPrice,
      points: [
        ForecastPoint(
          step: horizonInDays,
          date: DateTime(2024, 6, 1),
          price: projectedPrice,
          lowerBound: projectedPrice * 0.95,
          upperBound: projectedPrice * 1.05,
        )
      ],
      diagnostics: diagnostics ??
          const ModelDiagnostics(
            trainingSamples: 90,
            validationError: 0.8,
            baselineError: 1.0,
            skill: 0.2,
            neuralWeight: 0.12,
            epochs: 120,
            trained: true,
          ),
      confidenceLevel: 0.8,
    );

List<InsightCode> _codes(List<FinancialInsight> insights) =>
    insights.map((insight) => insight.code).toList();

FinancialInsight _insightOf(
        List<FinancialInsight> insights, InsightCode code) =>
    insights.firstWhere((insight) => insight.code == code);

void main() {
  final engine = const InsightEngine();
  final series = seriesFromPrices(syntheticPrices(length: 60));
  final cryptoSeries = seriesFromPrices(syntheticPrices(length: 60),
      code: "BTC", kind: AssetKind.cryptocurrency);

  group('InsightEngine projeção', () {
    test('alta projetada vira insight positivo', () {
      final insights = engine.generate(
          series: series,
          statistics: _statistics(),
          forecast: _forecast(projectedPrice: 5.5));

      final insight = _insightOf(insights, InsightCode.projectionUp);
      expect(insight.sentiment, InsightSentiment.positive);
      // Alta de 10%, horizonte de 15 dias e a cotação projetada.
      expect(insight.arguments.length, 3);
      expect(insight.arguments.first, contains("10"));
      expect(insight.arguments[1], "15");
    });

    test('queda projetada vira insight negativo', () {
      final insights = engine.generate(
          series: series,
          statistics: _statistics(),
          forecast: _forecast(projectedPrice: 4.5));

      expect(_insightOf(insights, InsightCode.projectionDown).sentiment,
          InsightSentiment.negative);
    });

    test('variação pequena é lida como estabilidade', () {
      final insights = engine.generate(
          series: series,
          statistics: _statistics(),
          forecast: _forecast(projectedPrice: 5.01));

      expect(_codes(insights), contains(InsightCode.projectionStable));
    });
  });

  group('InsightEngine tendência', () {
    test('alta de 30 dias acima do limiar vira tendência de alta', () {
      final insights = engine.generate(
          series: series,
          statistics: _statistics(monthlyChange: 0.08),
          forecast: _forecast());

      final insight = _insightOf(insights, InsightCode.trendUp);
      expect(insight.sentiment, InsightSentiment.positive);
      expect(insight.arguments.last, "30");
    });

    test('queda de 30 dias vira tendência de baixa', () {
      final insights = engine.generate(
          series: series,
          statistics: _statistics(monthlyChange: -0.08),
          forecast: _forecast());

      expect(_codes(insights), contains(InsightCode.trendDown));
    });

    test('variação pequena não é tendência', () {
      final insights = engine.generate(
          series: series,
          statistics: _statistics(monthlyChange: 0.005),
          forecast: _forecast());

      expect(_codes(insights), contains(InsightCode.trendSideways));
    });

    test('sem 30 dias de histórico usa a variação de 7 dias', () {
      final insights = engine.generate(
          series: series,
          statistics: _statistics(monthlyChange: null, weeklyChange: 0.09),
          forecast: _forecast());

      expect(_insightOf(insights, InsightCode.trendUp).arguments.last, "7");
    });

    test('sem variação nenhuma não fala de tendência', () {
      final insights = engine.generate(
          series: series,
          statistics: _statistics(monthlyChange: null, weeklyChange: null),
          forecast: _forecast());

      expect(
          _codes(insights),
          isNot(anyOf(contains(InsightCode.trendUp),
              contains(InsightCode.trendDown),
              contains(InsightCode.trendSideways))));
    });
  });

  group('InsightEngine momento', () {
    test('IFR alto avisa sobrecompra', () {
      final insights = engine.generate(
          series: series,
          statistics: _statistics(relativeStrengthIndex: 78),
          forecast: _forecast());

      final insight = _insightOf(insights, InsightCode.momentumOverbought);
      expect(insight.sentiment, InsightSentiment.caution);
      expect(insight.arguments.single, "78");
    });

    test('IFR baixo avisa sobrevenda', () {
      final insights = engine.generate(
          series: series,
          statistics: _statistics(relativeStrengthIndex: 22),
          forecast: _forecast());

      expect(_codes(insights), contains(InsightCode.momentumOversold));
    });

    test('IFR no meio da escala é momento equilibrado', () {
      final insights = engine.generate(
          series: series,
          statistics: _statistics(relativeStrengthIndex: 51),
          forecast: _forecast());

      expect(_codes(insights), contains(InsightCode.momentumNeutral));
    });

    test('sem IFR calculado não fala de momento', () {
      final insights = engine.generate(
          series: series,
          statistics: _statistics(relativeStrengthIndex: null),
          forecast: _forecast());

      expect(_codes(insights), isNot(contains(InsightCode.momentumNeutral)));
    });
  });

  group('InsightEngine volatilidade', () {
    test('o limiar de moeda fiduciária é mais baixo que o de cripto', () {
      final statistics = _statistics(annualizedVolatility: 0.30);

      final moeda = engine.generate(
          series: series, statistics: statistics, forecast: _forecast());
      final cripto = engine.generate(
          series: cryptoSeries, statistics: statistics, forecast: _forecast());

      expect(_codes(moeda), contains(InsightCode.volatilityHigh));
      expect(_codes(cripto), isNot(contains(InsightCode.volatilityHigh)));
    });

    test('cripto acima de 60% ao ano também é volatilidade alta', () {
      final insights = engine.generate(
          series: cryptoSeries,
          statistics: _statistics(annualizedVolatility: 0.75),
          forecast: _forecast());

      expect(_codes(insights), contains(InsightCode.volatilityHigh));
    });

    test('volatilidade baixa é ponto positivo', () {
      final insights = engine.generate(
          series: series,
          statistics: _statistics(annualizedVolatility: 0.02),
          forecast: _forecast());

      expect(_insightOf(insights, InsightCode.volatilityLow).sentiment,
          InsightSentiment.positive);
    });

    test('volatilidade intermediária não vira insight', () {
      final insights = engine.generate(
          series: series,
          statistics: _statistics(annualizedVolatility: 0.10),
          forecast: _forecast());

      expect(
          _codes(insights),
          isNot(anyOf(contains(InsightCode.volatilityHigh),
              contains(InsightCode.volatilityLow))));
    });
  });

  group('InsightEngine risco e confiança', () {
    test('queda relevante do topo vira aviso', () {
      final insights = engine.generate(
          series: series,
          statistics: _statistics(maxDrawdown: 0.32),
          forecast: _forecast());

      final insight = _insightOf(insights, InsightCode.drawdown);
      expect(insight.sentiment, InsightSentiment.caution);
      expect(insight.arguments.single, contains("32"));
    });

    test('queda pequena não vira aviso', () {
      final insights = engine.generate(
          series: series,
          statistics: _statistics(maxDrawdown: 0.03),
          forecast: _forecast());

      expect(_codes(insights), isNot(contains(InsightCode.drawdown)));
    });

    test('rede que superou o passeio aleatório é reportada como tal', () {
      final insights = engine.generate(
          series: series,
          statistics: _statistics(),
          forecast: _forecast(
              diagnostics: const ModelDiagnostics(
            trainingSamples: 90,
            validationError: 0.7,
            baselineError: 1.0,
            skill: 0.3,
            neuralWeight: 0.18,
            epochs: 100,
            trained: true,
          )));

      expect(_codes(insights), contains(InsightCode.confidenceGood));
    });

    test('rede sem vantagem avisa que a projeção é a base estatística', () {
      final insights = engine.generate(
          series: series,
          statistics: _statistics(),
          forecast: _forecast(
              diagnostics: const ModelDiagnostics(
            trainingSamples: 90,
            validationError: 1.0,
            baselineError: 1.0,
            skill: 0.0,
            neuralWeight: 0.0,
            epochs: 60,
            trained: true,
          )));

      final insight = _insightOf(insights, InsightCode.confidenceLow);
      expect(insight.sentiment, InsightSentiment.caution);
      expect(insight.arguments, isEmpty);
    });

    test('histórico curto é declarado explicitamente', () {
      final insights = engine.generate(
          series: series,
          statistics: _statistics(),
          forecast: _forecast(
              diagnostics: ModelDiagnostics.untrained(trainingSamples: 8)));

      final insight = _insightOf(insights, InsightCode.dataLimited);
      expect(insight.arguments.single, "8");
    });
  });

  group('InsightEngine formatação dos números', () {
    test('em português o separador decimal é a vírgula', () {
      final insights = const InsightEngine(languageCode: "pt").generate(
          series: series,
          statistics: _statistics(monthlyChange: 0.1234),
          forecast: _forecast());

      expect(_insightOf(insights, InsightCode.trendUp).arguments.first,
          "12,3%");
    });

    test('em inglês o separador decimal é o ponto', () {
      final insights = const InsightEngine(languageCode: "en").generate(
          series: series,
          statistics: _statistics(monthlyChange: 0.1234),
          forecast: _forecast());

      expect(_insightOf(insights, InsightCode.trendUp).arguments.first,
          "12.3%");
    });

    test('a cotação projetada ganha casas decimais conforme a ordem de '
        'grandeza', () {
      final insights = const InsightEngine(languageCode: "en").generate(
          series: cryptoSeries,
          statistics: _statistics(lastPrice: 0.0000017),
          forecast:
              _forecast(lastPrice: 0.0000017, projectedPrice: 0.0000019));

      final insight = _insightOf(insights, InsightCode.projectionUp);
      expect(insight.arguments.last, isNot("0.00"));
      expect(insight.arguments.last, startsWith("0.0000019"));
    });
  });

  test('a projeção é sempre a primeira observação da lista', () {
    final insights = engine.generate(
        series: series,
        statistics: _statistics(monthlyChange: 0.2),
        forecast: _forecast(projectedPrice: 6));

    expect(insights.first.code, InsightCode.projectionUp);
  });
}
