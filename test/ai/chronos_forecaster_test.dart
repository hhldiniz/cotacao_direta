import 'dart:convert';
import 'dart:typed_data';

import 'package:cotacao_direta/ai/chronos/chronos_bolt_runner.dart';
import 'package:cotacao_direta/ai/chronos/chronos_bolt_runner_io.dart';
import 'package:cotacao_direta/ai/chronos_forecaster.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/chronos_test_helper.dart';
import '../helpers/series_test_helper.dart';

void main() {
  final model = loadTinyChronosBolt();
  ChronosForecaster forecaster({int backtestWindows = 3}) => ChronosForecaster(
        InlineChronosBoltRunner(model),
        modelName: 'Chronos-Bolt Fixture',
        backtestWindows: backtestWindows,
      );

  group('ChronosForecaster.forecast', () {
    test('projeta um ponto por dia do horizonte, a partir da última data',
        () async {
      final series = seriesFromPrices(syntheticPrices(length: 120));

      final forecast = await forecaster().forecast(series, horizonInDays: 15);

      expect(forecast.points.length, 15);
      expect(forecast.horizonInDays, 15);
      expect(forecast.points.first.step, 1);
      expect(forecast.points.first.date,
          series.lastDate.add(const Duration(days: 1)));
      expect(forecast.lastPrice, series.lastPrice);
      expect(forecast.confidenceLevel, 0.8);
    });

    test('a projeção é a mediana do modelo e a faixa, os quantis externos',
        () async {
      final prices = syntheticPrices(length: 60);
      final series = seriesFromPrices(prices);
      final prediction = model.predict(prices);

      final forecast = await forecaster().forecast(series, horizonInDays: 5);

      for (var step = 0; step < 5; step++) {
        final values = [
          prediction.quantile(0.1, step),
          prediction.median(step),
          prediction.quantile(0.9, step),
        ]..sort();
        final point = forecast.points[step];
        expect(point.lowerBound, closeTo(values[0], 1e-12));
        expect(point.price, closeTo(values[1], 1e-12));
        expect(point.upperBound, closeTo(values[2], 1e-12));
      }
    });

    test('a faixa sempre envolve a projeção e nunca fica negativa', () async {
      final series = seriesFromPrices(
          syntheticPrices(length: 150, noise: 0.05, initialPrice: 0.02));

      final forecast = await forecaster().forecast(series, horizonInDays: 30);

      for (final point in forecast.points) {
        expect(point.lowerBound, lessThanOrEqualTo(point.price));
        expect(point.upperBound, greaterThanOrEqualTo(point.price));
        expect(point.lowerBound, greaterThanOrEqualTo(0));
      }
    });

    test('é determinística: a mesma série dá a mesma projeção', () async {
      final series = seriesFromPrices(syntheticPrices(length: 120));

      final first = await forecaster().forecast(series);
      final second = await forecaster().forecast(series);

      expect(first.projectedPrice, second.projectedPrice);
      expect(first.diagnostics.skill, second.diagnostics.skill);
    });

    test('recusa série vazia e horizonte fora do alcance do modelo', () {
      final series = seriesFromPrices(syntheticPrices(length: 60));

      expect(() => forecaster().forecast(seriesFromPrices(const [])),
          throwsArgumentError);
      expect(() => forecaster().forecast(series, horizonInDays: 0),
          throwsArgumentError);
      expect(
          () => forecaster().forecast(series,
              horizonInDays: model.config.predictionLength + 1),
          throwsArgumentError);
    });

    test('recusa nível de confiança além dos quantis do modelo', () {
      expect(
          () => ChronosForecaster(InlineChronosBoltRunner(model),
              modelName: 'x', confidenceLevel: 0.95),
          throwsArgumentError);
    });
  });

  group('ChronosForecaster diagnóstico', () {
    test('testa o modelo contra o passado recente', () async {
      final series = seriesFromPrices(syntheticPrices(length: 120));

      final diagnostics =
          (await forecaster().forecast(series, horizonInDays: 15)).diagnostics;

      expect(diagnostics.evaluated, isTrue);
      expect(diagnostics.backtestWindows, 3);
      expect(diagnostics.modelName, 'Chronos-Bolt Fixture');
      expect(diagnostics.backtestError, isNotNull);
      expect(diagnostics.baselineError, greaterThan(0));
      expect(diagnostics.skill, inInclusiveRange(0, 1));
      // O modelo de teste lê no máximo a janela de contexto dele.
      expect(diagnostics.contextLength, model.config.contextLength);
    });

    test('a habilidade compara o erro do modelo com o do passeio aleatório',
        () async {
      final diagnostics = (await forecaster()
              .forecast(seriesFromPrices(syntheticPrices(length: 120))))
          .diagnostics;

      final expected = (1 -
              diagnostics.backtestError! / diagnostics.baselineError!)
          .clamp(0.0, 1.0);
      expect(diagnostics.skill, closeTo(expected, 1e-12));
    });

    test('histórico curto demais fica sem teste', () async {
      final series = seriesFromPrices(syntheticPrices(length: 40));

      final diagnostics =
          (await forecaster().forecast(series, horizonInDays: 15)).diagnostics;

      expect(diagnostics.evaluated, isFalse);
      expect(diagnostics.backtestWindows, 0);
      expect(diagnostics.skill, 0);
      expect(diagnostics.contextLength, 32);
    });

    test('cada janela de teste exige contexto mínimo', () async {
      // 15 de horizonte, janelas a cada 7: origens em 35 e 28; só a primeira
      // tem o contexto mínimo.
      final series = seriesFromPrices(syntheticPrices(length: 50));

      final diagnostics =
          (await forecaster().forecast(series, horizonInDays: 15)).diagnostics;

      expect(diagnostics.backtestWindows, 1);
    });

    test('sem janelas de teste pedidas, não há diagnóstico', () async {
      final diagnostics = (await forecaster(backtestWindows: 0)
              .forecast(seriesFromPrices(syntheticPrices(length: 120))))
          .diagnostics;

      expect(diagnostics.evaluated, isFalse);
    });
  });

  group('IsolateChronosBoltRunner', () {
    test('dá o mesmo resultado que a execução direta', () async {
      final runner = await IsolateChronosBoltRunner.spawn(
          _configJson(), tinyChronosWeightBytes());
      addTearDown(runner.dispose);
      final contexts = [
        syntheticPrices(length: 50),
        syntheticPrices(length: 13, seed: 3),
      ];

      final predictions = await runner.predictAll(contexts);

      expect(predictions.length, 2);
      for (var index = 0; index < contexts.length; index++) {
        final direct = model.predict(contexts[index]);
        for (var quantile = 0; quantile < direct.values.length; quantile++) {
          expect(predictions[index].values[quantile],
              direct.values[quantile]);
        }
      }
    });

    test('pesos corrompidos viram FormatException', () async {
      expect(
          () => IsolateChronosBoltRunner.spawn(
              _configJson(), Uint8List.fromList(List.filled(64, 7))),
          throwsFormatException);
    });

    test('depois de descartado, recusa pedidos', () async {
      final runner = await IsolateChronosBoltRunner.spawn(
          _configJson(), tinyChronosWeightBytes());
      await runner.dispose();

      expect(() => runner.predictAll([
            [1.0, 2.0]
          ]), throwsStateError);
    });
  });
}

Map<String, dynamic> _configJson() =>
    jsonDecode(utf8.decode(tinyChronosConfigBytes())) as Map<String, dynamic>;
