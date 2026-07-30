import 'dart:math';

import 'package:cotacao_direta/ai/math/statistics.dart';

/// Classic technical indicators computed over the price series. They are both
/// the inputs the local model receives besides the raw returns and the numbers
/// shown in the market summary on screen.

/// Simple moving average of the last [period] prices. Returns null when the
/// series is shorter than the period: an incomplete average would be compared
/// against complete ones on a different scale.
double? simpleMovingAverage(List<double> values, int period) {
  if (period <= 0) throw ArgumentError("period must be positive");
  if (values.length < period) return null;
  return mean(values.sublist(values.length - period));
}

/// Exponential moving average of period [period], in the usual market form
/// (`alpha = 2 / (period + 1)`), seeded by the simple average of the first
/// block.
double? exponentialMovingAverage(List<double> values, int period) {
  if (period <= 0) throw ArgumentError("period must be positive");
  if (values.length < period) return null;
  final alpha = 2 / (period + 1);
  var estimate = mean(values.sublist(0, period));
  for (var index = period; index < values.length; index++) {
    estimate = alpha * values[index] + (1 - alpha) * estimate;
  }
  return estimate;
}

/// Wilder's Relative Strength Index (RSI), between 0 and 100.
///
/// Above 70 the asset reads as overbought; below 30, as oversold. It needs
/// [period] changes, that is, `period + 1` prices; with fewer it returns null.
double? relativeStrengthIndex(List<double> prices, {int period = 14}) {
  if (period <= 0) throw ArgumentError("period must be positive");
  if (prices.length < period + 1) return null;

  var averageGain = 0.0;
  var averageLoss = 0.0;
  for (var index = 1; index <= period; index++) {
    final change = prices[index] - prices[index - 1];
    if (change >= 0)
      averageGain += change;
    else
      averageLoss -= change;
  }
  averageGain /= period;
  averageLoss /= period;

  // Wilder's smoothing: each new day enters with weight 1/period, without
  // dropping in one go the day that left the window.
  for (var index = period + 1; index < prices.length; index++) {
    final change = prices[index] - prices[index - 1];
    final gain = change > 0 ? change : 0.0;
    final loss = change < 0 ? -change : 0.0;
    averageGain = (averageGain * (period - 1) + gain) / period;
    averageLoss = (averageLoss * (period - 1) + loss) / period;
  }

  // With no losses in the period the index saturates at 100 (and the division
  // by zero never happens).
  if (averageLoss == 0) return averageGain == 0 ? 50.0 : 100.0;
  final relativeStrength = averageGain / averageLoss;
  return 100 - 100 / (1 + relativeStrength);
}

/// Largest drop from a peak to the following trough, as a positive fraction
/// (0.2 = fell 20% from the peak). Zero when the series only rises.
double maxDrawdown(List<double> prices) {
  if (prices.isEmpty) return 0;
  var peak = prices.first;
  var worst = 0.0;
  for (var price in prices) {
    if (price > peak) peak = price;
    if (peak <= 0) continue;
    final drawdown = (peak - price) / peak;
    if (drawdown > worst) worst = drawdown;
  }
  return worst;
}

/// Annualised volatility from daily log-returns: the daily standard deviation
/// times `sqrt(days in a year)`.
///
/// [periodsPerYear] is 252 by default (trading days in a year) — the API
/// series comes in business days. For crypto, which trades every day, the
/// caller passes 365.
double annualizedVolatility(List<double> dailyLogReturns,
    {double periodsPerYear = 252}) {
  if (dailyLogReturns.length < 2) return 0;
  return standardDeviation(dailyLogReturns) * sqrt(periodsPerYear);
}

/// Cumulative percentage change over the last [period] points, as a fraction
/// (0.05 = up 5%). Null when there are not enough points.
double? momentum(List<double> prices, int period) {
  if (period <= 0) throw ArgumentError("period must be positive");
  if (prices.length < period + 1) return null;
  final past = prices[prices.length - 1 - period];
  if (past <= 0) return null;
  return prices.last / past - 1;
}

/// Compound annual growth rate (CAGR) implied between the first and the last
/// price, given the span in calendar days.
double compoundAnnualGrowthRate(
    {required double initialPrice,
    required double finalPrice,
    required int spanInDays,
    double daysPerYear = 365}) {
  if (initialPrice <= 0 || finalPrice <= 0 || spanInDays <= 0) return 0;
  final years = spanInDays / daysPerYear;
  return pow(finalPrice / initialPrice, 1 / years).toDouble() - 1;
}

/// Distance from the current price to the moving average of [period], measured
/// in standard deviations of that same window (the Bollinger bands "z-score").
/// Positive means the price is stretched above the average.
double? bollingerZScore(List<double> prices, int period) {
  if (period <= 1) throw ArgumentError("period must be greater than 1");
  if (prices.length < period) return null;
  final window = prices.sublist(prices.length - period);
  final deviation = standardDeviation(window);
  if (deviation == 0) return 0;
  return (prices.last - mean(window)) / deviation;
}
