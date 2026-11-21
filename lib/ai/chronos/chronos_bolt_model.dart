import 'dart:math';
import 'dart:typed_data';

import 'package:cotacao_direta/ai/chronos/safetensors.dart';

/// Hyperparameters of a Chronos-Bolt checkpoint, read from the `config.json`
/// published next to the weights.
///
/// Chronos-Bolt is a T5 encoder-decoder: the T5 fields describe the
/// transformer, and `chronos_config` describes how the series is cut into
/// patches and which quantiles come out.
class ChronosBoltConfig {
  final int dModel;
  final int dFf;
  final int dKv;
  final int numHeads;
  final int numLayers;
  final int numDecoderLayers;
  final int relativeAttentionNumBuckets;
  final int relativeAttentionMaxDistance;
  final double layerNormEpsilon;
  final int decoderStartTokenId;
  final int regTokenId;

  /// Longest context the model reads; older points are dropped.
  final int contextLength;

  /// How many steps one forward pass predicts.
  final int predictionLength;
  final int inputPatchSize;
  final int inputPatchStride;
  final List<double> quantiles;
  final bool useRegToken;

  const ChronosBoltConfig({
    required this.dModel,
    required this.dFf,
    required this.dKv,
    required this.numHeads,
    required this.numLayers,
    required this.numDecoderLayers,
    required this.relativeAttentionNumBuckets,
    required this.relativeAttentionMaxDistance,
    required this.layerNormEpsilon,
    required this.decoderStartTokenId,
    required this.regTokenId,
    required this.contextLength,
    required this.predictionLength,
    required this.inputPatchSize,
    required this.inputPatchStride,
    required this.quantiles,
    required this.useRegToken,
  });

  factory ChronosBoltConfig.fromJson(Map<String, dynamic> json) {
    final chronos = json["chronos_config"];
    if (chronos is! Map<String, dynamic>)
      throw const FormatException("not a Chronos-Bolt config");

    // The port implements the plain T5 feed-forward (ReLU, not gated) that the
    // published Chronos-Bolt checkpoints use. Anything else would be computed
    // wrong in silence, so it is refused up front.
    final feedForward = json["feed_forward_proj"] ?? "relu";
    if (feedForward != "relu" || json["is_gated_act"] == true)
      throw FormatException("unsupported feed_forward_proj $feedForward");
    if ((json["dense_act_fn"] ?? "relu") != "relu")
      throw FormatException("unsupported dense_act_fn ${json["dense_act_fn"]}");

    final patchSize = chronos["input_patch_size"] as int;
    final patchStride = chronos["input_patch_stride"] as int;
    if (patchSize != patchStride)
      throw const FormatException("overlapping patches are not supported");

    final numLayers = json["num_layers"] as int;
    return ChronosBoltConfig(
      dModel: json["d_model"] as int,
      dFf: json["d_ff"] as int,
      dKv: json["d_kv"] as int,
      numHeads: json["num_heads"] as int,
      numLayers: numLayers,
      numDecoderLayers: (json["num_decoder_layers"] as int?) ?? numLayers,
      relativeAttentionNumBuckets:
          (json["relative_attention_num_buckets"] as int?) ?? 32,
      relativeAttentionMaxDistance:
          (json["relative_attention_max_distance"] as int?) ?? 128,
      layerNormEpsilon:
          ((json["layer_norm_epsilon"] as num?) ?? 1e-6).toDouble(),
      decoderStartTokenId: (json["decoder_start_token_id"] as int?) ?? 0,
      regTokenId: (json["reg_token_id"] as int?) ?? 1,
      contextLength: chronos["context_length"] as int,
      predictionLength: chronos["prediction_length"] as int,
      inputPatchSize: patchSize,
      inputPatchStride: patchStride,
      quantiles: List.unmodifiable((chronos["quantiles"] as List)
          .map((value) => (value as num).toDouble())),
      useRegToken: (chronos["use_reg_token"] as bool?) ?? false,
    );
  }

