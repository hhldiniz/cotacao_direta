import 'package:cotacao_direta/ai/chronos/chronos_bolt_runner.dart';
import 'package:cotacao_direta/ai/chronos_forecaster.dart';
import 'package:cotacao_direta/ai/financial_ai_service.dart';
import 'package:cotacao_direta/model/asset_series.dart';
import 'package:cotacao_direta/model/financial_analysis.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/chronos_test_helper.dart';
import '../helpers/series_test_helper.dart';

void main() {
  final model = loadTinyChronosBolt();
  final service = FinancialAiService(ChronosForecaster(
      InlineChronosBoltRunner(model),
      modelName: 'Chronos-Bolt Fixture'));

  group('FinancialAiService.computeStatistics', () {
    test('mede as variações de 7 e 30 dias', () {
      // 40 preços subindo 1% ao dia, de forma exata.
      final prices = List<double>.generate(
          40, (index) => 100 * _power(1.01, index));

      final statistics =
          FinancialAiService.computeStatistics(seriesFromPrices(prices));

      expect(statistics.weeklyChange, closeTo(_power(1.01, 7) - 1, 1e-9));
      expect(statistics.monthlyChange, closeTo(_power(1.01, 30) - 1, 1e-9));
      expect(statistics.lastPrice, prices.last);
      expect(statistics.sampleCount, 40);
    });

    test('série que só sobe não tem queda a reportar', () {
      final prices = List<double>.generate(40, (index) => 100.0 + index);

      final statistics = FinancialAiService.computeStatistics(seriesFromPrices(prices));

      expect(statistics.maxDrawdown, 0);
      expect(statistics.relativeStrengthIndex, 100);
    });

    test('crescimento exponencial constante tem R² perto de 1', () {
      final prices =
          List<double>.generate(60, (index) => 10 * _power(1.005, index));

      final statistics = FinancialAiService.computeStatistics(seriesFromPrices(prices));

      expect(statistics.trendRSquared, closeTo(1, 1e-6));
      expect(statistics.trendSlopePerDay, greaterThan(0));
      expect(statistics.compoundAnnualGrowthRate, greaterThan(0));
    });

    test('série sem variação é plana em todos os indicadores', () {
      final statistics =
          FinancialAiService.computeStatistics(seriesFromPrices(List.filled(60, 4.0)));

      expect(statistics.annualizedVolatility, 0);
      expect(statistics.maxDrawdown, 0);
      expect(statistics.weeklyChange, 0);
      expect(statistics.relativeStrengthIndex, 50);
      expect(statistics.compoundAnnualGrowthRate, closeTo(0, 1e-12));
    });

    test('cripto é anualizada com 365 dias, e não com 252 pregões', () {
      final prices = syntheticPrices(length: 90);

      final moeda = FinancialAiService.computeStatistics(seriesFromPrices(prices));
      final cripto = FinancialAiService.computeStatistics(seriesFromPrices(prices,
          code: "BTC", kind: AssetKind.cryptocurrency));

      expect(cripto.annualizedVolatility,
          greaterThan(moeda.annualizedVolatility));
    });

    test('as médias móveis exigem histórico suficiente', () {
      final curta = FinancialAiService.computeStatistics(
          seriesFromPrices(syntheticPrices(length: 10)));

      expect(curta.shortMovingAverage, isNotNull);
      expect(curta.longMovingAverage, isNull);
      expect(curta.monthlyChange, isNull);
    });

    test('recusa série vazia', () {
      final vazia = AssetSeries(
          code: "USD",
          kind: AssetKind.currency,
          quoteCurrency: "BRL",
          points: []);

      expect(() => FinancialAiService.computeStatistics(vazia), throwsArgumentError);
    });
  });

  group('FinancialAiService.analyze', () {
    test('devolve estatísticas, projeção e observações juntas', () async {
      final series = seriesFromPrices(syntheticPrices(length: 150));

      final analysis = await service.analyze(series, horizonInDays: 15);

      expect(analysis.assetCode, "USD");
      expect(analysis.assetKind, AssetKind.currency);
      expect(analysis.statistics.sampleCount, 150);
      expect(analysis.forecast.points.length, 15);
      expect(analysis.insights, isNotEmpty);
    });

    test('o idioma pedido formata os números das observações', () async {
      final series = seriesFromPrices(
          syntheticPrices(length: 150, dailyDrift: 0.004, noise: 0.002));

      final portugues = await service.analyze(series, localeName: "pt");
      final ingles = await service.analyze(series, localeName: "en");

      expect(
          portugues.insights
              .expand((insight) => insight.arguments)
              .any((argument) => argument.contains(",")),
          isTrue);
      expect(
          ingles.insights
              .expand((insight) => insight.arguments)
              .any((argument) => argument.contains(",")),
          isFalse);
    });

    test('recusa série curta demais para os indicadores', () {
      final series = seriesFromPrices(syntheticPrices(length: 5));

      expect(() => service.analyze(series), throwsArgumentError);
    });

    test('aceita um previsor configurado pelo chamador', () async {
      final service = FinancialAiService(ChronosForecaster(
          InlineChronosBoltRunner(model),
          modelName: 'Chronos-Bolt Fixture',
          confidenceLevel: 0.6));
      final series = seriesFromPrices(syntheticPrices(length: 120));

      final analysis = await service.analyze(series, horizonInDays: 7);

      expect(analysis.forecast.confidenceLevel, 0.6);
      expect(analysis.forecast.points.length, 7);
    });

    test('a análise inteira é reprodutível', () async {
      final series = seriesFromPrices(syntheticPrices(length: 150));

      final first = await service.analyze(series);
      final second = await service.analyze(series);

      expect(first.forecast.projectedPrice, second.forecast.projectedPrice);
      expect(first.insights.map((insight) => insight.code),
          second.insights.map((insight) => insight.code));
    });

    test('série de cripto é analisada como cripto', () async {
      final series = seriesFromPrices(syntheticPrices(length: 150),
          code: "BTC", kind: AssetKind.cryptocurrency, quoteCurrency: "BRL");

      final analysis = await service.analyze(series);

      expect(analysis.assetKind, AssetKind.cryptocurrency);
      expect(analysis.series.quoteCurrency, "BRL");
    });

    test('o insight de projeção concorda com o número projetado', () async {
      for (final seed in [1, 2, 3, 4, 5]) {
        final series = seriesFromPrices(
            syntheticPrices(length: 150, noise: 0.02, seed: seed));

        final analysis = await service.analyze(series, horizonInDays: 15);

        final change = analysis.forecast.projectedChange;
        final expected = change > 0.01
            ? InsightCode.projectionUp
            : change < -0.01
                ? InsightCode.projectionDown
                : InsightCode.projectionStable;
        expect(analysis.insights.first.code, expected, reason: 'seed $seed');
      }
    });

    test('o diagnóstico do modelo chega às observações', () async {
      final analysis = await service
          .analyze(seriesFromPrices(syntheticPrices(length: 150)));

      expect(analysis.forecast.diagnostics.evaluated, isTrue);
      expect(
          analysis.insights.last.code,
          anyOf(InsightCode.confidenceGood, InsightCode.confidenceLow));
    });
  });
}

double _power(double base, int exponent) {
  var result = 1.0;
  for (var index = 0; index < exponent; index++) result *= base;
  return result;
}
