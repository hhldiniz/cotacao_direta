import 'package:cotacao_direta/model/configuration.dart';
import 'package:cotacao_direta/repository/configuration_repository.dart';
import 'package:cotacao_direta/util/app_locale_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fakes.dart';

/// Repositório que falha na leitura, para conferir que o app ainda abre quando
/// a configuração não pode ser lida.
class _BrokenConfigurationRepository implements ConfigurationRepository {
  @override
  Future<Configuration> getConfiguration() async =>
      throw StateError("banco indisponível");

  @override
  Future<void> insert(Configuration configuration) async {}
}

void main() {
  late FakeConfigurationRepository repository;
  late AppLocaleController controller;

  setUp(() {
    repository = FakeConfigurationRepository();
    controller = AppLocaleController(configurationRepository: repository);
  });

  tearDown(() => controller.dispose());

  group('AppLocaleController', () {
    test('começa no idioma do aparelho', () {
      expect(controller.value, isNull);
    });

    test('load lê o idioma gravado', () async {
      repository.configuration = Configuration(1, languageCode: "en");

      await controller.load();

      expect(controller.value, const Locale("en"));
    });

    test('load sem idioma gravado segue o aparelho', () async {
      await controller.load();

      expect(controller.value, isNull);
    });

    // Instalar por cima de uma versão com mais traduções deixaria um código
    // que esta build não sabe mostrar.
    test('load ignora um idioma que não está na build', () async {
      repository.configuration = Configuration(1, languageCode: "fr");

      await controller.load();

      expect(controller.value, isNull);
    });

    test('uma falha de leitura não impede o app de abrir', () async {
      var broken = AppLocaleController(
          configurationRepository: _BrokenConfigurationRepository());
      addTearDown(broken.dispose);
      // O erro é reportado, e não deve ir parar na saída do teste.
      var reportados = <FlutterErrorDetails>[];
      var onError = FlutterError.onError;
      FlutterError.onError = reportados.add;
      addTearDown(() => FlutterError.onError = onError);

      await broken.load();

      expect(broken.value, isNull,
          reason: "sem configuração legível, vale o idioma do aparelho");
      expect(reportados, hasLength(1));
    });

    test('updateLanguage avisa quem estiver ouvindo', () async {
      var notificacoes = <Locale?>[];
      controller.addListener(() => notificacoes.add(controller.value));

      controller.updateLanguage("pt");
      controller.updateLanguage("");

      expect(notificacoes, [const Locale("pt"), null]);
    });
  });
}