  int get innerDim => numHeads * dKv;
}

/// Output of one forward pass: for each quantile level, the predicted value of
/// each of the next [ChronosBoltConfig.predictionLength] steps, already in the
/// scale of the input series.
class ChronosBoltPrediction {
  final List<double> quantileLevels;

  /// `values[q][h]`: quantile `quantileLevels[q]` of step `h + 1`.
  final List<Float64List> values;

  const ChronosBoltPrediction(this.quantileLevels, this.values);

  int get length => values.isEmpty ? 0 : values.first.length;

  /// Value at quantile [level] of step [step] (0-based), interpolated linearly
  /// between the levels the model was trained on. Levels outside that range
  /// are clamped to the outermost ones, as the reference pipeline does.
  double quantile(double level, int step) {
    final levels = quantileLevels;
    if (level <= levels.first) return values.first[step];
    if (level >= levels.last) return values.last[step];
    for (var index = 1; index < levels.length; index++) {
      if (level <= levels[index]) {
        final lowLevel = levels[index - 1];
        final fraction = (level - lowLevel) / (levels[index] - lowLevel);
        final low = values[index - 1][step];
        return low + fraction * (values[index][step] - low);
      }
    }
    return values.last[step];
  }

  /// Median of step [step] (0-based): the point forecast.
  double median(int step) => quantile(0.5, step);
}

/// Chronos-Bolt forward pass, written in plain Dart.
///
/// Chronos-Bolt (Amazon, Apache-2.0) is a time-series foundation model: it was
/// pre-trained on a large and varied collection of real series and forecasts a
/// new series "zero-shot", with no training on the device. The app uses the
/// Tiny variant (9M parameters, 35 MB in float32), which runs in a few dozen
/// milliseconds on an entry-level phone and needs no GPU or NPU.
///
/// The port follows `ChronosBoltModelForForecasting` from the
/// `chronos-forecasting` package and the T5 code of `transformers`:
///
/// 1. the context is standardised (mean and standard deviation of the context
///    itself), left-padded to a whole number of patches and cut into patches
///    of 16 points;
/// 2. each patch, together with its observed/missing mask, goes through a
///    residual MLP and becomes one token; a learned [REG] token is appended;
/// 3. a T5 encoder (relative-position attention, RMS layer norm, no attention
///    scaling) reads the tokens;
/// 4. a T5 decoder with a single start token attends to the encoder output;
/// 5. a residual MLP turns the decoder output into every quantile of every
///    step at once, which are de-standardised.
///
/// Doing it in Dart rather than through a native runtime keeps the model
/// working the same way on every platform the app ships to — Android, Linux,
/// Ubuntu Touch and the web — with no binary dependency. The test suite pins
/// the port to the reference implementation (see
/// tool/chronos_reference/generate_fixtures.py).
class ChronosBoltModel {
  final ChronosBoltConfig config;
  final SafeTensors _weights;

  // Weights resolved once, so the forward pass does no map lookups.
  late final _ResidualBlock _inputEmbedding;
  late final _ResidualBlock _outputEmbedding;
  late final Float32List _shared;
  late final List<_EncoderLayer> _encoderLayers;
  late final List<_DecoderLayer> _decoderLayers;
  late final Float32List _encoderRelativeBias;
  late final Float32List _encoderFinalNorm;
  late final Float32List _decoderFinalNorm;

