import 'package:cotacao_direta/model/asset_series.dart';

/// One projected day from the forecasting model, with the confidence band around it.
class ForecastPoint {
  /// How many days ahead of the last observed point, starting at 1.
  final int step;
  final DateTime date;

  /// Projected price (the centre of the band).
  final double price;

  final double lowerBound;
  final double upperBound;

  const ForecastPoint(
      {required this.step,
      required this.date,
      required this.price,
      required this.lowerBound,
      required this.upperBound});
}

/// How the forecasting model fared when tested against the asset's own past.
/// It reaches the screen because it changes how the projection should be
/// read: a model that did not beat the random walk on this series is, in
/// practice, no better than "tomorrow equals today".
class ModelDiagnostics {
  /// Name of the model that produced the projection, as shown on screen.
  final String modelName;

  /// Quotes the model read as context for the projection.
  final int contextLength;

  /// How many times the model was run from a point in the past and compared
  /// with what actually happened next (a walk-forward backtest).
  final int backtestWindows;

  /// Mean absolute error of the model in those backtests, in log-price (0.01
  /// is about 1%).
  final double? backtestError;

  /// The error, over the same backtests, of predicting "it stays where it is"
  /// — the random walk, which is the fair rival of any price forecaster.
  final double? baselineError;

  /// `1 - model error / random walk error`, clamped to [0, 1]. Zero means the
  /// model added no information at all on this series.
  final double skill;

  const ModelDiagnostics(
      {required this.modelName,
      required this.contextLength,
      required this.backtestWindows,
      required this.backtestError,
      required this.baselineError,
      required this.skill});

  /// The history was too short to hold back a stretch and test the model on
  /// it, so there is no measure of how reliable the projection is.
  factory ModelDiagnostics.unevaluated(
          {required String modelName, required int contextLength}) =>
      ModelDiagnostics(
          modelName: modelName,
          contextLength: contextLength,
          backtestWindows: 0,
          backtestError: null,
          baselineError: null,
          skill: 0);

  bool get evaluated => backtestWindows > 0;
}

/// Full projection for an asset.
class AssetForecast {
  final double lastPrice;
  final List<ForecastPoint> points;
  final ModelDiagnostics diagnostics;

  /// Confidence level of the band (0.8 = 80%).
  final double confidenceLevel;

  const AssetForecast(
      {required this.lastPrice,
      required this.points,
      required this.diagnostics,
      required this.confidenceLevel});

  int get horizonInDays => points.isEmpty ? 0 : points.last.step;

  /// Price at the end of the projected horizon.
  double get projectedPrice => points.isEmpty ? lastPrice : points.last.price;

  double get projectedLowerBound =>
      points.isEmpty ? lastPrice : points.last.lowerBound;

  double get projectedUpperBound =>
      points.isEmpty ? lastPrice : points.last.upperBound;

  /// Projected change as a fraction (0.03 = up 3%).
  double get projectedChange =>
      lastPrice <= 0 ? 0 : projectedPrice / lastPrice - 1;

  /// What [amount] invested today would be worth at the end of the horizon,
  /// with the same confidence band as the price projection.
  ///
  /// It is a rule of three over the projected change — the "financial
  /// handling" the screen offers on top of the model.
  AmountProjection projectAmount(double amount) {
    if (lastPrice <= 0 || !amount.isFinite)
      return AmountProjection(
          initialAmount: amount, expected: amount, lower: amount, upper: amount);
    return AmountProjection(
      initialAmount: amount,
      expected: amount * projectedPrice / lastPrice,
      lower: amount * projectedLowerBound / lastPrice,
      upper: amount * projectedUpperBound / lastPrice,
    );
  }
}

/// Simulation of an amount invested today, projected to the end of the
/// horizon.
class AmountProjection {
  final double initialAmount;
  final double expected;
  final double lower;
  final double upper;

  const AmountProjection(
      {required this.initialAmount,
      required this.expected,
      required this.lower,
      required this.upper});

  double get expectedProfit => expected - initialAmount;
}

/// Statistical portrait of the series, shown in the market summary and used by
/// the insights. Optional fields stay null when the history is too short for
/// the indicator (RSI needs 15 points, the 30-day change needs 31, and so on).
class MarketStatistics {
  final double lastPrice;
  final double? weeklyChange;
  final double? monthlyChange;
  final double annualizedVolatility;
  final double? relativeStrengthIndex;
  final double? shortMovingAverage;
  final double? longMovingAverage;
  final double maxDrawdown;
  final double compoundAnnualGrowthRate;

  /// Slope of the line fitted over the log of the prices, in log-return per
  /// day, with the R² of the fit: how much of the variation the trend
  /// explains.
  final double trendSlopePerDay;
  final double trendRSquared;

  final int sampleCount;

  const MarketStatistics(
      {required this.lastPrice,
      required this.weeklyChange,
      required this.monthlyChange,
      required this.annualizedVolatility,
      required this.relativeStrengthIndex,
      required this.shortMovingAverage,
      required this.longMovingAverage,
      required this.maxDrawdown,
      required this.compoundAnnualGrowthRate,
      required this.trendSlopePerDay,
      required this.trendRSquared,
      required this.sampleCount});

  /// Change over the longest period available, for the trend insights.
  double? get referenceChange => monthlyChange ?? weeklyChange;

  /// A short average above the long one is the classic bullish crossover.
  bool? get shortAboveLong =>
      shortMovingAverage == null || longMovingAverage == null
          ? null
          : shortMovingAverage! > longMovingAverage!;
}

/// What the analysis finds worth pointing out. The text does not come ready
/// made: the code identifies the kind of remark and [arguments] carries the
/// numbers already formatted in the requested language, which the screen slots
/// into the translated sentence template.
enum InsightCode {
  trendUp,
  trendDown,
  trendSideways,
  momentumOverbought,
  momentumOversold,
  momentumNeutral,
  volatilityHigh,
  volatilityLow,
  projectionUp,
  projectionDown,
  projectionStable,
  drawdown,
  confidenceGood,
  confidenceLow,
  dataLimited,
}

/// Tone of the remark, so the screen can pick an icon and a colour.
enum InsightSentiment { positive, negative, neutral, caution }

class FinancialInsight {
  final InsightCode code;
  final InsightSentiment sentiment;
  final List<String> arguments;

  const FinancialInsight(
      {required this.code,
      required this.sentiment,
      this.arguments = const []});

  @override
  String toString() => "FinancialInsight($code, $sentiment, $arguments)";
}

/// Everything the local analysis produces for one asset.
class FinancialAnalysis {
  final AssetSeries series;
  final MarketStatistics statistics;
  final AssetForecast forecast;
  final List<FinancialInsight> insights;

  const FinancialAnalysis(
      {required this.series,
      required this.statistics,
      required this.forecast,
      required this.insights});

  String get assetCode => series.code;

  AssetKind get assetKind => series.kind;
}
