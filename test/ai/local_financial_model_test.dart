import 'package:cotacao_direta/ai/local_financial_model.dart';
import 'package:cotacao_direta/model/asset_series.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/series_test_helper.dart';

void main() {
  final model = LocalFinancialModel();

  group('LocalFinancialModel.forecast', () {
    test('projeta um ponto por dia do horizonte', () {
      final series = seriesFromPrices(syntheticPrices(length: 120));

      final forecast = model.forecast(series, horizonInDays: 10);

      expect(forecast.points.length, 10);
      expect(forecast.points.first.step, 1);
      expect(forecast.points.last.step, 10);
      expect(forecast.horizonInDays, 10);
    });

    test('as datas projetadas seguem o último dia observado', () {
      final series = seriesFromPrices(syntheticPrices(length: 60),
          startDate: DateTime(2024, 1, 1));

      final forecast = model.forecast(series, horizonInDays: 3);

      expect(forecast.points.first.date, series.lastDate.add(Duration(days: 1)));
      expect(forecast.points.last.date, series.lastDate.add(Duration(days: 3)));
    });

    test('a faixa de confiança envolve o valor projetado', () {
      final series = seriesFromPrices(syntheticPrices(length: 120));

      final forecast = model.forecast(series, horizonInDays: 15);

      for (var point in forecast.points) {
        expect(point.lowerBound, lessThan(point.price));
        expect(point.upperBound, greaterThan(point.price));
        expect(point.lowerBound, greaterThan(0));
      }
    });

    test('a incerteza cresce com a distância no tempo', () {
      final series = seriesFromPrices(syntheticPrices(length: 120));

      final forecast = model.forecast(series, horizonInDays: 20);
      final primeiraFaixa = forecast.points.first.upperBound /
          forecast.points.first.lowerBound;
      final ultimaFaixa =
          forecast.points.last.upperBound / forecast.points.last.lowerBound;

      expect(ultimaFaixa, greaterThan(primeiraFaixa));
    });

    test('a mesma série produz sempre a mesma projeção', () {
      final series = seriesFromPrices(syntheticPrices(length: 120));

      final first = model.forecast(series, horizonInDays: 15);
      final second = model.forecast(series, horizonInDays: 15);

      expect(first.projectedPrice, second.projectedPrice);
      expect(first.diagnostics.skill, second.diagnostics.skill);
    });

    test('série longa o bastante treina a rede', () {
      final series = seriesFromPrices(syntheticPrices(length: 150));

      final diagnostics = model.forecast(series).diagnostics;

      expect(diagnostics.trained, isTrue);
      expect(diagnostics.trainingSamples,
          greaterThanOrEqualTo(LocalFinancialModel.minimumTrainingSamples));
      expect(diagnostics.epochs, greaterThan(0));
      expect(diagnostics.validationError, isNotNull);
      expect(diagnostics.baselineError, isNotNull);
    });

    test('série curta cai na base estatística, sem treinar', () {
      final series = seriesFromPrices(syntheticPrices(length: 20));

      final forecast = model.forecast(series, horizonInDays: 5);

      expect(forecast.diagnostics.trained, isFalse);
      expect(forecast.diagnostics.neuralWeight, 0);
      expect(forecast.points.length, 5);
      expect(forecast.points.every((point) => point.price.isFinite), isTrue);
    });

    test('o peso da rede nunca passa do teto configurado', () {
      final series = seriesFromPrices(syntheticPrices(length: 200));

      final diagnostics = model.forecast(series).diagnostics;

      expect(diagnostics.neuralWeight,
          lessThanOrEqualTo(model.maximumNeuralWeight));
      expect(diagnostics.neuralWeight, greaterThanOrEqualTo(0));
      expect(diagnostics.skill, inInclusiveRange(0, 1));
    });

    test('série sem variação nenhuma projeta o mesmo valor, sem NaN', () {
      final series = seriesFromPrices(List<double>.filled(120, 5.0));

      final forecast = model.forecast(series, horizonInDays: 10);

      for (var point in forecast.points) {
        expect(point.price, closeTo(5.0, 1e-6));
        expect(point.price.isNaN, isFalse);
        expect(point.lowerBound.isNaN, isFalse);
      }
    });

    test('acompanha o sentido de uma tendência forte de alta', () {
      final series = seriesFromPrices(
          syntheticPrices(length: 150, dailyDrift: 0.004, noise: 0.002));

      final forecast = model.forecast(series, horizonInDays: 15);

      expect(forecast.projectedPrice, greaterThan(forecast.lastPrice));
      expect(forecast.projectedChange, greaterThan(0));
    });

    test('acompanha o sentido de uma tendência forte de baixa', () {
      final series = seriesFromPrices(
          syntheticPrices(length: 150, dailyDrift: -0.004, noise: 0.002));

      final forecast = model.forecast(series, horizonInDays: 15);

      expect(forecast.projectedPrice, lessThan(forecast.lastPrice));
      expect(forecast.projectedChange, lessThan(0));
    });

    test('não extrapola a tendência sem freio: o movimento diário é limitado',
        () {
      final series = seriesFromPrices(
          syntheticPrices(length: 150, dailyDrift: 0.05, noise: 0.001));

      final forecast = model.forecast(series, horizonInDays: 30);

      // Com amortecimento, 30 dias de alta projetada não podem multiplicar o
      // preço por um fator absurdo.
      expect(forecast.projectedPrice / forecast.lastPrice, lessThan(5));
    });

    test('a faixa acompanha a volatilidade da série', () {
      final calma = model.forecast(
          seriesFromPrices(syntheticPrices(length: 150, noise: 0.001)),
          horizonInDays: 10);
      final agitada = model.forecast(
          seriesFromPrices(syntheticPrices(length: 150, noise: 0.02)),
          horizonInDays: 10);

      expect(
          agitada.projectedUpperBound / agitada.projectedLowerBound,
          greaterThan(
              calma.projectedUpperBound / calma.projectedLowerBound));
    });

    test('mais confiança pedida, faixa mais larga', () {
      final series = seriesFromPrices(syntheticPrices(length: 150));
      final estreita = LocalFinancialModel(confidenceLevel: 0.8)
          .forecast(series, horizonInDays: 10);
      final larga = LocalFinancialModel(confidenceLevel: 0.99)
          .forecast(series, horizonInDays: 10);

      expect(larga.projectedUpperBound,
          greaterThan(estreita.projectedUpperBound));
      expect(larga.projectedLowerBound, lessThan(estreita.projectedLowerBound));
      expect(larga.confidenceLevel, 0.99);
    });

    test('recusa série vazia', () {
      final series = AssetSeries(
          code: "USD",
          kind: AssetKind.currency,
          quoteCurrency: "BRL",
          points: []);

      expect(() => model.forecast(series), throwsArgumentError);
    });

    test('recusa horizonte não positivo', () {
      final series = seriesFromPrices(syntheticPrices(length: 60));

      expect(() => model.forecast(series, horizonInDays: 0),
          throwsArgumentError);
    });

    test('roda rápido o bastante para um celular', () {
      final series = seriesFromPrices(syntheticPrices(length: 360));

      final stopwatch = Stopwatch()..start();
      model.forecast(series, horizonInDays: 30);
      stopwatch.stop();

      // Folgado de propósito: o objetivo é pegar uma regressão de ordem de
      // grandeza (treino saindo de milissegundos para segundos), não medir a
      // máquina do CI.
      expect(stopwatch.elapsedMilliseconds, lessThan(4000));
    });
  });

  group('AssetForecast.projectAmount', () {
    test('aplica a variação projetada sobre o valor investido', () {
      final series = seriesFromPrices(
          syntheticPrices(length: 150, dailyDrift: 0.003, noise: 0.002));
      final forecast = model.forecast(series, horizonInDays: 15);

      final projection = forecast.projectAmount(1000);

      expect(projection.initialAmount, 1000);
      expect(projection.expected,
          closeTo(1000 * forecast.projectedPrice / forecast.lastPrice, 1e-9));
      expect(projection.lower, lessThan(projection.expected));
      expect(projection.upper, greaterThan(projection.expected));
      expect(projection.expectedProfit,
          closeTo(projection.expected - 1000, 1e-9));
    });
  });
}
