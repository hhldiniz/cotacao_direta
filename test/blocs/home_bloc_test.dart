import 'package:cotacao_direta/blocs/home_bloc.dart';
import 'package:cotacao_direta/enums/currency_enum.dart';
import 'package:cotacao_direta/model/configuration.dart';
import 'package:cotacao_direta/repository/currency_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fakes.dart';

void main() {
  // Sem repositório injetado, resolveCounterCurrency() cairia no
  // CurrencyRepository real e tentaria abrir o banco de verdade.
  HomeBloc buildBloc({Configuration? configuration}) => HomeBloc(
      currencyRepository: CurrencyRepository.withDependencies(
          configurationRepository:
              FakeConfigurationRepository(configuration: configuration)));

  group('HomeBloc.loadCounterCurrencyName', () {
    test('publica o real quando não há moeda sobrescrita', () async {
      var bloc = buildBloc();
      var stream = bloc.getNextStreamController();

      await bloc.loadCounterCurrencyName(const Locale("pt"));

      expect(await stream.first, "Real Brasileiro");
    });

    test('publica a moeda escolhida nas configurações, e não o dólar',
        () async {
      var bloc = buildBloc(
          configuration: Configuration(1,
              overrideDefaultCurrency: true,
              selectedOverrideCurrencyCode: "JPY"));
      var stream = bloc.getNextStreamController();

      await bloc.loadCounterCurrencyName(const Locale("pt"));

      expect(await stream.first, "Iene Japonês");
    });

    test('traduz o nome para o idioma da tela', () async {
      var bloc = buildBloc();
      var stream = bloc.getNextStreamController();

      await bloc.loadCounterCurrencyName(const Locale("en"));

      expect(await stream.first, "Brazilian Real");
    });

    test('não quebra se a stream já foi fechada', () async {
      var bloc = buildBloc();
      bloc.getNextStreamController();
      bloc.dispose();

      await expectLater(
          bloc.loadCounterCurrencyName(const Locale("pt")), completes);
    });
  });

  group('HomeBloc.loadHomeCurrencies', () {
    HomeBloc buildBlocWithConfiguration(Configuration configuration) => HomeBloc(
        currencyRepository: CurrencyRepository.withDependencies(
            configurationRepository:
                FakeConfigurationRepository(configuration: configuration)),
        configurationRepository:
            FakeConfigurationRepository(configuration: configuration));

    test('devolve as moedas escolhidas, na ordem gravada', () async {
      var bloc = buildBlocWithConfiguration(
          Configuration(1, homeCurrencyCodes: ["CHF", "GBP"]));

      expect(await bloc.loadHomeCurrencies(),
          [Currencies.CHF, Currencies.GBP]);
    });

    test('devolve as moedas padrão para quem nunca escolheu', () async {
      var bloc = buildBlocWithConfiguration(Configuration(1));

      expect(await bloc.loadHomeCurrencies(),
          [Currencies.USD, Currencies.EUR, Currencies.CAD, Currencies.JPY]);
    });

    test('descarta código que o app não conhece', () async {
      var bloc = buildBlocWithConfiguration(
          Configuration(1, homeCurrencyCodes: ["GBP", "XYZ"]));

      expect(await bloc.loadHomeCurrencies(), [Currencies.GBP]);
    });

    // A tela sem bolha nenhuma não diria ao usuário o que aconteceu.
    test('cai nas moedas padrão quando nenhum código é conhecido', () async {
      var bloc = buildBlocWithConfiguration(
          Configuration(1, homeCurrencyCodes: ["XYZ"]));

      expect(await bloc.loadHomeCurrencies(), HomeBloc.defaultHomeCurrencies);
    });
  });
}
