import 'dart:math';

import 'package:cotacao_direta/ai/neural/neural_network.dart';
import 'package:flutter_test/flutter_test.dart';

/// Amostras de uma função conhecida, para verificar que a rede aprende de fato
/// em vez de apenas rodar sem erro.
({List<List<double>> inputs, List<double> targets}) _samples(
    double Function(double, double) function,
    {int count = 200,
    int seed = 3}) {
  final random = Random(seed);
  final inputs = <List<double>>[];
  final targets = <double>[];
  for (var index = 0; index < count; index++) {
    final first = random.nextDouble() * 2 - 1;
    final second = random.nextDouble() * 2 - 1;
    inputs.add([first, second]);
    targets.add(function(first, second));
  }
  return (inputs: inputs, targets: targets);
}

void main() {
  group('NeuralNetwork', () {
    test('aprende uma relação linear', () {
      final data = _samples((first, second) => 0.5 * first - 0.3 * second);
      final network = NeuralNetwork(inputSize: 2, hiddenSize: 6);

      final report = network.train(data.inputs, data.targets,
          epochs: 300, learningRate: 0.05);

      expect(report.trainingError, lessThan(1e-3));
      expect(network.predict([1, 0]), closeTo(0.5, 0.1));
      expect(network.predict([0, 1]), closeTo(-0.3, 0.1));
    });

    test('aprende uma relação não linear, que uma reta não daria conta', () {
      final data = _samples((first, second) => first * second);
      final network = NeuralNetwork(inputSize: 2, hiddenSize: 8);

      final report = network.train(data.inputs, data.targets,
          epochs: 400, learningRate: 0.05);

      expect(report.trainingError, lessThan(0.01));
      expect(network.predict([0.8, 0.8]), closeTo(0.64, 0.15));
      expect(network.predict([-0.8, 0.8]), closeTo(-0.64, 0.15));
    });

    test('a mesma semente produz a mesma rede', () {
      final data = _samples((first, second) => 0.5 * first - 0.3 * second);
      final first = NeuralNetwork(inputSize: 2, hiddenSize: 5, seed: 11)
        ..train(data.inputs, data.targets, epochs: 40);
      final second = NeuralNetwork(inputSize: 2, hiddenSize: 5, seed: 11)
        ..train(data.inputs, data.targets, epochs: 40);

      expect(first.predict([0.3, -0.7]), second.predict([0.3, -0.7]));
    });

    test('sementes diferentes produzem redes diferentes', () {
      final data = _samples((first, second) => 0.5 * first - 0.3 * second);
      final first = NeuralNetwork(inputSize: 2, hiddenSize: 5, seed: 11)
        ..train(data.inputs, data.targets, epochs: 5);
      final second = NeuralNetwork(inputSize: 2, hiddenSize: 5, seed: 12)
        ..train(data.inputs, data.targets, epochs: 5);

      expect(first.predict([0.3, -0.7]),
          isNot(closeTo(second.predict([0.3, -0.7]), 1e-12)));
    });

    test('mede o erro no conjunto de validação', () {
      final data = _samples((first, second) => 0.5 * first - 0.3 * second);
      final network = NeuralNetwork(inputSize: 2, hiddenSize: 6);

      final report = network.train(
        data.inputs.sublist(0, 150),
        data.targets.sublist(0, 150),
        validationInputs: data.inputs.sublist(150),
        validationTargets: data.targets.sublist(150),
        epochs: 200,
        learningRate: 0.05,
      );

      expect(report.validationError, isNotNull);
      expect(report.validationError!, lessThan(1e-2));
    });

    test('sem validação não há erro de validação a reportar', () {
      final data = _samples((first, second) => first + second, count: 30);
      final network = NeuralNetwork(inputSize: 2, hiddenSize: 4);

      final report = network.train(data.inputs, data.targets, epochs: 10);

      expect(report.validationError, isNull);
      expect(report.epochs, 10);
    });

    test('a parada antecipada encurta o treino quando a validação empaca', () {
      // Alvo puramente aleatório: não há o que aprender, então a validação para
      // de melhorar cedo.
      final random = Random(5);
      final inputs = List.generate(
          80, (_) => [random.nextDouble(), random.nextDouble()]);
      final targets = List.generate(80, (_) => random.nextDouble() * 2 - 1);
      final network = NeuralNetwork(inputSize: 2, hiddenSize: 6);

      final report = network.train(
        inputs.sublist(0, 60),
        targets.sublist(0, 60),
        validationInputs: inputs.sublist(60),
        validationTargets: targets.sublist(60),
        epochs: 2000,
        learningRate: 0.05,
        patience: 10,
      );

      expect(report.epochs, lessThan(2000));
    });

    test('recusa entradas e alvos de tamanhos diferentes', () {
      final network = NeuralNetwork(inputSize: 2, hiddenSize: 3);

      expect(
          () => network.train([
                [1, 2]
              ], [
                1,
                2
              ]),
          throwsArgumentError);
    });

    test('recusa treino sem amostras', () {
      final network = NeuralNetwork(inputSize: 2, hiddenSize: 3);

      expect(() => network.train([], []), throwsArgumentError);
    });

    test('recusa um vetor de entrada com o tamanho errado', () {
      final network = NeuralNetwork(inputSize: 3, hiddenSize: 3);

      expect(() => network.predict([1, 2]), throwsArgumentError);
    });

    test('a rede recém-criada já responde sem treino', () {
      final network = NeuralNetwork(inputSize: 3, hiddenSize: 4);

      expect(network.predict([0.1, 0.2, 0.3]).isFinite, isTrue);
    });

    test('entradas extremas não estouram a ativação', () {
      final network = NeuralNetwork(inputSize: 2, hiddenSize: 4);

      expect(network.predict([1e6, -1e6]).isFinite, isTrue);
    });
  });
}