  ChronosBoltModel(this.config, this._weights) {
    final c = config;
    final d = c.dModel;
    final inner = c.innerDim;
    _inputEmbedding = _ResidualBlock.load(
        _weights, "input_patch_embedding", c.inputPatchSize * 2, c.dFf, d);
    _outputEmbedding = _ResidualBlock.load(_weights, "output_patch_embedding",
        d, c.dFf, c.quantiles.length * c.predictionLength);
    _shared = _weights.require("shared.weight").data;
    if (_shared.length < (max(c.regTokenId, c.decoderStartTokenId) + 1) * d)
      throw const FormatException("shared embedding too small");

    _encoderRelativeBias = _weights.require(
        "encoder.block.0.layer.0.SelfAttention.relative_attention_bias.weight",
        [c.relativeAttentionNumBuckets, c.numHeads]).data;
    _encoderLayers = List.generate(c.numLayers, (layer) {
      final prefix = "encoder.block.$layer.layer";
      return _EncoderLayer(
        attentionNorm: _weights.require("$prefix.0.layer_norm.weight", [d]).data,
        attention: _Attention.load(_weights, "$prefix.0.SelfAttention", d, inner),
        feedForwardNorm:
            _weights.require("$prefix.1.layer_norm.weight", [d]).data,
        feedForward:
            _FeedForward.load(_weights, "$prefix.1.DenseReluDense", d, c.dFf),
      );
    }, growable: false);
    _encoderFinalNorm =
        _weights.require("encoder.final_layer_norm.weight", [d]).data;

    _decoderLayers = List.generate(c.numDecoderLayers, (layer) {
      final prefix = "decoder.block.$layer.layer";
      return _DecoderLayer(
        selfAttentionNorm:
            _weights.require("$prefix.0.layer_norm.weight", [d]).data,
        selfAttention:
            _Attention.load(_weights, "$prefix.0.SelfAttention", d, inner),
        crossAttentionNorm:
            _weights.require("$prefix.1.layer_norm.weight", [d]).data,
        crossAttention:
            _Attention.load(_weights, "$prefix.1.EncDecAttention", d, inner),
        feedForwardNorm:
            _weights.require("$prefix.2.layer_norm.weight", [d]).data,
        feedForward:
            _FeedForward.load(_weights, "$prefix.2.DenseReluDense", d, c.dFf),
      );
    }, growable: false);
    _decoderFinalNorm =
        _weights.require("decoder.final_layer_norm.weight", [d]).data;
  }

  /// Builds the model from the bytes of `model.safetensors` and the parsed
  /// `config.json`.
  factory ChronosBoltModel.fromBytes(
          Map<String, dynamic> configJson, Uint8List safetensors) =>
      ChronosBoltModel(ChronosBoltConfig.fromJson(configJson),
          SafeTensors.parse(safetensors));

  /// Number of parameters, for the screen and the tests.
  int get parameterCount => _weights.tensors.values
      .fold(0, (total, tensor) => total + tensor.length);

  static const double _instanceNormEpsilon = 1e-5;

