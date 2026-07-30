import 'package:cotacao_direta/ai/financial_ai_service.dart';
import 'package:cotacao_direta/ai/local_financial_model.dart';
import 'package:cotacao_direta/model/asset_series.dart';
import 'package:cotacao_direta/model/financial_analysis.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/series_test_helper.dart';

void main() {
  final service = FinancialAiService();

  group('FinancialAiService.computeStatistics', () {
    test('mede as variações de 7 e 30 dias', () {
      // 40 preços subindo 1% ao dia, de forma exata.
      final prices = List<double>.generate(
          40, (index) => 100 * _power(1.01, index));

      final statistics =
          service.computeStatistics(seriesFromPrices(prices));

      expect(statistics.weeklyChange, closeTo(_power(1.01, 7) - 1, 1e-9));
      expect(statistics.monthlyChange, closeTo(_power(1.01, 30) - 1, 1e-9));
      expect(statistics.lastPrice, prices.last);
      expect(statistics.sampleCount, 40);
    });

    test('série que só sobe não tem queda a reportar', () {
      final prices = List<double>.generate(40, (index) => 100.0 + index);

      final statistics = service.computeStatistics(seriesFromPrices(prices));

      expect(statistics.maxDrawdown, 0);
      expect(statistics.relativeStrengthIndex, 100);
    });

    test('crescimento exponencial constante tem R² perto de 1', () {
      final prices =
          List<double>.generate(60, (index) => 10 * _power(1.005, index));

      final statistics = service.computeStatistics(seriesFromPrices(prices));

      expect(statistics.trendRSquared, closeTo(1, 1e-6));
      expect(statistics.trendSlopePerDay, greaterThan(0));
      expect(statistics.compoundAnnualGrowthRate, greaterThan(0));
    });

    test('série sem variação é plana em todos os indicadores', () {
      final statistics =
          service.computeStatistics(seriesFromPrices(List.filled(60, 4.0)));

      expect(statistics.annualizedVolatility, 0);
      expect(statistics.maxDrawdown, 0);
      expect(statistics.weeklyChange, 0);
      expect(statistics.relativeStrengthIndex, 50);
      expect(statistics.compoundAnnualGrowthRate, closeTo(0, 1e-12));
    });

    test('cripto é anualizada com 365 dias, e não com 252 pregões', () {
      final prices = syntheticPrices(length: 90);

      final moeda = service.computeStatistics(seriesFromPrices(prices));
      final cripto = service.computeStatistics(seriesFromPrices(prices,
          code: "BTC", kind: AssetKind.cryptocurrency));

      expect(cripto.annualizedVolatility,
          greaterThan(moeda.annualizedVolatility));
    });

    test('as médias móveis exigem histórico suficiente', () {
      final curta = service.computeStatistics(
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

      expect(() => service.computeStatistics(vazia), throwsArgumentError);
    });
  });

  group('FinancialAiService.analyze', () {
    test('devolve estatísticas, projeção e observações juntas', () {
      final series = seriesFromPrices(syntheticPrices(length: 150));

      final analysis = service.analyze(series, horizonInDays: 15);

      expect(analysis.assetCode, "USD");
      expect(analysis.assetKind, AssetKind.currency);
      expect(analysis.statistics.sampleCount, 150);
      expect(analysis.forecast.points.length, 15);
      expect(analysis.insights, isNotEmpty);
    });

    test('o idioma pedido formata os números das observações', () {
      final series = seriesFromPrices(
          syntheticPrices(length: 150, dailyDrift: 0.004, noise: 0.002));

      final portugues = service.analyze(series, languageCode: "pt");
      final ingles = service.analyze(series, languageCode: "en");

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

    test('aceita um modelo configurado pelo chamador', () {
      final service = FinancialAiService(
          model: LocalFinancialModel(confidenceLevel: 0.95, seed: 99));
      final series = seriesFromPrices(syntheticPrices(length: 120));

      final analysis = service.analyze(series, horizonInDays: 7);

      expect(analysis.forecast.confidenceLevel, 0.95);
      expect(analysis.forecast.points.length, 7);
    });

    test('a análise inteira é reprodutível', () {
      final series = seriesFromPrices(syntheticPrices(length: 150));

      final first = service.analyze(series);
      final second = service.analyze(series);

      expect(first.forecast.projectedPrice, second.forecast.projectedPrice);
      expect(first.insights.map((insight) => insight.code),
          second.insights.map((insight) => insight.code));
    });

    test('série de cripto é analisada como cripto', () {
      final series = seriesFromPrices(syntheticPrices(length: 150),
          code: "BTC", kind: AssetKind.cryptocurrency, quoteCurrency: "BRL");

      final analysis = service.analyze(series);

      expect(analysis.assetKind, AssetKind.cryptocurrency);
      expect(analysis.series.quoteCurrency, "BRL");
    });

    test('o insight de projeção concorda com o número projetado', () {
      final series = seriesFromPrices(
          syntheticPrices(length: 150, dailyDrift: 0.004, noise: 0.002));

      final analysis = service.analyze(series, horizonInDays: 15);

      expect(analysis.forecast.projectedChange, greaterThan(0));
      expect(analysis.insights.first.code, InsightCode.projectionUp);
    });
  });
}

double _power(double base, int exponent) {
  var result = 1.0;
  for (var index = 0; index < exponent; index++) result *= base;
  return result;
}
