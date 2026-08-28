import 'package:cotacao_direta/blocs/configurations_page_bloc.dart';
import 'package:cotacao_direta/model/configuration.dart';
import 'package:cotacao_direta/util/app_locale_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fakes.dart';

void main() {
  late FakeConfigurationRepository repository;
  late AppLocaleController localeController;
  late ConfigurationsPageBloc bloc;

  setUp(() {
    repository = FakeConfigurationRepository();
    localeController =
        AppLocaleController(configurationRepository: repository);
    bloc = ConfigurationsPageBloc(
        configurationRepository: repository,
        localeController: localeController);
  });

  tearDown(() {
    bloc.dispose();
    localeController.dispose();
  });

  group('ConfigurationsPageBloc e o idioma da interface', () {
    test('começa seguindo o idioma do aparelho', () {
      expect(bloc.languageCode, "");
      expect(localeController.value, isNull);
    });

    test('publica o idioma escolhido, grava e aplica na interface', () async {
      var published = bloc.languageStream.first;

      await bloc.updateLanguage("en");

      expect(await published, "en");
      expect(bloc.languageCode, "en");
      expect(repository.inserted.single.languageCode, "en");
      expect(localeController.value, const Locale("en"));
    });

    // Voltar para o idioma do aparelho é a opção padrão da lista, e precisa
    // apagar a escolha gravada em vez de deixá-la no banco.
    test('código vazio volta a seguir o aparelho', () async {
      await bloc.updateLanguage("pt");

      await bloc.updateLanguage("");

      expect(bloc.languageCode, "");
      expect(repository.configuration.languageCode, "");
      expect(localeController.value, isNull);
    });

    test('nulo é lido como o idioma do aparelho', () async {
      await bloc.updateLanguage(null);

      expect(bloc.languageCode, "");
      expect(localeController.value, isNull);
    });

    // Um idioma que esta build não tem — vindo de uma versão anterior com mais
    // traduções — não pode deixar a interface sem textos.
    test('um idioma fora da build cai no do aparelho', () async {
      await bloc.updateLanguage("fr");

      expect(localeController.value, isNull,
          reason: "o app não tem tradução para esse código");
    });

    test('não mexe nas outras configurações ao gravar o idioma', () async {
      repository.configuration = Configuration(1,
          overrideDefaultCurrency: true,
          selectedOverrideCurrencyCode: "EUR",
          homeCurrencyCodes: ["GBP"]);

      await bloc.updateLanguage("en");

      var configuration = repository.configuration;
      expect(configuration.overrideDefaultCurrency, isTrue);
      expect(configuration.selectedOverrideCurrencyCode, "EUR");
      expect(configuration.homeCurrencyCodes, ["GBP"]);
      expect(configuration.languageCode, "en");
    });

    test('loadCurrentConfiguration publica o idioma gravado', () async {
      repository.configuration = Configuration(1, languageCode: "en");
      var published = bloc.languageStream.first;

      bloc.loadCurrentConfiguration();

      expect(await published, "en");
      expect(bloc.languageCode, "en");
    });
  });
}
