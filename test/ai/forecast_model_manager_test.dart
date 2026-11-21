import 'dart:io';
import 'dart:typed_data';

import 'package:cotacao_direta/ai/model/forecast_model_manager.dart';
import 'package:cotacao_direta/ai/model/hugging_face_model.dart';
import 'package:cotacao_direta/ai/model/model_storage_io.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/chronos_test_helper.dart';
import '../helpers/series_test_helper.dart';

void main() {
  late InMemoryModelStorage storage;
  late FakeHuggingFace huggingFace;
  late ForecastModelManager manager;

  setUp(() {
    storage = InMemoryModelStorage();
    huggingFace = FakeHuggingFace(tinyChronosSpec());
    manager = tinyChronosManager(
        installed: false, storage: storage, huggingFace: huggingFace);
  });

  tearDown(() => manager.dispose());

  group('ForecastModelManager', () {
    test('começa verificando e descobre que o modelo não está instalado',
        () async {
      expect(manager.state.status, ForecastModelStatus.checking);

      await manager.refresh();

      expect(manager.state.status, ForecastModelStatus.notInstalled);
    });

    test('reconhece um modelo já baixado', () async {
      final installed = tinyChronosManager();
      addTearDown(installed.dispose);

      await installed.refresh();

      expect(installed.state.isInstalled, isTrue);
    });

    test('baixa os arquivos da revisão fixada no Hugging Face', () async {
      final ok = await manager.download();

      expect(ok, isTrue);
      expect(manager.state.status, ForecastModelStatus.installed);
      final spec = huggingFace.spec;
      expect(huggingFace.requests,
          [spec.urlOf(spec.config), spec.urlOf(spec.weights)]);
      expect(huggingFace.requests.first.toString(),
          'https://huggingface.co/test/chronos-bolt-fixture/resolve/'
          '${spec.revision}/config.json');
      expect(storage.files.keys, {
        '${spec.storageFolder}/config.json',
        '${spec.storageFolder}/model.safetensors',
      });
    });

    test('publica o progresso do download até o total', () async {
      final states = <ForecastModelState>[];
      manager.states.listen(states.add);

      await manager.download();
      await pumpEventQueue();

      final downloading = states
          .where((state) => state.status == ForecastModelStatus.downloading)
          .toList();
      expect(downloading, isNotEmpty);
      expect(downloading.first.totalBytes, huggingFace.spec.totalSize);
      final progress = downloading.map((state) => state.receivedBytes).toList();
      expect(progress, orderedEquals([...progress]..sort()));
      expect(progress.last, huggingFace.spec.totalSize);
      expect(states.last.status, ForecastModelStatus.installed);
    });

    test('arquivo com hash diferente é descartado', () async {
      final tampered = Uint8List.fromList(tinyChronosWeightBytes());
      tampered[tampered.length - 1] ^= 0xFF;
      huggingFace.weightBytes = tampered;

      final ok = await manager.download();

      expect(ok, isFalse);
      expect(manager.state.status, ForecastModelStatus.failed);
      expect(storage.files, isEmpty);
    });

    test('arquivo de tamanho diferente é descartado', () async {
      huggingFace.weightBytes =
          Uint8List.sublistView(tinyChronosWeightBytes(), 0, 1000);

      expect(await manager.download(), isFalse);
      expect(storage.files, isEmpty);
    });

    test('erro HTTP vira falha, sem derrubar nada', () async {
      huggingFace.failWithStatus = 503;

      expect(await manager.download(), isFalse);
      expect(manager.state.status, ForecastModelStatus.failed);
    });

    test('depois de uma falha, dá para tentar de novo', () async {
      huggingFace.failWithStatus = 503;
      await manager.download();
      huggingFace.failWithStatus = null;

      expect(await manager.download(), isTrue);
      expect(manager.state.isInstalled, isTrue);
    });

    test('pedidos simultâneos compartilham o mesmo download', () async {
      final results = await Future.wait([manager.download(), manager.download()]);

      expect(results, [true, true]);
      expect(huggingFace.requests.length, 2);
    });

    test('sem o modelo, pedir o previsor falha de forma reconhecível',
        () async {
      await expectLater(manager.forecaster(),
          throwsA(isA<ForecastModelNotInstalledException>()));
      expect(manager.state.status, ForecastModelStatus.notInstalled);
    });

    test('depois do download, entrega o previsor pronto', () async {
      await manager.download();

      final forecaster = await manager.forecaster();
      final forecast = await forecaster.forecast(
          seriesFromPrices(syntheticPrices(length: 80)),
          horizonInDays: 7);

      expect(forecast.points.length, 7);
      expect(forecast.diagnostics.modelName, 'Chronos-Bolt Fixture');
    });

    test('arquivos danificados são apagados para poder baixar de novo',
        () async {
      await manager.download();
      final spec = huggingFace.spec;
      storage.files['${spec.storageFolder}/model.safetensors'] =
          Uint8List.fromList(List.filled(32, 1));

      await expectLater(manager.forecaster(), throwsFormatException);

      expect(storage.files, isEmpty);
      expect(manager.state.status, ForecastModelStatus.notInstalled);
    });

    test('remover apaga os arquivos e volta ao estado inicial', () async {
      await manager.download();
      await manager.forecaster();

      await manager.delete();

      expect(storage.files, isEmpty);
      expect(manager.state.status, ForecastModelStatus.notInstalled);
      await expectLater(manager.forecaster(),
          throwsA(isA<ForecastModelNotInstalledException>()));
    });
  });

  group('HuggingFaceModel.chronosBoltTiny', () {
    const spec = HuggingFaceModel.chronosBoltTiny;

    test('aponta para o repositório oficial numa revisão fixa', () {
      expect(spec.urlOf(spec.weights).toString(),
          'https://huggingface.co/amazon/chronos-bolt-tiny/resolve/'
          'a0e552de83495b5c28c14c71c374f3e33280b340/model.safetensors');
      expect(spec.revision, hasLength(40));
      expect(spec.pageUrl.toString(),
          'https://huggingface.co/amazon/chronos-bolt-tiny');
    });

    test('fixa o SHA-256 e o tamanho de cada arquivo', () {
      for (final file in spec.files) {
        expect(file.sha256, matches(RegExp(r'^[0-9a-f]{64}$')));
        expect(file.size, greaterThan(0));
      }
      expect(spec.totalSize, greaterThan(30 * 1000 * 1000));
    });

    test('guarda cada revisão numa pasta própria', () {
      expect(spec.storageFolder, 'amazon--chronos-bolt-tiny/a0e552de8349');
    });
  });

  group('FileModelStorage', () {
    late Directory root;
    late FileModelStorage files;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('model_storage_test');
      files = FileModelStorage(root: () async => root);
    });

    tearDown(() => root.delete(recursive: true));

    test('grava, lê e apaga por pasta', () async {
      final bytes = Uint8List.fromList([1, 2, 3]);

      await files.write('repo/rev/model.bin', bytes);

      expect(await files.contains('repo/rev/model.bin'), isTrue);
      expect(await files.read('repo/rev/model.bin'), bytes);
      expect(File('${root.path}/repo/rev/model.bin.part').existsSync(),
          isFalse);

      await files.deleteFolder('repo/rev');

      expect(await files.contains('repo/rev/model.bin'), isFalse);
      expect(await files.read('repo/rev/model.bin'), isNull);
    });

    test('apagar uma pasta que não existe não é erro', () async {
      await files.deleteFolder('nada/aqui');
    });
  });
}