  /// Forecasts the [ChronosBoltConfig.predictionLength] steps that follow
  /// [context]. Values must be finite; the oldest points beyond
  /// [ChronosBoltConfig.contextLength] are ignored.
  ChronosBoltPrediction predict(List<double> context) {
    if (context.isEmpty) throw ArgumentError("empty context");
    if (context.any((value) => !value.isFinite))
      throw ArgumentError("context has non-finite values");

    final c = config;
    final series = context.length > c.contextLength
        ? context.sublist(context.length - c.contextLength)
        : context;

    // Instance normalisation: mean and (population) standard deviation of the
    // context; a flat series gets a tiny scale instead of a division by zero.
    final count = series.length;
    var loc = 0.0;
    for (final value in series) {
      loc += value;
    }
    loc /= count;
    var variance = 0.0;
    for (final value in series) {
      variance += (value - loc) * (value - loc);
    }
    var scale = sqrt(variance / count);
    if (scale == 0) scale = _instanceNormEpsilon;
    // The reference runs this step in float32; rounding here keeps the
    // standardised values bit-compatible with it.
    loc = _toFloat32(loc);
    scale = _toFloat32(scale);

    // Patching: the context is left-padded with missing values up to a whole
    // number of patches. A missing value enters as 0 with mask 0.
    final patchSize = c.inputPatchSize;
    final patchCount = (count + patchSize - 1) ~/ patchSize;
    final padding = patchCount * patchSize - count;
    final tokenCount = patchCount + (c.useRegToken ? 1 : 0);
    final d = c.dModel;

    final embeddings = Float64List(tokenCount * d);
    final keyMask = List<bool>.filled(tokenCount, true);
    final patchInput = Float64List(patchSize * 2);
    for (var patch = 0; patch < patchCount; patch++) {
      var observed = false;
      for (var offset = 0; offset < patchSize; offset++) {
        final position = patch * patchSize + offset - padding;
        if (position >= 0) {
          patchInput[offset] =
              _toFloat32((series[position] - loc) / scale);
          patchInput[patchSize + offset] = 1;
          observed = true;
        } else {
          patchInput[offset] = 0;
          patchInput[patchSize + offset] = 0;
        }
      }
      keyMask[patch] = observed;
      _inputEmbedding.apply(patchInput, embeddings, patch * d);
    }
    if (c.useRegToken) {
      final row = c.regTokenId * d;
      for (var index = 0; index < d; index++) {
        embeddings[patchCount * d + index] = _shared[row + index];
      }
    }

    final encoded = _encode(embeddings, tokenCount, keyMask);
    final decoded = _decode(encoded, tokenCount, keyMask);

    final quantileCount = c.quantiles.length;
    final horizon = c.predictionLength;
    final raw = Float64List(quantileCount * horizon);
    _outputEmbedding.apply(decoded, raw, 0);

    final values = List<Float64List>.generate(quantileCount, (quantile) {
      final row = Float64List(horizon);
      for (var step = 0; step < horizon; step++) {
        row[step] = raw[quantile * horizon + step] * scale + loc;
      }
      return row;
    }, growable: false);
    return ChronosBoltPrediction(c.quantiles, values);
  }

  Float64List _encode(Float64List input, int tokens, List<bool> keyMask) {
    final c = config;
    final d = c.dModel;
    final bias = _positionBias(tokens);
    final hidden = Float64List.fromList(input);
    final normed = Float64List(tokens * d);
    final update = Float64List(tokens * d);

    for (final layer in _encoderLayers) {
      _rmsNorm(hidden, tokens, layer.attentionNorm, normed);
      layer.attention.apply(
        queries: normed,
        queryCount: tokens,
        keysValues: normed,
        keyCount: tokens,
        keyMask: keyMask,
        positionBias: bias,
        numHeads: c.numHeads,
        dKv: c.dKv,
        output: update,
      );
      _addInPlace(hidden, update);

      _rmsNorm(hidden, tokens, layer.feedForwardNorm, normed);
      layer.feedForward.apply(normed, tokens, update);
      _addInPlace(hidden, update);
    }
    final output = Float64List(tokens * d);
    _rmsNorm(hidden, tokens, _encoderFinalNorm, output);
    return output;
  }

  Float64List _decode(Float64List encoded, int tokens, List<bool> keyMask) {
    final c = config;
    final d = c.dModel;
    final hidden = Float64List(d);
    final start = c.decoderStartTokenId * d;
    for (var index = 0; index < d; index++) {
      hidden[index] = _shared[start + index];
    }
    final normed = Float64List(d);
    final update = Float64List(d);

    for (final layer in _decoderLayers) {
      // Self-attention over a single token: the softmax of one score is 1, so
      // the relative-position bias of the decoder plays no part and the
      // output is the value projection itself.
      _rmsNorm(hidden, 1, layer.selfAttentionNorm, normed);
      layer.selfAttention.apply(
        queries: normed,
        queryCount: 1,
        keysValues: normed,
        keyCount: 1,
        keyMask: const [true],
        positionBias: null,
        numHeads: c.numHeads,
        dKv: c.dKv,
        output: update,
      );
      _addInPlace(hidden, update);

      // Cross-attention has no position bias in T5.
      _rmsNorm(hidden, 1, layer.crossAttentionNorm, normed);
      layer.crossAttention.apply(
        queries: normed,
        queryCount: 1,
        keysValues: encoded,
        keyCount: tokens,
        keyMask: keyMask,
        positionBias: null,
        numHeads: c.numHeads,
        dKv: c.dKv,
        output: update,
      );
      _addInPlace(hidden, update);

      _rmsNorm(hidden, 1, layer.feedForwardNorm, normed);
      layer.feedForward.apply(normed, 1, update);
      _addInPlace(hidden, update);
    }
    final output = Float64List(d);
    _rmsNorm(hidden, 1, _decoderFinalNorm, output);
    return output;
  }

