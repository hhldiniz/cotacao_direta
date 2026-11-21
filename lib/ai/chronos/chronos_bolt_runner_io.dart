import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:cotacao_direta/ai/chronos/chronos_bolt_model.dart';
import 'package:cotacao_direta/ai/chronos/chronos_bolt_runner.dart';

Future<ChronosBoltRunner> createPlatformChronosBoltRunner(
        Map<String, dynamic> configJson, Uint8List weights) =>
    IsolateChronosBoltRunner.spawn(configJson, weights);

/// Keeps the model on a worker isolate. The weights are handed over as
/// [TransferableTypedData] — a move, not a copy, so the 35 MB are never held
/// twice — and each request sends only the prices and gets back only the
/// quantiles.
class IsolateChronosBoltRunner implements ChronosBoltRunner {
  @override
  final ChronosBoltConfig config;

  final Isolate _isolate;
  final SendPort _requests;
  final ReceivePort _responses;
  final Map<int, Completer<List<ChronosBoltPrediction>>> _pending = {};
  int _nextRequestId = 0;
  bool _disposed = false;

  IsolateChronosBoltRunner._(
      this.config, this._isolate, this._requests, this._responses) {
    _responses.listen(_onResponse);
  }

  static Future<IsolateChronosBoltRunner> spawn(
      Map<String, dynamic> configJson, Uint8List weights) async {
    // Parsing the config here first turns a bad checkpoint into an error at
    // the call site rather than inside the worker.
    final config = ChronosBoltConfig.fromJson(configJson);
    final handshake = ReceivePort();
    final isolate = await Isolate.spawn(
      _workerMain,
      [
        handshake.sendPort,
        configJson,
        TransferableTypedData.fromList([weights]),
      ],
      debugName: "chronos-bolt",
      errorsAreFatal: false,
    );
    final first = await handshake.first;
    if (first is! List || first[0] != "ready") {
      isolate.kill(priority: Isolate.immediate);
      final reason = first is List && first.length > 1 ? first[1] : first;
      // A checkpoint that does not parse is reported as such, so the caller
      // can tell damaged files from a worker that could not start.
      if (first is List && first.length > 2 && first[2] == true)
        throw FormatException("$reason");
      throw StateError("Chronos-Bolt worker failed to start: $reason");
    }
    final responses = ReceivePort();
    (first[1] as SendPort).send(responses.sendPort);
    return IsolateChronosBoltRunner._(
        config, isolate, first[1] as SendPort, responses);
  }

  @override
  Future<List<ChronosBoltPrediction>> predictAll(List<List<double>> contexts) {
    if (_disposed) throw StateError("runner disposed");
    final id = _nextRequestId++;
    final completer = Completer<List<ChronosBoltPrediction>>();
    _pending[id] = completer;
    _requests.send([
      id,
      [for (final context in contexts) Float64List.fromList(context)],
    ]);
    return completer.future;
  }

  void _onResponse(dynamic message) {
    final response = message as List;
    final completer = _pending.remove(response[0] as int);
    if (completer == null) return;
    if (response[1] == "error") {
      completer.completeError(StateError("${response[2]}"));
      return;
    }
    final levels = config.quantiles;
    completer.complete([
      for (final values in response[2] as List)
        ChronosBoltPrediction(levels, (values as List).cast<Float64List>()),
    ]);
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _isolate.kill(priority: Isolate.immediate);
    _responses.close();
    for (final completer in _pending.values) {
      completer.completeError(StateError("runner disposed"));
    }
    _pending.clear();
  }
}

Future<void> _workerMain(List<Object?> arguments) async {
  final handshake = arguments[0] as SendPort;
  final ChronosBoltModel model;
  try {
    final weights = (arguments[2] as TransferableTypedData)
        .materialize()
        .asUint8List();
    model = ChronosBoltModel.fromBytes(
        arguments[1] as Map<String, dynamic>, weights);
  } catch (error) {
    handshake.send(["failed", "$error", error is FormatException]);
    return;
  }

  final requests = ReceivePort();
  handshake.send(["ready", requests.sendPort]);
  SendPort? replies;
  await for (final message in requests) {
    if (message is SendPort) {
      replies = message;
      continue;
    }
    final request = message as List;
    final id = request[0] as int;
    try {
      final predictions = [
        for (final context in request[1] as List)
          model.predict(context as Float64List).values,
      ];
      replies?.send([id, "ok", predictions]);
    } catch (error) {
      replies?.send([id, "error", "$error"]);
    }
  }
}
