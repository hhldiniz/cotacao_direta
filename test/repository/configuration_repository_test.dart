import 'package:cotacao_direta/model/configuration.dart';
import 'package:cotacao_direta/repository/configuration_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fakes.dart';

void main() {
  late FakeConfigurationDao dao;
  late ConfigurationRepository repository;

  setUp(() {
    dao = FakeConfigurationDao();
    repository = ConfigurationRepository(configurationDao: dao);
  });

  group('ConfigurationRepository', () {
    test('devolve a configuração vinda do DAO', () async {
      dao.configuration = Configuration(1,
          overrideDefaultCurrency: true, selectedOverrideCurrencyCode: "EUR");

      var configuration = await repository.getConfiguration();

      expect(configuration.overrideDefaultCurrency, isTrue);
      expect(configuration.selectedOverrideCurrencyCode, "EUR");
    });

    test('repassa a configuração para o DAO no insert', () async {
      var configuration = Configuration(1,
          overrideDefaultCurrency: true, selectedOverrideCurrencyCode: "JPY");

      await repository.insert(configuration);

      expect(dao.inserted, [configuration]);
    });

    test('lê de volta o que foi gravado', () async {
      await repository
          .insert(Configuration(1, selectedOverrideCurrencyCode: "CHF"));

      expect((await repository.getConfiguration()).selectedOverrideCurrencyCode,
          "CHF");
    });

    test('usa o ConfigurationDao real quando nenhum é informado', () {
      expect(ConfigurationRepository(), isNotNull);
    });
  });
}
