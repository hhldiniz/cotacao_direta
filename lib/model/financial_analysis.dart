import 'package:cotacao_direta/model/asset_series.dart';

/// Um dia projetado pelo modelo local, com a faixa de confiança em volta.
class ForecastPoint {
  /// Quantos dias à frente do último ponto observado, começando em 1.
  final int step;
  final DateTime date;

  /// Preço projetado (o centro da faixa).
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

/// O que o treino da rede revelou sobre a própria confiabilidade. Vai para a
/// tela porque muda a leitura da projeção: uma rede que não superou o passeio
/// aleatório está, na prática, repetindo a média.
class ModelDiagnostics {
  /// Amostras (janelas) montadas a partir do histórico para treinar.
  final int trainingSamples;

  /// Erro da rede no trecho de validação.
  final double? validationError;

  /// Erro, no mesmo trecho, de prever "amanhã igual a hoje" — o passeio
  /// aleatório, que é o rival honesto de qualquer previsor de preço.
  final double? baselineError;

  /// `1 - erro da rede / erro do passeio aleatório`, limitado a [0, 1]. Zero
  /// quer dizer que a rede não trouxe informação nenhuma.
  final double skill;

  /// Peso dado à rede na projeção final; o restante fica com a deriva
  /// estatística.
  final double neuralWeight;

  final int epochs;

  /// Falso quando o histórico era curto demais para treinar e a projeção saiu
  /// só da base estatística.
  final bool trained;

  const ModelDiagnostics(
      {required this.trainingSamples,
      required this.validationError,
      required this.baselineError,
      required this.skill,
      required this.neuralWeight,
      required this.epochs,
      required this.trained});

  factory ModelDiagnostics.untrained({int trainingSamples = 0}) =>
      ModelDiagnostics(
          trainingSamples: trainingSamples,
          validationError: null,
          baselineError: null,
          skill: 0,
          neuralWeight: 0,
          epochs: 0,
          trained: false);
}

/// Projeção completa de um ativo.
class AssetForecast {
  final double lastPrice;
  final List<ForecastPoint> points;
  final ModelDiagnostics diagnostics;

  /// Nível de confiança da faixa (0,8 = 80%).
  final double confidenceLevel;

  const AssetForecast(
      {required this.lastPrice,
      required this.points,
      required this.diagnostics,
      required this.confidenceLevel});

  int get horizonInDays => points.isEmpty ? 0 : points.last.step;

  /// Preço no fim do horizonte projetado.
  double get projectedPrice => points.isEmpty ? lastPrice : points.last.price;

  double get projectedLowerBound =>
      points.isEmpty ? lastPrice : points.last.lowerBound;

  double get projectedUpperBound =>
      points.isEmpty ? lastPrice : points.last.upperBound;

  /// Variação projetada como fração (0,03 = alta de 3%).
  double get projectedChange =>
      lastPrice <= 0 ? 0 : projectedPrice / lastPrice - 1;

  /// Quanto [amount] investido hoje valeria no fim do horizonte, com a mesma
  /// faixa de confiança da projeção de preço.
  ///
  /// É uma regra de três sobre a variação projetada — o "manuseio financeiro"
  /// que a tela oferece por cima do modelo.
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

/// Simulação de um valor aplicado hoje, projetado para o fim do horizonte.
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

/// Retrato estatístico da série, mostrado no resumo de mercado e usado pelos
/// insights. Os campos opcionais ficam nulos quando o histórico é curto demais
/// para o indicador (o IFR precisa de 15 pontos, a variação de 30 dias precisa
/// de 31, e assim por diante).
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

  /// Inclinação da reta ajustada sobre o log dos preços, em log-retorno por
  /// dia, com o R² do ajuste: quanto da variação a tendência explica.
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

  /// Variação do período mais longo disponível, para os insights de tendência.
  double? get referenceChange => monthlyChange ?? weeklyChange;

  /// Média curta acima da longa é o cruzamento clássico de alta.
  bool? get shortAboveLong =>
      shortMovingAverage == null || longMovingAverage == null
          ? null
          : shortMovingAverage! > longMovingAverage!;
}

/// O que a rede acha digno de nota. O texto não vem pronto: o código identifica
/// o tipo de observação e [arguments] traz os números já formatados no idioma
/// pedido, que a tela encaixa no modelo de frase traduzido.
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

/// Tom da observação, para a tela escolher ícone e cor.
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

/// Tudo o que a análise local produz para um ativo.
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
