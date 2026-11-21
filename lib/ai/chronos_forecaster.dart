import 'dart:math';

import 'package:cotacao_direta/ai/chronos/chronos_bolt_model.dart';
import 'package:cotacao_direta/ai/chronos/chronos_bolt_runner.dart';
import 'package:cotacao_direta/model/asset_series.dart';
import 'package:cotacao_direta/model/financial_analysis.dart';

/// Something that projects an asset's price forward. The analysis service
/// only knows this interface, which keeps it testable without the model.
abstract interface class AssetForecaster {
  /// Furthest horizon, in series steps, a single projection can reach.
  int get maximumHorizon;

  Future<AssetForecast> forecast(AssetSeries series, {int horizonInDays = 15});
}

/// Price projection made by Chronos-Bolt, a pre-trained forecasting model
/// downloaded from Hugging Face and run on the device (see
/// [ChronosBoltModel]).
///
/// Unlike a model trained on the spot with a few months of one asset, a
/// foundation model brings what it learned from a large collection of real
/// series, and answers in one pass with the whole distribution of the next
/// steps: the median is the projection and the outer quantiles are the
/// confidence band. No band has to be assumed.
///
/// The model is still tested against the asset's own past before its answer
/// is shown. A few times, it is run from a point in the recent past and its
/// projection is compared with what actually happened, side by side with the
/// random walk ("it stays where it is") — the rival that is hard to beat on
/// prices. The skill that comes out of it reaches the screen, so the user
/// knows how much to trust the projection for this asset.
class ChronosForecaster implements AssetForecaster {
  final ChronosBoltRunner runner;

  /// Name shown on screen as the source of the projection.
  final String modelName;

  /// Level of the band drawn around the projection (0.8 = 80%). It must fit
  /// within the outermost quantiles the model was trained on (0.1 and 0.9 for
  /// the published checkpoints).
  final double confidenceLevel;

  /// How many walk-forward backtests feed the diagnostics.
  final int backtestWindows;

  /// Shortest context a backtest may start from. With less, the model is
  /// working from a handful of points and the test would say little about the
  /// projection made from the full history.
  static const int minimumBacktestContext = 30;

  ChronosForecaster(
    this.runner, {
    required this.modelName,
    this.confidenceLevel = 0.8,
    this.backtestWindows = 3,
  })  : assert(confidenceLevel > 0 && confidenceLevel < 1),
        assert(backtestWindows >= 0) {
    final levels = runner.config.quantiles;
    if ((1 - confidenceLevel) / 2 < levels.first - 1e-9 ||
        (1 + confidenceLevel) / 2 > levels.last + 1e-9)
      throw ArgumentError(
          "confidence level $confidenceLevel is outside the model's quantiles");
  }

  @override
  int get maximumHorizon => runner.config.predictionLength;

  @override
  Future<AssetForecast> forecast(AssetSeries series,
      {int horizonInDays = 15}) async {
    if (series.isEmpty) throw ArgumentError("forecast of an empty series");
    if (horizonInDays <= 0 || horizonInDays > maximumHorizon)
      throw ArgumentError(
          "horizon must be between 1 and $maximumHorizon, was $horizonInDays");

    final prices = series.prices.toList(growable: false);
    final origins = _backtestOrigins(prices.length, horizonInDays);

    // The projection and the backtests go to the runner together: on the
    // isolate that is a single round trip.
    final predictions = await runner.predictAll([
      prices,
      for (final origin in origins) prices.sublist(0, origin),
    ]);

    final projection = predictions.first;
    final lowerLevel = (1 - confidenceLevel) / 2;
    final upperLevel = (1 + confidenceLevel) / 2;
    final points = <ForecastPoint>[];
    for (var step = 1; step <= horizonInDays; step++) {
      // The quantiles come out of independent heads and may cross now and
      // then; sorting keeps the band around the projection.
      final values = [
        projection.quantile(lowerLevel, step - 1),
        projection.median(step - 1),
        projection.quantile(upperLevel, step - 1),
      ]..sort();
      points.add(ForecastPoint(
        step: step,
        date: series.lastDate.add(Duration(days: step)),
        // A price does not go below zero, whatever the tail of the
        // distribution says.
        price: max(values[1], 0),
        lowerBound: max(values[0], 0),
        upperBound: max(values[2], 0),
      ));
    }

    return AssetForecast(
      lastPrice: series.lastPrice,
      points: List.unmodifiable(points),
      diagnostics: _diagnostics(
        prices,
        horizonInDays,
        origins,
        predictions.sublist(1),
        contextLength: min(prices.length, runner.config.contextLength),
      ),
      confidenceLevel: confidenceLevel,
    );
  }

  /// Points in the past the backtests start from, most recent first. Each one
  /// leaves [horizon] known prices ahead of it to compare against; they are
  /// spaced by half a horizon, so together they cover more than one stretch of
  /// the recent past.
  List<int> _backtestOrigins(int length, int horizon) {
    final spacing = max(1, horizon ~/ 2);
    final origins = <int>[];
    for (var window = 0; window < backtestWindows; window++) {
      final origin = length - horizon - window * spacing;
      if (origin < minimumBacktestContext) break;
      origins.add(origin);
    }
    return origins;
  }

  ModelDiagnostics _diagnostics(
    List<double> prices,
    int horizon,
    List<int> origins,
    List<ChronosBoltPrediction> backtests, {
    required int contextLength,
  }) {
    if (origins.isEmpty) {
      return ModelDiagnostics.unevaluated(
          modelName: modelName, contextLength: contextLength);
    }

    // Mean relative error at every step of every backtest, for the model's
    // median and for the random walk (the last price seen at the origin).
    var modelError = 0.0;
    var baselineError = 0.0;
    var count = 0;
    for (var window = 0; window < origins.length; window++) {
      final origin = origins[window];
      final lastSeen = prices[origin - 1];
      for (var step = 0; step < horizon; step++) {
        final actual = prices[origin + step];
        if (actual <= 0) continue;
        modelError +=
            (backtests[window].median(step) - actual).abs() / actual;
        baselineError += (lastSeen - actual).abs() / actual;
        count++;
      }
    }
    if (count == 0) {
      return ModelDiagnostics.unevaluated(
          modelName: modelName, contextLength: contextLength);
    }
    modelError /= count;
    baselineError /= count;
    final skill = baselineError <= 0
        ? 0.0
        : (1 - modelError / baselineError).clamp(0.0, 1.0);

    return ModelDiagnostics(
      modelName: modelName,
      contextLength: contextLength,
      backtestWindows: origins.length,
      backtestError: modelError,
      baselineError: baselineError,
      skill: skill,
    );
  }
}
