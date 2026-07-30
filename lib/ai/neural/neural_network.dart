import 'dart:math';

import 'package:cotacao_direta/ai/math/statistics.dart';

/// Outcome of a training run, for the model to decide how much to trust the
/// network.
class TrainingReport {
  /// Mean squared error on the training set, on the last epoch run.
  final double trainingError;

  /// Mean squared error on the validation set (the tail of the series, which
  /// the network did not see while training). Null when there was no
  /// validation.
  final double? validationError;

  /// Epochs actually run — fewer than the cap when early stopping kicked in.
  final int epochs;

  const TrainingReport(
      {required this.trainingError,
      required this.validationError,
      required this.epochs});
}

/// Dense neural network with a single hidden layer (multilayer perceptron)
/// written in pure Dart, for single-output regression.
///
/// It is small on purpose: with a dozen inputs and half a dozen hidden
/// neurons, training a few hundred epochs over a year of quotes costs a few
/// milliseconds of CPU and a few kilobytes of memory. That is what lets the
/// app's "AI model" be trained and run on the device itself, with no weights
/// to download, no native plugin and no data leaving the phone — including on
/// the web, where there is no real isolate.
///
/// Architecture choices:
/// - `tanh` activation on the hidden layer, centred on zero like the returns
///   the network receives;
/// - linear output, because the target is a return (it can be negative and has
///   no ceiling);
/// - mean squared error as the loss, stochastic gradient descent with
///   per-epoch shuffling and weight decay (L2);
/// - all randomness (initial weights and sample order) comes from a seeded
///   [Random], so the same series always produces the same projection —
///   without that the screen would change its answer on every tap.
class NeuralNetwork {
  final int inputSize;
  final int hiddenSize;

  /// Hidden layer weights: `[neuron][input]`.
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

  /// Xavier/Glorot initialisation: the weight range follows the number of
  /// connections, so the signal does not saturate the `tanh` on the very first
  /// pass.
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
      // tanh(x) = 2 * sigmoid(2x) - 1; dart:math does not ship tanh, so we use
      // the exponential form, guarded against overflow for large |x|.
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

  /// The network's output for a feature vector.
  double predict(List<double> features) {
    if (features.length != inputSize)
      throw ArgumentError("expected $inputSize inputs, "
          "got ${features.length}");
    final activations = _hiddenActivations(features);
    var output = _outputBias;
    for (var neuron = 0; neuron < hiddenSize; neuron++) {
      output += _outputWeights[neuron] * activations[neuron];
    }
    return output;
  }

  List<double> predictAll(List<List<double>> inputs) =>
      inputs.map(predict).toList(growable: false);

  /// Trains by stochastic gradient descent.
  ///
  /// When [validationInputs] is given, training keeps the weights of the best
  /// epoch by validation error and restores them at the end: on a short series
  /// the network memorises the training set within a few dozen epochs, and
  /// without this the projection would come from the memorised fit rather than
  /// from what generalises. [patience] stops training once validation stops
  /// improving.
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
      throw ArgumentError("inputs and targets of different lengths");
    if (inputs.isEmpty) throw ArgumentError("training with no samples");

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

  /// One backpropagation step for a single sample, with loss `0.5 * error²`
  /// (the constant makes the derivative come out as exactly the error).
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
      // Derivative of tanh: 1 - tanh(x)².
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
