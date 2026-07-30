import 'dart:math';

import 'package:cotacao_direta/ai/math/indicators.dart';
import 'package:cotacao_direta/ai/math/statistics.dart';
import 'package:cotacao_direta/ai/neural/neural_network.dart';
import 'package:cotacao_direta/model/asset_series.dart';
import 'package:cotacao_direta/model/financial_analysis.dart';

/// Modelo preditivo que roda inteiramente no aparelho.
///
/// Ele junta duas peças que se cobrem:
///
/// 1. uma rede neural pequena ([NeuralNetwork]) treinada na hora, com o próprio
///    histórico do ativo que o usuário abriu — sem pesos baixados e sem
///    servidor. Ela recebe uma janela de log-retornos recentes mais alguns
///    indicadores (momento, IFR, distância da média, aceleração da
///    volatilidade) e tenta prever o retorno do dia seguinte;
/// 2. uma deriva estatística, que é a média exponencial dos log-retornos com
///    amortecimento ao longo do horizonte.
///
/// A projeção final é a média ponderada das duas, e o peso da rede não é
/// arbitrário: ele sai do quanto ela superou, num trecho de validação que não
/// viu no treino, o passeio aleatório ("amanhã é igual a hoje"). Preço de ativo
/// é quase um passeio aleatório, então esse rival é vencido por pouco quando é
/// vencido; quando não é, o peso vai a zero e a projeção vira a base
/// estatística. Isso mantém a tela honesta em vez de vender uma precisão que o
/// modelo não tem.
///
/// A faixa de confiança vem do modelo de caminhada aleatória em log-preço: o
/// desvio padrão acumulado cresce com `sigma * sqrt(dias)`, e o multiplicador
/// sai do quantil da normal para o nível de confiança pedido.
class LocalFinancialModel {
  /// Quantos log-retornos recentes entram no vetor de características.
  final int window;

  final int hiddenUnits;
  final int epochs;
  final double learningRate;
  final double weightDecay;

  /// Semente da aleatoriedade do treino. Fixa de propósito: a mesma série tem
  /// que produzir sempre a mesma projeção, senão a tela mudaria de resposta a
  /// cada toque no botão.
  final int seed;

  /// Nível da faixa mostrada em volta da projeção (0,8 = 80%).
  final double confidenceLevel;

  /// Teto do peso da rede na mistura. Mesmo uma rede que se saia muito bem na
  /// validação não passa daqui: a validação é curta e o excesso de confiança é
  /// o erro clássico deste tipo de previsão.
  final double maximumNeuralWeight;

  static const int _rsiPeriod = 14;
  static const int _rsiLookback = 60;
  static const int _movingAveragePeriod = 10;
  static const int _momentumPeriod = 5;
  static const int _volatilityPeriod = 5;

  /// Abaixo disto não vale treinar: a rede decoraria as poucas janelas
  /// existentes e a validação não diria nada.
  static const int minimumTrainingSamples = 24;

  /// Amortecimento da deriva a cada dia projetado. Sem ele, uma tendência
  /// recente de alta seria extrapolada em linha reta até o fim do horizonte.
  static const double _driftDamping = 0.92;

  /// Teto do movimento diário projetado, em desvios padrão. Segura a projeção
  /// dentro do que a série costuma fazer.
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

  /// Tamanho do vetor de características: a janela de retornos mais os quatro
  /// indicadores derivados.
  int get featureCount => window + 4;

  /// Primeiro índice da série que tem passado suficiente para virar amostra.
  int get _firstUsableIndex =>
      max(window, max(_rsiPeriod + 1, _movingAveragePeriod));

  /// Menor histórico que permite treinar a rede.
  int get minimumHistoryForTraining =>
      _firstUsableIndex + minimumTrainingSamples + 1;

  /// Projeta [horizonInDays] dias à frente do último ponto de [series].
  AssetForecast forecast(AssetSeries series, {int horizonInDays = 15}) {
    if (series.isEmpty) throw ArgumentError("forecast de uma série vazia");
    if (horizonInDays <= 0)
      throw ArgumentError("horizonte precisa ser positivo");

    final prices = series.prices.toList();
    final returns = logReturns(prices);

    // Escala de referência da série. Todas as características e o alvo são
    // divididos por ela, o que deixa a rede vendo números da ordem de 1 tanto
    // para um par de moedas calmo quanto para uma cripto. O piso evita divisão
    // por zero numa série sem variação (uma moeda cotada contra ela mesma, por
    // exemplo).
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

      // Incerteza da caminhada aleatória: cresce com a raiz do número de dias.
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

  /// Janelas de treino montadas a partir da série: cada amostra são as
  /// características no dia `index` e, como alvo, o log-retorno do dia
  /// seguinte.
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

  /// Características do dia [index], todas em unidades de [scale] e limitadas a
  /// [-4, 4] para que um dia excepcional não domine o treino.
  List<double>? _features(List<double> prices, int index, double scale) {
    if (index < _firstUsableIndex || index >= prices.length) return null;

    final features = <double>[];

    // Os log-retornos mais recentes, do dia [index] para trás.
    for (var lag = 0; lag < window; lag++) {
      final current = prices[index - lag];
      final previous = prices[index - lag - 1];
      if (current <= 0 || previous <= 0) return null;
      features.add(log(current / previous) / scale);
    }

    // Momento: o retorno acumulado da janela curta, normalizado pela
    // volatilidade esperada nesse número de dias.
    final momentumBase = prices[index - _momentumPeriod];
    if (momentumBase <= 0 || prices[index] <= 0) return null;
    features.add(log(prices[index] / momentumBase) /
        (scale * sqrt(_momentumPeriod.toDouble())));

    // IFR centrado em zero. A janela de apuração é fixa para que a
    // característica signifique o mesmo no começo e no fim da série.
    final rsiWindow = prices.sublist(
        max(0, index + 1 - _rsiLookback), index + 1);
    final rsi = relativeStrengthIndex(rsiWindow, period: _rsiPeriod) ?? 50;
    features.add((rsi - 50) / 50);

    // Distância da média móvel, em desvios padrão da janela (bandas de
    // Bollinger), reduzida para a mesma ordem de grandeza das demais.
    final zScore = bollingerZScore(
            prices.sublist(index + 1 - _movingAveragePeriod, index + 1),
            _movingAveragePeriod) ??
        0;
    features.add(zScore / 3);

    // Aceleração da volatilidade: quanto a agitação dos últimos dias difere da
    // agitação típica da série.
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

  /// Treina a rede e mede o quanto ela superou o passeio aleatório.
  _TrainedModel _train(_TrainingData data) {
    if (data.inputs.length < minimumTrainingSamples) {
      return _TrainedModel(
          null, ModelDiagnostics.untrained(trainingSamples: data.inputs.length));
    }

    // A validação é o trecho final da série, e não uma amostra sorteada: prever
    // um dia no meio de dias vizinhos já conhecidos é bem mais fácil do que
    // prever o futuro, e daria uma nota inflada.
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

    // O passeio aleatório prevê retorno zero para o dia seguinte.
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
  /// Nulo quando não houve histórico suficiente para treinar.
  final NeuralNetwork? network;
  final ModelDiagnostics diagnostics;

  const _TrainedModel(this.network, this.diagnostics);
}
