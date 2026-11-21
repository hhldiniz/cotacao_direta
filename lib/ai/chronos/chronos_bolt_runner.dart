import 'dart:typed_data';

import 'package:cotacao_direta/ai/chronos/chronos_bolt_model.dart';

import 'chronos_bolt_runner_io.dart'
    if (dart.library.js_interop) 'chronos_bolt_runner_web.dart';

/// Runs Chronos-Bolt forward passes somewhere they do not freeze the screen.
///
/// One pass takes tens of milliseconds on a phone, and an analysis makes a few
/// of them (the projection plus the backtests). On Android and Linux the
/// passes run on a dedicated isolate that owns the weights; on the web, where
/// there are no isolates to share memory with, they run on the page's thread,
/// one at a time, giving the event loop a turn between them.
abstract interface class ChronosBoltRunner {
  ChronosBoltConfig get config;

  /// One prediction per context, in the same order.
  Future<List<ChronosBoltPrediction>> predictAll(List<List<double>> contexts);

  /// Releases the weights (and the isolate, where there is one).
  Future<void> dispose();

  /// Picks the right runner for the platform. [weights] is the content of
  /// `model.safetensors`; on platforms with isolates it is moved to the worker
  /// without a copy and must not be used by the caller afterwards.
  static Future<ChronosBoltRunner> create(
          Map<String, dynamic> configJson, Uint8List weights) =>
      createPlatformChronosBoltRunner(configJson, weights);
}

/// Runs the passes right where it is called. Used on the web and in the
/// tests.
class InlineChronosBoltRunner implements ChronosBoltRunner {
  final ChronosBoltModel model;

  InlineChronosBoltRunner(this.model);

  @override
  ChronosBoltConfig get config => model.config;

  @override
  Future<List<ChronosBoltPrediction>> predictAll(
      List<List<double>> contexts) async {
    final predictions = <ChronosBoltPrediction>[];
    for (final context in contexts) {
      // A turn for the event loop between passes, so the loading indicator
      // keeps moving.
      await Future<void>.delayed(Duration.zero);
      predictions.add(model.predict(context));
    }
    return predictions;
  }

  @override
  Future<void> dispose() async {}
}