  /// Bidirectional relative-position bias of the encoder:
  /// `bias[head][query][key]`, flattened.
  Float64List _positionBias(int tokens) {
    final c = config;
    final heads = c.numHeads;
    final bias = Float64List(heads * tokens * tokens);
    for (var query = 0; query < tokens; query++) {
      for (var key = 0; key < tokens; key++) {
        final bucket = relativePositionBucket(key - query,
            numBuckets: c.relativeAttentionNumBuckets,
            maxDistance: c.relativeAttentionMaxDistance);
        for (var head = 0; head < heads; head++) {
          bias[(head * tokens + query) * tokens + key] =
              _encoderRelativeBias[bucket * heads + head];
        }
      }
    }
    return bias;
  }

  /// T5's bucketing of a relative position (bidirectional): exact buckets for
  /// short distances, logarithmic ones up to [maxDistance], and a shared last
  /// bucket beyond it. Half the buckets are for keys after the query.
  static int relativePositionBucket(int relativePosition,
      {required int numBuckets, required int maxDistance}) {
    final half = numBuckets ~/ 2;
    var bucket = relativePosition > 0 ? half : 0;
    final distance = relativePosition.abs();
    final maxExact = half ~/ 2;
    if (distance < maxExact) return bucket + distance;
    // Computed in float32 and truncated, as in the reference.
    final logRatio = _toFloat32(_toFloat32(log(_toFloat32(distance / maxExact))) /
        log(maxDistance / maxExact));
    final large =
        maxExact + _toFloat32(logRatio * (half - maxExact)).truncate();
    bucket += min(large, half - 1);
    return bucket;
  }

  void _rmsNorm(
      Float64List input, int tokens, Float32List weight, Float64List output) {
    final d = config.dModel;
    final epsilon = config.layerNormEpsilon;
    for (var token = 0; token < tokens; token++) {
      final offset = token * d;
      var sumOfSquares = 0.0;
      for (var index = 0; index < d; index++) {
        final value = input[offset + index];
        sumOfSquares += value * value;
      }
      final inverse = 1 / sqrt(sumOfSquares / d + epsilon);
      for (var index = 0; index < d; index++) {
        output[offset + index] = weight[index] * input[offset + index] * inverse;
      }
    }
  }

  static void _addInPlace(Float64List target, Float64List update) {
    for (var index = 0; index < target.length; index++) {
      target[index] += update[index];
    }
  }

  static final Float32List _float32Scratch = Float32List(1);

  static double _toFloat32(double value) {
    _float32Scratch[0] = value;
    return _float32Scratch[0];
  }
}

/// `y = W x (+ b)` for a PyTorch `nn.Linear` weight of shape `[out, in]`,
/// reading [input] from [inputOffset] and writing [output] from
/// [outputOffset].
void _linear(Float32List weight, Float32List? bias, int outDim, int inDim,
    Float64List input, int inputOffset, Float64List output, int outputOffset) {
  // Four independent accumulators: the products no longer wait on each other,
  // which cuts about a quarter of the time of a pass. Every inner
  // dimension of the published checkpoints is a multiple of four; the tail
  // loop covers any other.
  final unrolled = inDim - inDim % 4;
  for (var row = 0; row < outDim; row++) {
    final weightOffset = row * inDim;
    var sum0 = 0.0, sum1 = 0.0, sum2 = 0.0, sum3 = 0.0;
    var column = 0;
    for (; column < unrolled; column += 4) {
      final w = weightOffset + column;
      final x = inputOffset + column;
      sum0 += weight[w] * input[x];
      sum1 += weight[w + 1] * input[x + 1];
      sum2 += weight[w + 2] * input[x + 2];
      sum3 += weight[w + 3] * input[x + 3];
    }
    for (; column < inDim; column++) {
      sum0 += weight[weightOffset + column] * input[inputOffset + column];
    }
    output[outputOffset + row] =
        (bias == null ? 0.0 : bias[row]) + ((sum0 + sum1) + (sum2 + sum3));
  }
}

