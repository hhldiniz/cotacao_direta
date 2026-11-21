import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cotacao_direta/ai/chronos/chronos_bolt_runner.dart';
import 'package:cotacao_direta/ai/chronos_forecaster.dart';
import 'package:cotacao_direta/ai/model/hugging_face_model.dart';
import 'package:cotacao_direta/ai/model/model_storage.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

enum ForecastModelStatus {
  /// Looking at the storage to see whether the model is there.
  checking,

  /// Not on the device yet: it has to be downloaded before any analysis.
  notInstalled,

  downloading,

  /// On the device and ready to run.
  installed,

  /// The last download failed (no network, an interrupted transfer, a file
  /// that did not match its hash). The model is not on the device.
  failed,
}

class ForecastModelState {
  final ForecastModelStatus status;
  final int receivedBytes;
  final int totalBytes;

  const ForecastModelState(this.status,
      {this.receivedBytes = 0, this.totalBytes = 0});

  /// Download progress from 0 to 1, or null when the size is unknown.
  double? get progress =>
      totalBytes <= 0 ? null : (receivedBytes / totalBytes).clamp(0.0, 1.0);

  bool get isInstalled => status == ForecastModelStatus.installed;

  bool get isBusy =>
      status == ForecastModelStatus.checking ||
      status == ForecastModelStatus.downloading;
}

/// The model was asked for before it was downloaded.
class ForecastModelNotInstalledException implements Exception {
  const ForecastModelNotInstalledException();

  @override
  String toString() => "forecast model not installed";
}

/// Downloads the forecasting model from Hugging Face, keeps it on the device
/// and hands it, loaded, to the analysis.
///
/// The model is not bundled with the app: it is fetched from its official
/// repository the first time the user asks for it, pinned to one revision and
/// checked against the SHA-256 of every file, and from then on everything runs
/// offline. That keeps the install small for those who never open the AI
/// screen, and the provenance of the weights verifiable.
///
/// One instance is shared by the whole app ([shared]): the loaded model
/// survives leaving and coming back to the screen, and a download keeps going
/// if the user navigates away in the middle of it.
class ForecastModelManager {
  final HuggingFaceModel model;
  final ModelStorage _storage;
  final http.Client Function() _clientFactory;
  final Future<ChronosBoltRunner> Function(
      Map<String, dynamic> configJson, Uint8List weights) _runnerFactory;

  final StreamController<ForecastModelState> _states =
      StreamController<ForecastModelState>.broadcast();

  ForecastModelState _state =
      const ForecastModelState(ForecastModelStatus.checking);

  Future<void>? _checking;
  Future<bool>? _downloading;
  Future<ChronosBoltRunner>? _runner;

  ForecastModelManager({
    this.model = HuggingFaceModel.chronosBoltTiny,
    ModelStorage? storage,
    http.Client Function()? clientFactory,
    Future<ChronosBoltRunner> Function(
            Map<String, dynamic> configJson, Uint8List weights)?
        runnerFactory,
  })  : _storage = storage ?? ModelStorage(),
        _clientFactory = clientFactory ?? http.Client.new,
        _runnerFactory = runnerFactory ?? ChronosBoltRunner.create;

  static ForecastModelManager? _shared;

  /// The instance the app uses.
  static ForecastModelManager get shared =>
      _shared ??= ForecastModelManager();

  ForecastModelState get state => _state;

  Stream<ForecastModelState> get states => _states.stream;

  String _key(HuggingFaceFile file) => "${model.storageFolder}/${file.path}";

  /// Finds out whether the model is already on the device. Cheap and
  /// idempotent: the screen calls it whenever it opens.
  Future<void> refresh() {
    if (_downloading != null) return Future.value();
    return _checking ??= _check().whenComplete(() => _checking = null);
  }

  Future<void> _check() async {
    if (_state.status != ForecastModelStatus.installed &&
        _state.status != ForecastModelStatus.failed) {
      _emit(const ForecastModelState(ForecastModelStatus.checking));
    }
    try {
      var installed = true;
      for (final file in model.files) {
        if (!await _storage.contains(_key(file))) installed = false;
      }
      if (_downloading != null) return;
      if (installed) {
        _emit(const ForecastModelState(ForecastModelStatus.installed));
      } else if (_state.status != ForecastModelStatus.failed) {
        _emit(const ForecastModelState(ForecastModelStatus.notInstalled));
      }
    } catch (_) {
      if (_downloading == null)
        _emit(const ForecastModelState(ForecastModelStatus.notInstalled));
    }
  }

