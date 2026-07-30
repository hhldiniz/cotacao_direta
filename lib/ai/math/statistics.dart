import 'dart:math';

/// Funções estatísticas usadas pelo modelo local. Ficam separadas do modelo por
/// serem puras: entram números, saem números, sem depender de Flutter nem de
/// rede — o que as deixa testáveis isoladamente e reaproveitáveis pelos
/// indicadores.

/// Média aritmética. Lança se a lista estiver vazia: uma média de nada não tem
/// valor neutro razoável, e todo chamador aqui já sabe quantos pontos tem.
double mean(List<double> values) {
  if (values.isEmpty) throw ArgumentError("mean de uma lista vazia");
  var total = 0.0;
  for (var value in values) total += value;
  return total / values.length;
}

/// Variância amostral (divisor n-1) por padrão; com [sample] falso, a
/// populacional. Com um único ponto não há dispersão a medir: devolve zero.
double variance(List<double> values, {bool sample = true}) {
  if (values.isEmpty) throw ArgumentError("variance de uma lista vazia");
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

/// Retornos logarítmicos da série de preços: `ln(p[i] / p[i-1])`.
///
/// O modelo trabalha em log-retorno, e não em variação percentual, porque eles
/// se somam ao longo do tempo (o retorno de 10 dias é a soma dos 10 diários).
/// É isso que permite projetar vários dias à frente acumulando previsões e
/// abrir a faixa de confiança por `sigma * sqrt(dias)`.
///
/// Preço não positivo interrompe o cálculo naquele ponto: `ln` não existiria e
/// um par de dias sem preço não representa retorno nenhum.
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

/// Reta ajustada por mínimos quadrados, com o R² do ajuste.
class LinearFit {
  final double slope;
  final double intercept;

  /// Fração da variação dos dados explicada pela reta, entre 0 e 1. Vale 0
  /// quando os dados não variam (não há o que explicar).
  final double rSquared;

  const LinearFit(
      {required this.slope, required this.intercept, required this.rSquared});

  double predict(double x) => intercept + slope * x;
}

/// Ajusta `y = intercept + slope * x` por mínimos quadrados.
LinearFit linearFit(List<double> xs, List<double> ys) {
  if (xs.length != ys.length)
    throw ArgumentError("linearFit com listas de tamanhos diferentes");
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

/// Média móvel exponencial de toda a lista, com peso [alpha] no ponto mais
/// recente. É a estimativa de deriva usada como linha de base da projeção:
/// dá mais peso ao passado recente sem descartar o restante da série.
double exponentiallyWeightedMean(List<double> values, {double alpha = 0.15}) {
  if (values.isEmpty) throw ArgumentError("ewm de uma lista vazia");
  var estimate = values.first;
  for (var index = 1; index < values.length; index++) {
    estimate = alpha * values[index] + (1 - alpha) * estimate;
  }
  return estimate;
}

/// Erro quadrático médio entre previsões e alvos.
double meanSquaredError(List<double> predictions, List<double> targets) {
  if (predictions.length != targets.length)
    throw ArgumentError("meanSquaredError com listas de tamanhos diferentes");
  if (predictions.isEmpty) return 0;
  var accumulated = 0.0;
  for (var index = 0; index < predictions.length; index++) {
    final error = predictions[index] - targets[index];
    accumulated += error * error;
  }
  return accumulated / predictions.length;
}

// Coeficientes da aproximação racional de Peter Acklam para o inverso da
// normal padrão, com erro relativo abaixo de 1,15e-9 — folgado para o uso
// aqui, que é converter um nível de confiança (80%, 95%) no multiplicador do
// desvio padrão que abre a faixa da projeção.
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

/// Quantil da normal padrão: o valor `z` tal que `P(Z <= z) = probability`.
double normalQuantile(double probability) {
  if (probability <= 0 || probability >= 1)
    throw ArgumentError("normalQuantile fora do intervalo (0, 1)");

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

/// Multiplicador do desvio padrão que cobre [confidenceLevel] da distribuição
/// em torno da média: 1,96 para 95%, 1,28 para 80%.
double confidenceMultiplier(double confidenceLevel) {
  if (confidenceLevel <= 0 || confidenceLevel >= 1)
    throw ArgumentError("confidenceMultiplier fora do intervalo (0, 1)");
  return normalQuantile(0.5 + confidenceLevel / 2);
}
