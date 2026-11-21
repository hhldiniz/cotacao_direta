import 'dart:math';

/// Statistical helpers behind the market summary. They live apart from the
/// analysis because they are pure: numbers in, numbers out, with no Flutter and
/// no network — which keeps them testable in isolation and reusable by the
/// indicators.

/// Arithmetic mean. Throws on an empty list: the mean of nothing has no
/// sensible neutral value, and every caller here already knows how many points
/// it has.
double mean(List<double> values) {
  if (values.isEmpty) throw ArgumentError("mean of an empty list");
  var total = 0.0;
  for (var value in values) total += value;
  return total / values.length;
}

/// Sample variance (divisor n-1) by default; with [sample] false, the
/// population one. A single point has no dispersion to measure: returns zero.
double variance(List<double> values, {bool sample = true}) {
  if (values.isEmpty) throw ArgumentError("variance of an empty list");
  if (values.length == 1) return 0;
  final average = mean(values);
  var accumulated = 0.0;
  for (var value in values) {
    final deviation = value - average;
    accumulated += deviation * deviation;
  }
  return accumulated / (sample ? values.length - 1 : values.length);
}

double standardDeviation(List<double> values, {bool sample = true}) =>
    sqrt(variance(values, sample: sample));

/// Logarithmic returns of the price series: `ln(p[i] / p[i-1])`.
///
/// The model works in log-returns rather than percentage changes because they
/// add up over time (a 10-day return is the sum of the 10 daily ones). That is
/// what allows projecting several days ahead by accumulating predictions, and
/// widening the confidence band by `sigma * sqrt(days)`.
///
/// A non-positive price interrupts the calculation at that point: `ln` would
/// not exist, and a pair of days without a price is no return at all.
List<double> logReturns(List<double> prices) {
  final returns = <double>[];
  for (var index = 1; index < prices.length; index++) {
    final previous = prices[index - 1];
    final current = prices[index];
    if (previous <= 0 || current <= 0) continue;
    returns.add(log(current / previous));
  }
  return returns;
}

/// Least-squares fitted line, with the R² of the fit.
class LinearFit {
  final double slope;
  final double intercept;

  /// Share of the data's variation explained by the line, between 0 and 1. It
  /// is 0 when the data does not vary (there is nothing to explain).
  final double rSquared;

  const LinearFit(
      {required this.slope, required this.intercept, required this.rSquared});

  double predict(double x) => intercept + slope * x;
}

/// Fits `y = intercept + slope * x` by least squares.
LinearFit linearFit(List<double> xs, List<double> ys) {
  if (xs.length != ys.length)
    throw ArgumentError("linearFit with lists of different lengths");
  if (xs.length < 2)
    return const LinearFit(slope: 0, intercept: 0, rSquared: 0);

  final meanX = mean(xs);
  final meanY = mean(ys);
  var covariance = 0.0;
  var varianceX = 0.0;
  for (var index = 0; index < xs.length; index++) {
    final deviationX = xs[index] - meanX;
    covariance += deviationX * (ys[index] - meanY);
    varianceX += deviationX * deviationX;
  }
  if (varianceX == 0)
    return LinearFit(slope: 0, intercept: meanY, rSquared: 0);

  final slope = covariance / varianceX;
  final intercept = meanY - slope * meanX;

  var residualSum = 0.0;
  var totalSum = 0.0;
  for (var index = 0; index < xs.length; index++) {
    final residual = ys[index] - (intercept + slope * xs[index]);
    final deviationY = ys[index] - meanY;
    residualSum += residual * residual;
    totalSum += deviationY * deviationY;
  }
  final rSquared =
      totalSum == 0 ? 0.0 : (1 - residualSum / totalSum).clamp(0.0, 1.0);
  return LinearFit(slope: slope, intercept: intercept, rSquared: rSquared);
}
