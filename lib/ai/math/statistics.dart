import 'dart:math';

/// Statistical helpers used by the local model. They live apart from the model
/// because they are pure: numbers in, numbers out, with no Flutter and no
/// network — which keeps them testable in isolation and reusable by the
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

/// Exponentially weighted mean of the whole list, with weight [alpha] on the
/// most recent point. This is the drift estimate used as the projection's
/// baseline: it favours the recent past without discarding the rest of the
/// series.
double exponentiallyWeightedMean(List<double> values, {double alpha = 0.15}) {
  if (values.isEmpty) throw ArgumentError("ewm of an empty list");
  var estimate = values.first;
  for (var index = 1; index < values.length; index++) {
    estimate = alpha * values[index] + (1 - alpha) * estimate;
  }
  return estimate;
}

/// Mean squared error between predictions and targets.
double meanSquaredError(List<double> predictions, List<double> targets) {
  if (predictions.length != targets.length)
    throw ArgumentError("meanSquaredError with lists of different lengths");
  if (predictions.isEmpty) return 0;
  var accumulated = 0.0;
  for (var index = 0; index < predictions.length; index++) {
    final error = predictions[index] - targets[index];
    accumulated += error * error;
  }
  return accumulated / predictions.length;
}

// Coefficients of Peter Acklam's rational approximation for the inverse of the
// standard normal, with relative error below 1.15e-9 — plenty for the use here,
// which is turning a confidence level (80%, 95%) into the standard deviation
// multiplier that opens the projection band.
const List<double> _lowerCoefficientsA = [
  -3.969683028665376e+01,
  2.209460984245205e+02,
  -2.759285104469687e+02,
  1.383577518672690e+02,
  -3.066479806614716e+01,
  2.506628277459239e+00
];
const List<double> _lowerCoefficientsB = [
  -5.447609879822406e+01,
  1.615858368580409e+02,
  -1.556989798598866e+02,
  6.680131188771972e+01,
  -1.328068155288572e+01
];
const List<double> _tailCoefficientsC = [
  -7.784894002430293e-03,
  -3.223964580411365e-01,
  -2.400758277161838e+00,
  -2.549732539343734e+00,
  4.374664141464968e+00,
  2.938163982698783e+00
];
const List<double> _tailCoefficientsD = [
  7.784695709041462e-03,
  3.224671290700398e-01,
  2.445134137142996e+00,
  3.754408661907416e+00
];

/// Quantile of the standard normal: the value `z` such that
/// `P(Z <= z) = probability`.
double normalQuantile(double probability) {
  if (probability <= 0 || probability >= 1)
    throw ArgumentError("normalQuantile outside the (0, 1) range");

  const lowerBreak = 0.02425;
  const upperBreak = 1 - lowerBreak;

  double tail(double q) =>
      (((((_tailCoefficientsC[0] * q + _tailCoefficientsC[1]) * q +
                                  _tailCoefficientsC[2]) *
                              q +
                          _tailCoefficientsC[3]) *
                      q +
                  _tailCoefficientsC[4]) *
              q +
          _tailCoefficientsC[5]) /
      ((((_tailCoefficientsD[0] * q + _tailCoefficientsD[1]) * q +
                      _tailCoefficientsD[2]) *
                  q +
              _tailCoefficientsD[3]) *
          q +
          1);

  if (probability < lowerBreak) return tail(sqrt(-2 * log(probability)));
  if (probability > upperBreak) return -tail(sqrt(-2 * log(1 - probability)));

  final q = probability - 0.5;
  final r = q * q;
  return (((((_lowerCoefficientsA[0] * r + _lowerCoefficientsA[1]) * r +
                              _lowerCoefficientsA[2]) *
                          r +
                      _lowerCoefficientsA[3]) *
                  r +
              _lowerCoefficientsA[4]) *
          r +
          _lowerCoefficientsA[5]) *
      q /
      (((((_lowerCoefficientsB[0] * r + _lowerCoefficientsB[1]) * r +
                          _lowerCoefficientsB[2]) *
                      r +
                  _lowerCoefficientsB[3]) *
              r +
          _lowerCoefficientsB[4]) *
          r +
          1);
}

/// Standard deviation multiplier covering [confidenceLevel] of the
/// distribution around the mean: 1.96 for 95%, 1.28 for 80%.
double confidenceMultiplier(double confidenceLevel) {
  if (confidenceLevel <= 0 || confidenceLevel >= 1)
    throw ArgumentError("confidenceMultiplier outside the (0, 1) range");
  return normalQuantile(0.5 + confidenceLevel / 2);
}