/// Chronos-Bolt's residual MLP:
/// `output(relu(hidden(x))) + residual(x)`, every layer with bias.
class _ResidualBlock {
  final Float32List hiddenWeight;
  final Float32List hiddenBias;
  final Float32List outputWeight;
  final Float32List outputBias;
  final Float32List residualWeight;
  final Float32List residualBias;
  final int inDim;
  final int hiddenDim;
  final int outDim;
  final Float64List _hidden;
  final Float64List _residual;

  _ResidualBlock(
      this.hiddenWeight,
      this.hiddenBias,
      this.outputWeight,
      this.outputBias,
      this.residualWeight,
      this.residualBias,
      this.inDim,
      this.hiddenDim,
      this.outDim)
      : _hidden = Float64List(hiddenDim),
        _residual = Float64List(outDim);

  factory _ResidualBlock.load(SafeTensors weights, String prefix, int inDim,
          int hiddenDim, int outDim) =>
      _ResidualBlock(
        weights.require("$prefix.hidden_layer.weight", [hiddenDim, inDim]).data,
        weights.require("$prefix.hidden_layer.bias", [hiddenDim]).data,
        weights.require("$prefix.output_layer.weight", [outDim, hiddenDim]).data,
        weights.require("$prefix.output_layer.bias", [outDim]).data,
        weights.require("$prefix.residual_layer.weight", [outDim, inDim]).data,
        weights.require("$prefix.residual_layer.bias", [outDim]).data,
        inDim,
        hiddenDim,
        outDim,
      );

  void apply(Float64List input, Float64List output, int outputOffset) {
    _linear(hiddenWeight, hiddenBias, hiddenDim, inDim, input, 0, _hidden, 0);
    for (var index = 0; index < hiddenDim; index++) {
      if (_hidden[index] < 0) _hidden[index] = 0;
    }
    _linear(outputWeight, outputBias, outDim, hiddenDim, _hidden, 0, output,
        outputOffset);
    _linear(
        residualWeight, residualBias, outDim, inDim, input, 0, _residual, 0);
    for (var index = 0; index < outDim; index++) {
      output[outputOffset + index] += _residual[index];
    }
  }
}

/// T5 multi-head attention, without the `1/sqrt(d)` scaling (T5 folds it into
/// the initialisation) and without biases.
class _Attention {
  final Float32List query;
  final Float32List key;
  final Float32List value;
  final Float32List out;
  final int dModel;
  final int innerDim;

  const _Attention(
      this.query, this.key, this.value, this.out, this.dModel, this.innerDim);

  factory _Attention.load(
          SafeTensors weights, String prefix, int dModel, int innerDim) =>
      _Attention(
        weights.require("$prefix.q.weight", [innerDim, dModel]).data,
        weights.require("$prefix.k.weight", [innerDim, dModel]).data,
        weights.require("$prefix.v.weight", [innerDim, dModel]).data,
        weights.require("$prefix.o.weight", [dModel, innerDim]).data,
        dModel,
        innerDim,
      );

