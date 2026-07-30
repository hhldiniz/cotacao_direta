import 'dart:math';

import 'package:cotacao_direta/ai/math/statistics.dart';

/// Indicadores técnicos clássicos calculados sobre a série de preços. São as
/// entradas que o modelo local recebe além dos retornos crus e, ao mesmo tempo,
/// os números que aparecem no resumo de mercado da tela.

/// Média móvel simples dos últimos [period] preços. Devolve nulo quando a série
/// é mais curta que o período: uma média incompleta seria comparada com médias
/// completas em outra escala.
double? simpleMovingAverage(List<double> values, int period) {
  if (period <= 0) throw ArgumentError("período precisa ser positivo");
  if (values.length < period) return null;
  return mean(values.sublist(values.length - period));
}

/// Média móvel exponencial de período [period], no formato usual do mercado
/// (`alpha = 2 / (period + 1)`), semeada pela média simples do primeiro bloco.
double? exponentialMovingAverage(List<double> values, int period) {
  if (period <= 0) throw ArgumentError("período precisa ser positivo");
  if (values.length < period) return null;
  final alpha = 2 / (period + 1);
  var estimate = mean(values.sublist(0, period));
  for (var index = period; index < values.length; index++) {
    estimate = alpha * values[index] + (1 - alpha) * estimate;
  }
  return estimate;
}

/// Índice de Força Relativa (IFR/RSI) de Wilder, entre 0 e 100.
///
/// Acima de 70 o ativo é lido como sobrecomprado; abaixo de 30, sobrevendido.
/// Precisa de [period] variações, isto é, `period + 1` preços; com menos que
/// isso devolve nulo.
double? relativeStrengthIndex(List<double> prices, {int period = 14}) {
  if (period <= 0) throw ArgumentError("período precisa ser positivo");
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

  // Suavização de Wilder: cada dia novo entra com peso 1/period, sem descartar
  // de uma vez o dia que saiu da janela.
  for (var index = period + 1; index < prices.length; index++) {
    final change = prices[index] - prices[index - 1];
    final gain = change > 0 ? change : 0.0;
    final loss = change < 0 ? -change : 0.0;
    averageGain = (averageGain * (period - 1) + gain) / period;
    averageLoss = (averageLoss * (period - 1) + loss) / period;
  }

  // Sem nenhuma perda no período o índice satura em 100 (e a divisão por zero
  // não chega a acontecer).
  if (averageLoss == 0) return averageGain == 0 ? 50.0 : 100.0;
  final relativeStrength = averageGain / averageLoss;
  return 100 - 100 / (1 + relativeStrength);
}

/// Maior queda entre um topo e o vale seguinte, como fração positiva (0,2 =
/// caiu 20% do topo). Zero quando a série só sobe.
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

/// Volatilidade anualizada a partir dos log-retornos diários: o desvio padrão
/// diário multiplicado por `sqrt(dias no ano)`.
///
/// [periodsPerYear] é 252 por padrão (pregões de um ano) — a série da API vem
/// em dias úteis. Para cripto, que negocia todo dia, o chamador passa 365.
double annualizedVolatility(List<double> dailyLogReturns,
    {double periodsPerYear = 252}) {
  if (dailyLogReturns.length < 2) return 0;
  return standardDeviation(dailyLogReturns) * sqrt(periodsPerYear);
}

/// Variação percentual acumulada nos últimos [period] pontos, como fração
/// (0,05 = subiu 5%). Nulo quando não há pontos suficientes.
double? momentum(List<double> prices, int period) {
  if (period <= 0) throw ArgumentError("período precisa ser positivo");
  if (prices.length < period + 1) return null;
  final past = prices[prices.length - 1 - period];
  if (past <= 0) return null;
  return prices.last / past - 1;
}

/// Taxa de crescimento anual composta (CAGR) implícita entre o primeiro e o
/// último preço, dado o intervalo em dias corridos.
double compoundAnnualGrowthRate(
    {required double initialPrice,
    required double finalPrice,
    required int spanInDays,
    double daysPerYear = 365}) {
  if (initialPrice <= 0 || finalPrice <= 0 || spanInDays <= 0) return 0;
  final years = spanInDays / daysPerYear;
  return pow(finalPrice / initialPrice, 1 / years).toDouble() - 1;
}

/// Distância do preço atual à média móvel de [period], medida em desvios
/// padrão da própria janela (o "z-score" das bandas de Bollinger). Positivo
/// quer dizer preço esticado acima da média.
double? bollingerZScore(List<double> prices, int period) {
  if (period <= 1) throw ArgumentError("período precisa ser maior que 1");
  if (prices.length < period) return null;
  final window = prices.sublist(prices.length - period);
  final deviation = standardDeviation(window);
  if (deviation == 0) return 0;
  return (prices.last - mean(window)) / deviation;
}
