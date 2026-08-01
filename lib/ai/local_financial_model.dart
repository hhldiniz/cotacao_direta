import 'dart:math';

import 'package:cotacao_direta/ai/math/indicators.dart';
import 'package:cotacao_direta/ai/math/statistics.dart';
import 'package:cotacao_direta/ai/neural/neural_network.dart';
import 'package:cotacao_direta/model/asset_series.dart';
import 'package:cotacao_direta/model/financial_analysis.dart';

/// Predictive model that runs entirely on the device.
///
/// It brings together two pieces that cover for each other:
///
/// 1. a small neural network ([NeuralNetwork]) trained on the spot with the
///    history of the very asset the user opened — no downloaded weights and no
///    server. It receives a window of recent log-returns plus a few indicators
///    (momentum, RSI, distance from the average, volatility acceleration) and
///    tries to predict the next day's return;
/// 2. a statistical drift, which is the exponentially weighted mean of the
///    log-returns, damped along the horizon.
///
/// The final projection is the weighted average of the two, and the network's
/// weight is not arbitrary: it comes from how much the network beat the random
/// walk ("tomorrow equals today") on a validation slice it did not see while
/// training. Asset prices are nearly a random walk, so that rival is beaten by
/// a small margin when it is beaten at all; when it is not, the weight goes to
/// zero and the projection becomes the statistical baseline. That keeps the
/// screen honest instead of selling a precision the model does not have.
///
/// The confidence band comes from the random walk model in log-price: the
/// accumulated standard deviation grows with `sigma * sqrt(days)`, and the
/// multiplier is the normal quantile for the requested confidence level.
class LocalFinancialModel {
  /// How many recent log-returns go into the feature vector.
  final int window;

  final int hiddenUnits;
  final int epochs;
  final double learningRate;
  final double weightDecay;

  /// Seed of the training randomness. Fixed on purpose: the same series has to
  /// produce the same projection every time, otherwise the screen would change
  /// its answer on every tap of the button.
  final int seed;

  /// Level of the band drawn around the projection (0.8 = 80%).
  final double confidenceLevel;

  /// Cap on the network's weight in the blend. Even a network that does very
  /// well on validation does not go past this: the validation slice is short,
  /// and overconfidence is the classic mistake in this kind of forecast.
  final double maximumNeuralWeight;

  static const int _rsiPeriod = 14;
  static const int _rsiLookback = 60;
  static const int _movingAveragePeriod = 10;
  static const int _momentumPeriod = 5;
  static const int _volatilityPeriod = 5;

  /// Below this it is not worth training: the network would memorise the few
  /// existing windows and validation would say nothing.
  static const int minimumTrainingSamples = 24;

  /// Damping applied to the drift on each projected day. Without it, a recent
  /// uptrend would be extrapolated in a straight line to the end of the
  /// horizon.
  static const double _driftDamping = 0.92;

  /// Cap on the projected daily move, in standard deviations. It holds the
  /// projection within what the series usually does.
  static const double _maximumDailyMove = 2.5;

  LocalFinancialModel({
    this.window = 5,
    this.hiddenUnits = 6,
    this.epochs = 300,
    this.learningRate = 0.03,
    this.weightDecay = 1e-4,
    this.seed = 7,
    this.confidenceLevel = 0.8,
    this.maximumNeuralWeight = 0.6,
  })  : assert(window > 0),
        assert(hiddenUnits > 0),
        assert(confidenceLevel > 0 && confidenceLevel < 1),
        assert(maximumNeuralWeight >= 0 && maximumNeuralWeight <= 1);

  /// Size of the feature vector: the window of returns plus the four derived
  /// indicators.
  int get featureCount => window + 4;

  /// First index of the series with enough past behind it to become a sample.
  int get _firstUsableIndex =>
      max(window, max(_rsiPeriod + 1, _movingAveragePeriod));

