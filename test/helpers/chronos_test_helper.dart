import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cotacao_direta/ai/chronos/chronos_bolt_model.dart';
import 'package:cotacao_direta/ai/chronos/chronos_bolt_runner.dart';
import 'package:cotacao_direta/ai/model/forecast_model_manager.dart';
import 'package:cotacao_direta/ai/model/hugging_face_model.dart';
import 'package:cotacao_direta/ai/model/model_storage.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Chronos-Bolt with the real architecture but tiny, random weights, generated
/// together with the reference outputs by
/// tool/chronos_reference/generate_fixtures.py. The tests use it in place of
/// the 35 MB checkpoint, which is only ever downloaded by the app.
const String tinyChronosDirectory = 'test/fixtures/chronos_bolt';

Uint8List tinyChronosConfigBytes() =>
    File('$tinyChronosDirectory/config.json').readAsBytesSync();

Uint8List tinyChronosWeightBytes() =>
    File('$tinyChronosDirectory/model.safetensors').readAsBytesSync();

ChronosBoltModel loadTinyChronosBolt() => ChronosBoltModel.fromBytes(
      jsonDecode(utf8.decode(tinyChronosConfigBytes())) as Map<String, dynamic>,
      tinyChronosWeightBytes(),
    );

/// The fixture described the way the app describes the real model: a
/// Hugging Face repository pinned to a revision, with the size and SHA-256 of
/// each file.
HuggingFaceModel tinyChronosSpec() {
  HuggingFaceFile describe(String path, Uint8List bytes) => HuggingFaceFile(
      path: path, sha256: sha256.convert(bytes).toString(), size: bytes.length);
  return HuggingFaceModel(
    repository: 'test/chronos-bolt-fixture',
    revision: '0123456789abcdef0123456789abcdef01234567',
    displayName: 'Chronos-Bolt Fixture',
    license: 'Apache-2.0',
    config: describe('config.json', tinyChronosConfigBytes()),
    weights: describe('model.safetensors', tinyChronosWeightBytes()),
  );
}

/// Serves the fixture files from the Hugging Face addresses of [spec], and
/// records every request. [weightBytes] replaces the weights served, to
/// simulate a corrupted download.
class FakeHuggingFace {
  final HuggingFaceModel spec;
  final List<Uri> requests = [];
  Uint8List? weightBytes;
  int? failWithStatus;

  FakeHuggingFace(this.spec);

  http.Client client() => MockClient.streaming((request, _) async {
        requests.add(request.url);
        if (failWithStatus != null)
          return http.StreamedResponse(Stream.value(const []), failWithStatus!);
        final Uint8List body;
        if (request.url == spec.urlOf(spec.config)) {
          body = tinyChronosConfigBytes();
        } else if (request.url == spec.urlOf(spec.weights)) {
          body = weightBytes ?? tinyChronosWeightBytes();
        } else {
          return http.StreamedResponse(Stream.value(const []), 404);
        }
        // In small chunks, as a real transfer arrives.
        final chunks = <List<int>>[
          for (var start = 0; start < body.length; start += 4096)
            body.sublist(start, (start + 4096).clamp(0, body.length)),
        ];
        return http.StreamedResponse(Stream.fromIterable(chunks), 200,
            contentLength: body.length);
      });
}

/// Model storage kept in memory.
class InMemoryModelStorage implements ModelStorage {
  final Map<String, Uint8List> files = {};

  @override
  Future<bool> contains(String key) async => files.containsKey(key);

  @override
  Future<Uint8List?> read(String key) async => files[key];

  @override
  Future<void> write(String key, Uint8List bytes) async => files[key] = bytes;

  @override
  Future<void> deleteFolder(String folder) async =>
      files.removeWhere((key, _) => key.startsWith('$folder/'));
}

Future<ChronosBoltRunner> inlineRunnerFactory(
        Map<String, dynamic> configJson, Uint8List weights) async =>
    InlineChronosBoltRunner(ChronosBoltModel.fromBytes(configJson, weights));

/// A manager for the fixture model, with the files already in [storage] when
/// [installed] is true.
ForecastModelManager tinyChronosManager({
  bool installed = true,
  InMemoryModelStorage? storage,
  FakeHuggingFace? huggingFace,
}) {
  final spec = huggingFace?.spec ?? tinyChronosSpec();
  final files = storage ?? InMemoryModelStorage();
  if (installed) {
    files.files['${spec.storageFolder}/config.json'] = tinyChronosConfigBytes();
    files.files['${spec.storageFolder}/model.safetensors'] =
        tinyChronosWeightBytes();
  }
  final server = huggingFace ?? FakeHuggingFace(spec);
  return ForecastModelManager(
    model: spec,
    storage: files,
    clientFactory: server.client,
    runnerFactory: inlineRunnerFactory,
  );
}