  /// Downloads every file of the model and stores it. Completes with whether
  /// it worked; the outcome is also published on [states]. Calling it again
  /// while a download is running joins that download.
  Future<bool> download() =>
      _downloading ??= _download().whenComplete(() => _downloading = null);

  Future<bool> _download() async {
    final total = model.totalSize;
    _emit(ForecastModelState(ForecastModelStatus.downloading,
        totalBytes: total));
    final client = _clientFactory();
    try {
      final contents = <HuggingFaceFile, Uint8List>{};
      var completed = 0;
      for (final file in model.files) {
        contents[file] = await _fetch(client, file, (received) {
          _emit(ForecastModelState(ForecastModelStatus.downloading,
              receivedBytes: completed + received, totalBytes: total));
        });
        completed += file.size;
      }
      // The weights are written last: as long as they are missing, a check
      // after a crash halfway through sees the model as not installed.
      await _storage.write(_key(model.config), contents[model.config]!);
      await _storage.write(_key(model.weights), contents[model.weights]!);
      _emit(const ForecastModelState(ForecastModelStatus.installed));
      return true;
    } catch (_) {
      _emit(const ForecastModelState(ForecastModelStatus.failed));
      return false;
    } finally {
      client.close();
    }
  }

  /// Fetches one file, reporting the bytes received so far, and checks its
  /// size and hash before accepting it.
  Future<Uint8List> _fetch(http.Client client, HuggingFaceFile file,
      void Function(int received) onProgress) async {
    final response =
        await client.send(http.Request("GET", model.urlOf(file)));
    if (response.statusCode != 200)
      throw http.ClientException(
          "HTTP ${response.statusCode} for ${file.path}", model.urlOf(file));

    final builder = BytesBuilder(copy: false);
    // Progress is published once per percent at most: a stream event per
    // network chunk would rebuild the screen thousands of times.
    final step = (file.size ~/ 100).clamp(1, 1 << 30);
    var lastReported = -step;
    await for (final chunk in response.stream) {
      builder.add(chunk);
      if (builder.length - lastReported >= step) {
        lastReported = builder.length;
        onProgress(builder.length);
      }
    }
    final bytes = builder.takeBytes();
    if (bytes.length != file.size)
      throw FormatException(
          "${file.path}: expected ${file.size} bytes, got ${bytes.length}");
    final digest = sha256.convert(bytes).toString();
    if (digest != file.sha256)
      throw FormatException("${file.path}: SHA-256 mismatch ($digest)");
    onProgress(bytes.length);
    return bytes;
  }

  /// The model, loaded and wrapped as a forecaster. Loads it on the first
  /// call; later calls reuse it. Throws [ForecastModelNotInstalledException]
  /// when the files are not on the device.
  Future<AssetForecaster> forecaster() async {
    final runner = await (_runner ??= _load());
    return ChronosForecaster(runner, modelName: model.displayName);
  }

  Future<ChronosBoltRunner> _load() async {
    try {
      final config = await _storage.read(_key(model.config));
      final weights = await _storage.read(_key(model.weights));
      if (config == null || weights == null)
        throw const ForecastModelNotInstalledException();
      final configJson = jsonDecode(utf8.decode(config));
      if (configJson is! Map<String, dynamic>)
        throw const FormatException("config.json is not an object");
      return await _runnerFactory(configJson, weights);
    } on ForecastModelNotInstalledException {
      _runner = null;
      _emit(const ForecastModelState(ForecastModelStatus.notInstalled));
      rethrow;
    } on FormatException {
      // Files that are there but do not parse are damaged: removing them lets
      // the user download them again instead of being stuck.
      _runner = null;
      await _storage.deleteFolder(model.storageFolder);
      _emit(const ForecastModelState(ForecastModelStatus.notInstalled));
      rethrow;
    } catch (_) {
      // Anything else (the worker could not start, say) leaves the files
      // alone: the next analysis tries to load them again.
      _runner = null;
      rethrow;
    }
  }

  /// Removes the model from the device, to free the space.
  Future<void> delete() async {
    await _downloading;
    final runner = _runner;
    _runner = null;
    if (runner != null) await (await runner).dispose();
    await _storage.deleteFolder(model.storageFolder);
    _emit(const ForecastModelState(ForecastModelStatus.notInstalled));
  }

  void _emit(ForecastModelState state) {
    _state = state;
    if (!_states.isClosed) _states.add(state);
  }

  /// Stops the worker and closes the stream. Only the tests call it: the
  /// shared instance lives as long as the app.
  Future<void> dispose() async {
    final runner = _runner;
    _runner = null;
    if (runner != null) {
      try {
        await (await runner).dispose();
      } catch (_) {}
    }
    await _states.close();
  }
}