  /// Shortest history that allows training the network.
  int get minimumHistoryForTraining =>
      _firstUsableIndex + minimumTrainingSamples + 1;

  /// Projects [horizonInDays] days beyond the last point of [series].
  AssetForecast forecast(AssetSeries series, {int horizonInDays = 15}) {
    if (series.isEmpty) throw ArgumentError("forecast of an empty series");
    if (horizonInDays <= 0)
      throw ArgumentError("horizon must be positive");

    final prices = series.prices.toList();
    final returns = logReturns(prices);

    // Reference scale of the series. Every feature and the target are divided
    // by it, which keeps the network seeing numbers of order 1 for both a calm
    // currency pair and a crypto. The floor avoids a division by zero on a
    // series with no variation (a currency quoted against itself, say).
    final volatility =
        returns.length >= 2 ? standardDeviation(returns) : 0.0;
    final scale = max(volatility, 1e-6);

    final samples = _buildSamples(prices, scale);
    final network = _train(samples);
    final diagnostics = network.diagnostics;

    final drift = returns.isEmpty
        ? 0.0
        : exponentiallyWeightedMean(returns, alpha: 0.15)
            .clamp(-0.5 * scale, 0.5 * scale);

    final multiplier = confidenceMultiplier(confidenceLevel);
    final workingPrices = prices.toList();
    final points = <ForecastPoint>[];

    for (var step = 1; step <= horizonInDays; step++) {
      final dampedDrift = drift * pow(_driftDamping, step - 1);

      var expectedReturn = dampedDrift;
      final model = network.network;
      if (model != null) {
        final features =
            _features(workingPrices, workingPrices.length - 1, scale);
        if (features != null) {
          final neuralReturn =
              model.predict(features).clamp(-4.0, 4.0) * scale;
          expectedReturn = diagnostics.neuralWeight * neuralReturn +
              (1 - diagnostics.neuralWeight) * dampedDrift;
        }
      }
      expectedReturn = expectedReturn.clamp(
          -_maximumDailyMove * scale, _maximumDailyMove * scale);

      final price = workingPrices.last * exp(expectedReturn);
      workingPrices.add(price);

      // Random walk uncertainty: it grows with the square root of the number
      // of days.
      final horizonDeviation = scale * sqrt(step) * multiplier;
      points.add(ForecastPoint(
        step: step,
        date: series.lastDate.add(Duration(days: step)),
        price: price,
        lowerBound: price * exp(-horizonDeviation),
        upperBound: price * exp(horizonDeviation),
      ));
    }

    return AssetForecast(
      lastPrice: series.lastPrice,
      points: List.unmodifiable(points),
      diagnostics: diagnostics,
      confidenceLevel: confidenceLevel,
    );
  }

  /// Training windows built from the series: each sample is the set of
  /// features on day `index` and, as the target, the next day's log-return.
  _TrainingData _buildSamples(List<double> prices, double scale) {
    final inputs = <List<double>>[];
    final targets = <double>[];
    for (var index = _firstUsableIndex; index < prices.length - 1; index++) {
      final features = _features(prices, index, scale);
      if (features == null) continue;
      final previous = prices[index];
      final next = prices[index + 1];
      if (previous <= 0 || next <= 0) continue;
      inputs.add(features);
      targets.add((log(next / previous) / scale).clamp(-4.0, 4.0));
    }
    return _TrainingData(inputs, targets);
  }

