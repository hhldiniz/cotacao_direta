import 'package:cotacao_direta/dao/configuration_dao.dart';
import 'package:cotacao_direta/model/configuration.dart';
import 'package:cotacao_direta/util/database.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/database_test_helper.dart';

void main() {
  useInMemoryDatabase();

  late ConfigurationDao dao;

  setUp(() {
    dao = ConfigurationDao();
  });

  group('ConfigurationDao.getConfiguration', () {
    test('devolve uma configuração padrão quando a tabela está vazia',
        () async {
      var configuration = await dao.getConfiguration();

      expect(configuration.id, ConfigurationDao.configurationId);
      expect(configuration.overrideDefaultCurrency, isFalse);
      expect(configuration.selectedOverrideCurrencyCode, "");
      expect(configuration.homeCurrencyCodes,
          Configuration.defaultHomeCurrencyCodes);
    });

    test('lê a configuração gravada', () async {
      await dao.insert(Configuration(ConfigurationDao.configurationId,
          overrideDefaultCurrency: true, selectedOverrideCurrencyCode: "EUR"));

      var configuration = await dao.getConfiguration();

      expect(configuration.overrideDefaultCurrency, isTrue);
      expect(configuration.selectedOverrideCurrencyCode, "EUR");
    });

    test('converte o inteiro 0 de volta para false', () async {
      await dao.insert(Configuration(ConfigurationDao.configurationId,
          overrideDefaultCurrency: false, selectedOverrideCurrencyCode: "JPY"));

      var configuration = await dao.getConfiguration();

      expect(configuration.overrideDefaultCurrency, isFalse);
      expect(configuration.selectedOverrideCurrencyCode, "JPY");
    });

    test('ignora configurações com outro id', () async {
      await dao.insert(Configuration(99,
          overrideDefaultCurrency: true, selectedOverrideCurrencyCode: "GBP"));

      var configuration = await dao.getConfiguration();

      expect(configuration.id, ConfigurationDao.configurationId);
      expect(configuration.overrideDefaultCurrency, isFalse,
          reason: "só a linha de id 1 é usada pelo app");
    });
  });

  group('ConfigurationDao e as moedas da tela inicial', () {
    test('grava e lê de volta as moedas escolhidas', () async {
      await dao.insert(Configuration(ConfigurationDao.configurationId,
          homeCurrencyCodes: ["GBP", "CHF", "USD"]));

      var configuration = await dao.getConfiguration();

      expect(configuration.homeCurrencyCodes, ["GBP", "CHF", "USD"]);
    });

    test('uma lista vazia é lida como as moedas padrão', () async {
      await dao.insert(Configuration(ConfigurationDao.configurationId,
          homeCurrencyCodes: []));

      var configuration = await dao.getConfiguration();

      expect(configuration.homeCurrencyCodes,
          Configuration.defaultHomeCurrencyCodes);
    });
  });

  group('ConfigurationDao.insert', () {
    test('substitui a linha existente em vez de duplicá-la', () async {
      await dao.insert(Configuration(ConfigurationDao.configurationId,
          overrideDefaultCurrency: true, selectedOverrideCurrencyCode: "EUR"));
      await dao.insert(Configuration(ConfigurationDao.configurationId,
          overrideDefaultCurrency: false, selectedOverrideCurrencyCode: "CHF"));

      var db = (await AppDatabase().openAppDatabase())!;
      var rows = await db.query("Configurations");

      expect(rows.length, 1);
      var configuration = await dao.getConfiguration();
      expect(configuration.overrideDefaultCurrency, isFalse);
      expect(configuration.selectedOverrideCurrencyCode, "CHF");
    });

    test('grava o booleano como inteiro na coluna', () async {
      await dao.insert(Configuration(ConfigurationDao.configurationId,
          overrideDefaultCurrency: true));

      var db = (await AppDatabase().openAppDatabase())!;
      var rows = await db.query("Configurations");

      expect(rows.single["overrideDefaultCurrency"], 1);
    });

    test('aceita código de moeda nulo', () async {
      await dao.insert(Configuration(ConfigurationDao.configurationId,
          selectedOverrideCurrencyCode: null));

      var configuration = await dao.getConfiguration();

      expect(configuration.selectedOverrideCurrencyCode, isNull);
    });
  });
}
