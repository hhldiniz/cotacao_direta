import 'dart:math';

import 'package:cotacao_direta/ai/math/statistics.dart';

/// Resultado de um treino, para o modelo decidir o quanto confiar na rede.
class TrainingReport {
  /// Erro quadrático médio no conjunto de treino, na última época rodada.
  final double trainingError;

  /// Erro quadrático médio no conjunto de validação (o trecho final da série,
  /// que a rede não viu no treino). É nulo quando não houve validação.
  final double? validationError;

  /// Épocas efetivamente rodadas — menos que o teto quando a parada antecipada
  /// entrou em ação.
  final int epochs;

  const TrainingReport(
      {required this.trainingError,
      required this.validationError,
      required this.epochs});
}

/// Rede neural densa de uma camada escondida (perceptron multicamada) escrita
/// em Dart puro, para regressão de uma saída.
///
/// É pequena de propósito: com uma dezena de entradas e meia dúzia de neurônios
/// escondidos, treinar algumas centenas de épocas sobre um ano de cotações
/// custa poucos milissegundos de CPU e alguns kilobytes de memória. Isso é o
/// que permite que o "modelo de IA" do app seja treinado e executado no próprio
/// aparelho, sem baixar pesos, sem plugin nativo e sem enviar dado nenhum para
/// fora — inclusive na web, onde não há isolate de verdade.
///
/// Escolhas de arquitetura:
/// - ativação `tanh` na camada escondida, centrada em zero como os retornos que
///   a rede recebe;
/// - saída linear, porque o alvo é um retorno (pode ser negativo e não tem
///   teto);
/// - erro quadrático médio como perda, gradiente descendente estocástico com
///   embaralhamento por época e decaimento de pesos (L2);
/// - toda a aleatoriedade (pesos iniciais e ordem das amostras) sai de um
///   [Random] semeado, então a mesma série produz sempre a mesma projeção —
///   sem isso a tela mudaria de resposta a cada toque no botão.
class NeuralNetwork {
  final int inputSize;
  final int hiddenSize;

  /// Pesos da camada escondida: `[neurônio][entrada]`.
  final List<List<double>> _hiddenWeights;
  final List<double> _hiddenBiases;
  final List<double> _outputWeights;
  double _outputBias;

  final Random _random;

  NeuralNetwork({required this.inputSize, required this.hiddenSize, int seed = 7})
      : assert(inputSize > 0),
        assert(hiddenSize > 0),
        _random = Random(seed),
        _hiddenWeights = List.generate(
            hiddenSize, (_) => List<double>.filled(inputSize, 0),
            growable: false),
        _hiddenBiases = List<double>.filled(hiddenSize, 0),
        _outputWeights = List<double>.filled(hiddenSize, 0),
        _outputBias = 0 {
    _initializeWeights();
  }

  /// Inicialização de Xavier/Glorot: a faixa dos pesos acompanha o número de
  /// conexões, para o sinal não saturar a `tanh` já na primeira passada.
  void _initializeWeights() {
    final hiddenLimit = sqrt(6 / (inputSize + hiddenSize));
    for (var neuron = 0; neuron < hiddenSize; neuron++) {
      for (var input = 0; input < inputSize; input++) {
        _hiddenWeights[neuron][input] =
            (_random.nextDouble() * 2 - 1) * hiddenLimit;
      }
      _hiddenBiases[neuron] = 0;
    }
    final outputLimit = sqrt(6 / (hiddenSize + 1));
    for (var neuron = 0; neuron < hiddenSize; neuron++) {
      _outputWeights[neuron] = (_random.nextDouble() * 2 - 1) * outputLimit;
    }
    _outputBias = 0;
  }

  List<double> _hiddenActivations(List<double> features) {
    final activations = List<double>.filled(hiddenSize, 0);
    for (var neuron = 0; neuron < hiddenSize; neuron++) {
      var sum = _hiddenBiases[neuron];
      final weights = _hiddenWeights[neuron];
      for (var input = 0; input < inputSize; input++) {
        sum += weights[input] * features[input];
      }
      // tanh(x) = 2 * sigmoide(2x) - 1; dart:math não traz tanh, então usamos
      // a forma com exponencial, protegida contra estouro para |x| grande.
      activations[neuron] = _hyperbolicTangent(sum);
    }
    return activations;
  }

  static double _hyperbolicTangent(double value) {
    if (value > 20) return 1;
    if (value < -20) return -1;
    final positive = exp(value);
    final negative = exp(-value);
    return (positive - negative) / (positive + negative);
  }

