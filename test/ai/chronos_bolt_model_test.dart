import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cotacao_direta/ai/chronos/chronos_bolt_model.dart';
import 'package:cotacao_direta/ai/chronos/safetensors.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/chronos_test_helper.dart';

/// Compares the Dart port with the numbers the reference implementation
/// (PyTorch, `chronos-forecasting`) produced for the same weights and contexts
/// — see tool/chronos_reference/generate_fixtures.py.
void main() {
  group('ChronosBoltModel', () {
    final model = loadTinyChronosBolt();
    final expected = jsonDecode(
            File('test/fixtures/chronos_bolt/expected.json').readAsStringSync())
        as Map<String, dynamic>;

    for (final name in expected.keys) {
      test('reproduz a referência do PyTorch: $name', () {
        final entry = expected[name] as Map<String, dynamic>;
        final context = (entry['context'] as List).cast<num>()
            .map((value) => value.toDouble())
            .toList();
        final prediction = model.predict(context);

        _expectQuantiles(prediction, entry['quantiles'] as List);
      });
    }

    test('lê a configuração do checkpoint', () {
      expect(model.config.dModel, 16);
      expect(model.config.innerDim, 8);
      expect(model.config.predictionLength, 32);
      expect(model.config.quantiles, [0.1, 0.5, 0.9]);
      expect(model.parameterCount, greaterThan(0));
    });

    test('interpola quantis entre os níveis treinados', () {
      final prediction = ChronosBoltPrediction([0.1, 0.5, 0.9], [
        Float64List.fromList([1]),
        Float64List.fromList([2]),
        Float64List.fromList([4]),
      ]);

      expect(prediction.median(0), 2);
      expect(prediction.quantile(0.3, 0), closeTo(1.5, 1e-12));
      expect(prediction.quantile(0.7, 0), closeTo(3, 1e-12));
      // Fora da faixa treinada vale o nível mais externo.
      expect(prediction.quantile(0.01, 0), 1);
      expect(prediction.quantile(0.99, 0), 4);
    });

    test('recusa contexto vazio ou com valores não finitos', () {
      expect(() => model.predict(const []), throwsArgumentError);
      expect(() => model.predict([1, double.nan, 2]), throwsArgumentError);
    });
  });

  group('ChronosBoltModel.relativePositionBucket', () {
    // Valores tirados do `T5Attention._relative_position_bucket` do
    // transformers com 32 buckets e distância máxima de 128, a configuração do
    // Chronos-Bolt Tiny.
    const cases = {
      0: 0,
      -1: 1,
      1: 17,
      -7: 7,
      7: 23,
      -8: 8,
      -12: 9,
      -16: 10,
      -32: 12,
      -100: 15,
      -127: 15,
      -128: 15,
      -500: 15,
      500: 31,
    };
    cases.forEach((position, bucket) {
      test('posição $position cai no bucket $bucket', () {
        expect(
            ChronosBoltModel.relativePositionBucket(position,
                numBuckets: 32, maxDistance: 128),
            bucket);
      });
    });
  });

  group('SafeTensors', () {
    test('recusa arquivo truncado', () {
      expect(() => SafeTensors.parse(Uint8List(4)), throwsFormatException);
    });

    test('lê tensores fora do alinhamento de 4 bytes', () {
      final bytes = File('test/fixtures/chronos_bolt/model.safetensors')
          .readAsBytesSync();
      // A mesma sequência começando um byte adiante dentro do buffer.
      final shifted = Uint8List(bytes.length + 1)..setRange(1, bytes.length + 1, bytes);
      final aligned = SafeTensors.parse(bytes);
      final unaligned = SafeTensors.parse(Uint8List.sublistView(shifted, 1));

      final name = aligned.tensors.keys.first;
      expect(unaligned.require(name).data, aligned.require(name).data);
    });

    test('recusa forma diferente da esperada', () {
      final weights = SafeTensors.parse(File(
              'test/fixtures/chronos_bolt/model.safetensors')
          .readAsBytesSync());
      expect(() => weights.require('shared.weight', [3, 16]),
          throwsFormatException);
      expect(() => weights.require('missing'), throwsFormatException);
    });
  });

  // Conferência opcional contra o checkpoint real, baixado do Hugging Face:
  //   CHRONOS_BOLT_TINY_DIR=<pasta> flutter test test/ai/chronos_bolt_model_test.dart
  // A pasta precisa de config.json, model.safetensors e do expected_real.json
  // gerado por `generate_fixtures.py --real-model <pasta>`.
  final realDirectory = Platform.environment['CHRONOS_BOLT_TINY_DIR'];
  group('amazon/chronos-bolt-tiny', () {
    test('reproduz a referência do PyTorch com os pesos reais', () {
      final directory = Directory(realDirectory!);
      final model = ChronosBoltModel.fromBytes(
        jsonDecode(File('${directory.path}/config.json').readAsStringSync())
            as Map<String, dynamic>,
        File('${directory.path}/model.safetensors').readAsBytesSync(),
      );
      final expected = jsonDecode(File('${directory.path}/expected_real.json')
          .readAsStringSync()) as Map<String, dynamic>;
      for (final entry in expected.values) {
        final context = ((entry as Map)['context'] as List)
            .cast<num>()
            .map((value) => value.toDouble())
            .toList();
        final watch = Stopwatch()..start();
        final prediction = model.predict(context);
        // ignore: avoid_print
        print('forward pass with ${context.length} points: '
            '${watch.elapsedMilliseconds} ms');
        _expectQuantiles(prediction, entry['quantiles'] as List);
      }
    });
  }, skip: realDirectory == null ? 'CHRONOS_BOLT_TINY_DIR not set' : false);
}

void _expectQuantiles(ChronosBoltPrediction prediction, List expected) {
  expect(prediction.values.length, expected.length);
  for (var quantile = 0; quantile < expected.length; quantile++) {
    final row = (expected[quantile] as List).cast<num>();
    expect(prediction.values[quantile].length, row.length);
    for (var step = 0; step < row.length; step++) {
      final reference = row[step].toDouble();
      // The reference runs in float32 and the port in float64: they agree to
      // about six significant digits.
      expect(prediction.values[quantile][step],
          closeTo(reference, 1e-4 * (1 + reference.abs())),
          reason: 'quantile $quantile, step $step');
    }
  }
}