  void apply({
    required Float64List queries,
    required int queryCount,
    required Float64List keysValues,
    required int keyCount,
    required List<bool> keyMask,
    required Float64List? positionBias,
    required int numHeads,
    required int dKv,
    required Float64List output,
  }) {
    final q = Float64List(queryCount * innerDim);
    final k = Float64List(keyCount * innerDim);
    final v = Float64List(keyCount * innerDim);
    for (var token = 0; token < queryCount; token++) {
      _linear(query, null, innerDim, dModel, queries, token * dModel, q,
          token * innerDim);
    }
    for (var token = 0; token < keyCount; token++) {
      _linear(key, null, innerDim, dModel, keysValues, token * dModel, k,
          token * innerDim);
      _linear(value, null, innerDim, dModel, keysValues, token * dModel, v,
          token * innerDim);
    }

    final context = Float64List(queryCount * innerDim);
    final scores = Float64List(keyCount);
    for (var head = 0; head < numHeads; head++) {
      final headOffset = head * dKv;
      for (var token = 0; token < queryCount; token++) {
        final queryOffset = token * innerDim + headOffset;
        var maximum = double.negativeInfinity;
        for (var other = 0; other < keyCount; other++) {
          if (!keyMask[other]) {
            scores[other] = double.negativeInfinity;
            continue;
          }
          final keyOffset = other * innerDim + headOffset;
          var score = 0.0;
          for (var index = 0; index < dKv; index++) {
            score += q[queryOffset + index] * k[keyOffset + index];
          }
          if (positionBias != null) {
            score +=
                positionBias[(head * queryCount + token) * keyCount + other];
          }
          scores[other] = score;
          if (score > maximum) maximum = score;
        }
        var total = 0.0;
        for (var other = 0; other < keyCount; other++) {
          final weight = keyMask[other] ? exp(scores[other] - maximum) : 0.0;
          scores[other] = weight;
          total += weight;
        }
        final contextOffset = token * innerDim + headOffset;
        for (var other = 0; other < keyCount; other++) {
          final weight = scores[other] / total;
          if (weight == 0) continue;
          final valueOffset = other * innerDim + headOffset;
          for (var index = 0; index < dKv; index++) {
            context[contextOffset + index] += weight * v[valueOffset + index];
          }
        }
      }
    }

    for (var token = 0; token < queryCount; token++) {
      _linear(out, null, dModel, innerDim, context, token * innerDim, output,
          token * dModel);
    }
  }
}

/// T5's feed-forward block: `wo(relu(wi(x)))`, no biases.
class _FeedForward {
  final Float32List wi;
  final Float32List wo;
  final int dModel;
  final int dFf;

  const _FeedForward(this.wi, this.wo, this.dModel, this.dFf);

  factory _FeedForward.load(
          SafeTensors weights, String prefix, int dModel, int dFf) =>
      _FeedForward(
        weights.require("$prefix.wi.weight", [dFf, dModel]).data,
        weights.require("$prefix.wo.weight", [dModel, dFf]).data,
        dModel,
        dFf,
      );

  void apply(Float64List input, int tokens, Float64List output) {
    final hidden = Float64List(dFf);
    for (var token = 0; token < tokens; token++) {
      _linear(wi, null, dFf, dModel, input, token * dModel, hidden, 0);
      for (var index = 0; index < dFf; index++) {
        if (hidden[index] < 0) hidden[index] = 0;
      }
      _linear(wo, null, dModel, dFf, hidden, 0, output, token * dModel);
    }
  }
}

class _EncoderLayer {
  final Float32List attentionNorm;
  final _Attention attention;
  final Float32List feedForwardNorm;
  final _FeedForward feedForward;

  const _EncoderLayer(
      {required this.attentionNorm,
      required this.attention,
      required this.feedForwardNorm,
      required this.feedForward});
}

class _DecoderLayer {
  final Float32List selfAttentionNorm;
  final _Attention selfAttention;
  final Float32List crossAttentionNorm;
  final _Attention crossAttention;
  final Float32List feedForwardNorm;
  final _FeedForward feedForward;

  const _DecoderLayer(
      {required this.selfAttentionNorm,
      required this.selfAttention,
      required this.crossAttentionNorm,
      required this.crossAttention,
      required this.feedForwardNorm,
      required this.feedForward});
}