  /// Saída da rede para um vetor de características.
  double predict(List<double> features) {
    if (features.length != inputSize)
      throw ArgumentError("esperadas $inputSize entradas, "
          "recebidas ${features.length}");
    final activations = _hiddenActivations(features);
    var output = _outputBias;
    for (var neuron = 0; neuron < hiddenSize; neuron++) {
      output += _outputWeights[neuron] * activations[neuron];
    }
    return output;
  }

  List<double> predictAll(List<List<double>> inputs) =>
      inputs.map(predict).toList(growable: false);

  /// Treina por gradiente descendente estocástico.
  ///
  /// Quando [validationInputs] é informado, o treino guarda os pesos da melhor
  /// época segundo o erro de validação e os restaura no fim: numa série curta a
  /// rede decora o treino em poucas dezenas de épocas, e sem isso a projeção
  /// sairia do ajuste memorizado em vez do que generaliza. [patience] encerra o
  /// treino quando a validação para de melhorar.
  TrainingReport train(
    List<List<double>> inputs,
    List<double> targets, {
    List<List<double>>? validationInputs,
    List<double>? validationTargets,
    int epochs = 250,
    double learningRate = 0.02,
    double weightDecay = 1e-4,
    int patience = 40,
  }) {
    if (inputs.length != targets.length)
      throw ArgumentError("entradas e alvos com tamanhos diferentes");
    if (inputs.isEmpty) throw ArgumentError("treino sem amostras");

    final validates = validationInputs != null &&
        validationTargets != null &&
        validationInputs.isNotEmpty;

    final order = List<int>.generate(inputs.length, (index) => index);
    var bestValidationError = double.infinity;
    var bestWeights = validates ? _snapshot() : null;
    var epochsWithoutImprovement = 0;
    var epochsRun = 0;

    for (var epoch = 0; epoch < epochs; epoch++) {
      order.shuffle(_random);
      for (var index in order) {
        _applyGradient(inputs[index], targets[index], learningRate, weightDecay);
      }
      epochsRun++;

      if (!validates) continue;
      final validationError =
          meanSquaredError(predictAll(validationInputs), validationTargets);
      if (validationError < bestValidationError - 1e-9) {
        bestValidationError = validationError;
        bestWeights = _snapshot();
        epochsWithoutImprovement = 0;
      } else if (++epochsWithoutImprovement >= patience) {
        break;
      }
    }

    if (validates && bestWeights != null) _restore(bestWeights);

    return TrainingReport(
      trainingError: meanSquaredError(predictAll(inputs), targets),
      validationError: validates
          ? meanSquaredError(predictAll(validationInputs), validationTargets)
          : null,
      epochs: epochsRun,
    );
  }

  /// Um passo de retropropagação para uma amostra, com a perda `0,5 * erro²`
  /// (a constante deixa a derivada valendo exatamente o erro).
  void _applyGradient(List<double> features, double target, double learningRate,
      double weightDecay) {
    final activations = _hiddenActivations(features);
    var output = _outputBias;
    for (var neuron = 0; neuron < hiddenSize; neuron++) {
      output += _outputWeights[neuron] * activations[neuron];
    }
    final outputDelta = output - target;

    for (var neuron = 0; neuron < hiddenSize; neuron++) {
      final activation = activations[neuron];
      // Derivada da tanh: 1 - tanh(x)².
      final hiddenDelta =
          outputDelta * _outputWeights[neuron] * (1 - activation * activation);

      _outputWeights[neuron] -= learningRate *
          (outputDelta * activation + weightDecay * _outputWeights[neuron]);

      final weights = _hiddenWeights[neuron];
      for (var input = 0; input < inputSize; input++) {
        weights[input] -= learningRate *
            (hiddenDelta * features[input] + weightDecay * weights[input]);
      }
      _hiddenBiases[neuron] -= learningRate * hiddenDelta;
    }
    _outputBias -= learningRate * outputDelta;
  }

  _Weights _snapshot() => _Weights(
        hiddenWeights: _hiddenWeights
            .map((weights) => List<double>.from(weights))
            .toList(growable: false),
        hiddenBiases: List<double>.from(_hiddenBiases),
        outputWeights: List<double>.from(_outputWeights),
        outputBias: _outputBias,
      );

  void _restore(_Weights weights) {
    for (var neuron = 0; neuron < hiddenSize; neuron++) {
      _hiddenWeights[neuron].setAll(0, weights.hiddenWeights[neuron]);
      _hiddenBiases[neuron] = weights.hiddenBiases[neuron];
      _outputWeights[neuron] = weights.outputWeights[neuron];
    }
    _outputBias = weights.outputBias;
  }
}

class _Weights {
  final List<List<double>> hiddenWeights;
  final List<double> hiddenBiases;
  final List<double> outputWeights;
  final double outputBias;

  const _Weights(
      {required this.hiddenWeights,
      required this.hiddenBiases,
      required this.outputWeights,
      required this.outputBias});
}
