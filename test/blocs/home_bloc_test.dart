import 'package:cotacao_direta/blocs/home_bloc.dart';
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
}