  /// Features of day [index], all in units of [scale] and clamped to [-4, 4]
  /// so that one exceptional day cannot dominate training.
  List<double>? _features(List<double> prices, int index, double scale) {
    if (index < _firstUsableIndex || index >= prices.length) return null;

    final features = <double>[];

    // The most recent log-returns, from day [index] backwards.
    for (var lag = 0; lag < window; lag++) {
      final current = prices[index - lag];
      final previous = prices[index - lag - 1];
      if (current <= 0 || previous <= 0) return null;
      features.add(log(current / previous) / scale);
    }

    // Momentum: the return accumulated over the short window, normalised by
    // the volatility expected over that number of days.
    final momentumBase = prices[index - _momentumPeriod];
    if (momentumBase <= 0 || prices[index] <= 0) return null;
    features.add(log(prices[index] / momentumBase) /
        (scale * sqrt(_momentumPeriod.toDouble())));

    // RSI centred on zero. The lookback is fixed so that the feature means the
    // same thing at the start and at the end of the series.
    final rsiWindow = prices.sublist(
        max(0, index + 1 - _rsiLookback), index + 1);
    final rsi = relativeStrengthIndex(rsiWindow, period: _rsiPeriod) ?? 50;
    features.add((rsi - 50) / 50);

    // Distance from the moving average, in standard deviations of the window
    // (Bollinger bands), scaled down to the same order of magnitude as the
    // rest.
    final zScore = bollingerZScore(
            prices.sublist(index + 1 - _movingAveragePeriod, index + 1),
            _movingAveragePeriod) ??
        0;
    features.add(zScore / 3);

    // Volatility acceleration: how much the agitation of the last few days
    // differs from the series' typical agitation.
    final recentReturns =
        logReturns(prices.sublist(index - _volatilityPeriod, index + 1));
    final recentVolatility =
        recentReturns.length >= 2 ? standardDeviation(recentReturns) : scale;
    features.add(recentVolatility / scale - 1);

    for (var position = 0; position < features.length; position++) {
      final value = features[position];
      features[position] = value.isFinite ? value.clamp(-4.0, 4.0) : 0.0;
    }
    return features;
  }

  /// Trains the network and measures how much it beat the random walk.
  _TrainedModel _train(_TrainingData data) {
    if (data.inputs.length < minimumTrainingSamples) {
      return _TrainedModel(
          null, ModelDiagnostics.untrained(trainingSamples: data.inputs.length));
    }

    // Validation is the tail of the series, not a random sample: predicting a
    // day surrounded by already known neighbours is far easier than predicting
    // the future, and would hand out an inflated score.
    final validationCount =
        (data.inputs.length * 0.2).round().clamp(4, data.inputs.length - 12);
    final splitIndex = data.inputs.length - validationCount;
    final trainingInputs = data.inputs.sublist(0, splitIndex);
    final trainingTargets = data.targets.sublist(0, splitIndex);
    final validationInputs = data.inputs.sublist(splitIndex);
    final validationTargets = data.targets.sublist(splitIndex);

    final network = NeuralNetwork(
        inputSize: featureCount, hiddenSize: hiddenUnits, seed: seed);
    final report = network.train(
      trainingInputs,
      trainingTargets,
      validationInputs: validationInputs,
      validationTargets: validationTargets,
      epochs: epochs,
      learningRate: learningRate,
      weightDecay: weightDecay,
    );

    // The random walk predicts a zero return for the next day.
    final baselineError = meanSquaredError(
        List<double>.filled(validationTargets.length, 0), validationTargets);
    final validationError = report.validationError;
    final skill = (baselineError <= 0 || validationError == null)
        ? 0.0
        : (1 - validationError / baselineError).clamp(0.0, 1.0);

    return _TrainedModel(
      network,
      ModelDiagnostics(
        trainingSamples: data.inputs.length,
        validationError: validationError,
        baselineError: baselineError,
        skill: skill,
        neuralWeight: skill * maximumNeuralWeight,
        epochs: report.epochs,
        trained: true,
      ),
    );
  }
}

class _TrainingData {
  final List<List<double>> inputs;
  final List<double> targets;

  const _TrainingData(this.inputs, this.targets);
}

class _TrainedModel {
  /// Null when there was not enough history to train.
  final NeuralNetwork? network;
  final ModelDiagnostics diagnostics;

  const _TrainedModel(this.network, this.diagnostics);
}
