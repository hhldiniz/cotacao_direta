import 'package:cotacao_direta/blocs/configurations_page_bloc.dart';
import 'package:cotacao_direta/model/configuration.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fakes.dart';

void main() {
  late FakeConfigurationRepository repository;
  late ConfigurationsPageBloc bloc;

  setUp(() {
    repository = FakeConfigurationRepository();
    bloc = ConfigurationsPageBloc(configurationRepository: repository);
  });

  tearDown(() => bloc.dispose());

  group('ConfigurationsPageBloc e as moedas da tela inicial', () {
    test('começa nas moedas padrão', () {
      expect(bloc.homeCurrencyCodes, Configuration.defaultHomeCurrencyCodes);
    });

    test('publica as moedas escolhidas e as grava', () async {
      var published = bloc.homeCurrenciesStream.first;

      await bloc.updateHomeCurrencies(["GBP", "CHF"]);

      expect(await published, ["GBP", "CHF"]);
      expect(bloc.homeCurrencyCodes, ["GBP", "CHF"]);
      expect(repository.inserted.single.homeCurrencyCodes, ["GBP", "CHF"]);
    });

    // Gravar lista vazia significaria "nunca escolheu", que traz de volta as
    // moedas padrão sem o usuário ter pedido.
    test('ignora uma lista vazia', () async {
      await bloc.updateHomeCurrencies(["GBP"]);

      await bloc.updateHomeCurrencies([]);

      expect(bloc.homeCurrencyCodes, ["GBP"]);
      expect(repository.configuration.homeCurrencyCodes, ["GBP"]);
    });

    test('loadCurrentConfiguration publica o que está gravado', () async {
      repository.configuration =
          Configuration(1, homeCurrencyCodes: ["CHF", "USD"]);
      var published = bloc.homeCurrenciesStream.first;

      bloc.loadCurrentConfiguration();

      expect(await published, ["CHF", "USD"]);
      expect(bloc.homeCurrencyCodes, ["CHF", "USD"]);
    });

    test('não mexe na moeda de contrapartida já gravada', () async {
      repository.configuration = Configuration(1,
          overrideDefaultCurrency: true, selectedOverrideCurrencyCode: "EUR");

      await bloc.updateHomeCurrencies(["GBP"]);

      var configuration = repository.configuration;
      expect(configuration.overrideDefaultCurrency, isTrue);
      expect(configuration.selectedOverrideCurrencyCode, "EUR");
      expect(configuration.homeCurrencyCodes, ["GBP"]);
    });
  });
}
