import 'dart:convert';

import 'package:cotacao_direta/model/configuration.dart';
import 'package:cotacao_direta/model/currency.dart';
import 'package:cotacao_direta/repository/currency_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../helpers/fakes.dart';

/// Resposta da API de nomes amigáveis (XML), usada em todas as chamadas.
const _friendlyNamesXml = '<?xml version="1.0" encoding="UTF-8"?>'
    '<currencies>'
    '<currency currencycode="USD" name="Dólar dos Estados Unidos"/>'
    '<currency currencycode="EUR" name="Euro"/>'
    '</currencies>';

void main() {
  late FakeCurrencyDao currencyDao;
  late FakeConfigurationRepository configurationRepository;
  late FakeNetworkUtils networkUtils;
  late List<Uri> requestedUris;

  setUp(() {
    currencyDao = FakeCurrencyDao();
    configurationRepository = FakeConfigurationRepository();
    networkUtils = FakeNetworkUtils();
    requestedUris = [];
  });

  tearDown(CurrencyRepository.resetInstance);

  /// Monta o repositório com um cliente HTTP que responde de acordo com o
  /// caminho da URL e registra tudo o que foi requisitado.
  CurrencyRepository buildRepository({String exchangeResponse = "[]"}) {
    var client = MockClient((request) async {
      requestedUris.add(request.url);
      if (request.url.path.contains("currencies")) {
        return http.Response.bytes(utf8.encode(_friendlyNamesXml), 200,
            headers: {"content-type": "application/xml; charset=utf-8"});
      }
      return http.Response.bytes(utf8.encode(exchangeResponse), 200,
          headers: {"content-type": "application/json; charset=utf-8"});
    });

    return CurrencyRepository.withDependencies(
        currencyDao: currencyDao,
        configurationRepository: configurationRepository,
        networkUtils: networkUtils,
        httpClient: client);
  }

  group('CurrencyRepository (singleton)', () {
    test('CurrencyRepository() devolve sempre a mesma instância', () {
      expect(identical(CurrencyRepository(), CurrencyRepository()), isTrue);
    });

    test('resetInstance descarta a instância anterior', () {
      var first = CurrencyRepository();
      CurrencyRepository.resetInstance();

      expect(identical(first, CurrencyRepository()), isFalse);
    });

    test('withDependencies não contamina o singleton', () {
      var injected = buildRepository();

      expect(identical(injected, CurrencyRepository()), isFalse);
    });
  });

  group('CurrencyRepository.getLatestDataByCurrencyCode', () {
    test('sem rede, devolve a cotação salva sem chamar a API', () async {
      networkUtils.available = false;
      currencyDao.latestCurrency = Currency(
          id: "USD",
          value: 5.0,
          timestamp: "2020-01-01T00:00:00.000",
          historicalDate: "2020-01-01T00:00:00.000",
          friendlyName: "Dólar dos Estados Unidos");

      var currency = await buildRepository().getLatestDataByCurrencyCode("USD");

      expect(currency!.value, 5.0);
      expect(requestedUris, isEmpty);
    });

    test('com rede e cotação recente, não consulta a API de cotação', () async {
      currencyDao.latestCurrency = Currency(
          id: "USD",
          value: 5.0,
          timestamp:
              DateTime.now().subtract(Duration(minutes: 30)).toIso8601String(),
          historicalDate: "2024-01-01T00:00:00.000",
          friendlyName: "Dólar dos Estados Unidos");

      var currency = await buildRepository().getLatestDataByCurrencyCode("USD");

      expect(currency!.value, 5.0);
      expect(requestedUris, isEmpty);
    });

    test('completa o nome amigável quando o registro salvo não tem um',
        () async {
      currencyDao.latestCurrency = Currency(
          id: "USD",
          value: 5.0,
          timestamp: DateTime.now().toIso8601String(),
          historicalDate: "2024-01-01T00:00:00.000");

      var currency = await buildRepository().getLatestDataByCurrencyCode("USD");

      expect(currency!.friendlyName, "Dólar dos Estados Unidos");
      expect(
          currencyDao.inserted.single.friendlyName, "Dólar dos Estados Unidos",
          reason: "o nome recuperado precisa ser gravado de volta");
      expect(requestedUris.single.path, contains("currencies"));
    });

    test('com rede e cotação vencida, busca na API e grava o resultado',
        () async {
      currencyDao.latestCurrency = Currency(
          id: "USD",
          value: 5.0,
          timestamp:
              DateTime.now().subtract(Duration(hours: 2)).toIso8601String(),
          historicalDate: "2024-01-01T00:00:00.000",
          friendlyName: "Dólar dos Estados Unidos");

      var currency = await buildRepository(
              exchangeResponse: '[{"currency_code": "USD", "value": 5.5}]')
          .getLatestDataByCurrencyCode("USD");

      expect(currency!.id, "USD");
      expect(currency.friendlyName, "Dólar dos Estados Unidos");
      expect(
          DateTime.parse(currency.timestamp!)
              .isAfter(DateTime.now().subtract(Duration(minutes: 1))),
          isTrue);
      expect(currencyDao.inserted.single.id, "USD");
      expect(
          requestedUris.map((uri) => uri.path), contains(contains("latest")));
    });

    test('sem cotação salva, busca na API', () async {
      currencyDao.latestCurrency = null;

      var currency = await buildRepository(
              exchangeResponse: '[{"currency_code": "USD", "value": 5.5}]')
          .getLatestDataByCurrencyCode("USD");

      expect(currency!.id, "USD");
      expect(currencyDao.inserted, hasLength(1));
    });

    test('timestamp inválido é tratado como vencido', () async {
      currencyDao.latestCurrency = Currency(
          id: "USD",
          value: 5.0,
          timestamp: "não é uma data",
          historicalDate: "2024-01-01T00:00:00.000",
          friendlyName: "Dólar dos Estados Unidos");

      await buildRepository(exchangeResponse: '[]')
          .getLatestDataByCurrencyCode("USD");

      expect(
          requestedUris.map((uri) => uri.path), contains(contains("latest")));
    });

    test('consulta a API usando USD por padrão', () async {
      currencyDao.latestCurrency = null;

      await buildRepository().getLatestDataByCurrencyCode("USD");

      var latestUri =
          requestedUris.firstWhere((uri) => uri.path.contains("latest"));
      expect(latestUri.queryParameters["symbol"], "USD");
    });

    test('respeita a moeda base configurada pelo usuário', () async {
      configurationRepository.configuration = Configuration(1,
          overrideDefaultCurrency: true, selectedOverrideCurrencyCode: "EUR");
      currencyDao.latestCurrency = null;

      await buildRepository().getLatestDataByCurrencyCode("EUR");

      var latestUri =
          requestedUris.firstWhere((uri) => uri.path.contains("latest"));
      expect(latestUri.queryParameters["symbol"], "EUR");
    });

    test('ignora a moeda selecionada quando o override está desligado',
        () async {
      configurationRepository.configuration = Configuration(1,
          overrideDefaultCurrency: false, selectedOverrideCurrencyCode: "EUR");
      currencyDao.latestCurrency = null;

      await buildRepository().getLatestDataByCurrencyCode("USD");

      var latestUri =
          requestedUris.firstWhere((uri) => uri.path.contains("latest"));
      expect(latestUri.queryParameters["symbol"], "USD");
    });

    // Comportamento atual: `jsonDecode(...).forEach(...)` devolve null, então a
    // cotação vinda da rede é sempre gravada sem valor.
    test('a cotação obtida na rede vem sem valor', () async {
      currencyDao.latestCurrency = null;

      var currency = await buildRepository(
              exchangeResponse: '[{"currency_code": "USD", "value": 5.5}]')
          .getLatestDataByCurrencyCode("USD");

      expect(currency!.value, isNull);
    });

    // Comportamento atual: `savedCurrency!` estoura quando não há rede e o
    // banco ainda está vazio (primeiro uso do app offline).
    test('sem rede e sem cotação salva, lança erro', () async {
      networkUtils.available = false;
      currencyDao.latestCurrency = null;

      expect(buildRepository().getLatestDataByCurrencyCode("USD"),
          throwsA(isA<TypeError>()));
    });
  });

  group('CurrencyRepository.getCurrencyHistoricalData', () {
    var ratesResponse = jsonEncode({
      "rates": {
        "2024-01-03": {"USD": 4.9},
        "2024-01-01": {"USD": 5.0, "EUR": 6.0},
      }
    });

    test('sem rede, delega ao DAO com os mesmos parâmetros', () async {
      networkUtils.available = false;
      currencyDao.historicalData = [
        Currency(id: "USD", value: 5.0, historicalDate: "2024-01-01")
      ];

      var result = await buildRepository()
          .getCurrencyHistoricalData(["USD"], "2024-01-01", "2024-01-31");

      expect(result, currencyDao.historicalData);
      expect(currencyDao.historicalDataCalls.single, [
        ["USD"],
        "2024-01-01",
        "2024-01-31"
      ]);
      expect(requestedUris, isEmpty);
    });

    test('com rede, converte o mapa de cotações em moedas', () async {
      var result = await buildRepository(exchangeResponse: ratesResponse)
          .getCurrencyHistoricalData(
              ["USD", "EUR"], "2024-01-01", "2024-01-31");

      expect(result, hasLength(3));
      var first = result.first;
      expect(first.id, "USD");
      expect(first.value, 5.0);
      expect(first.historicalDate, DateTime(2024, 1, 1).toIso8601String());
      expect(first.friendlyName, "Dólar dos Estados Unidos");
      expect(result.map((currency) => currency.friendlyName), contains("Euro"));
    });

    test('devolve as cotações ordenadas da mais antiga para a mais nova',
        () async {
      var result = await buildRepository(exchangeResponse: ratesResponse)
          .getCurrencyHistoricalData(["USD"], "2024-01-01", "2024-01-31");

      var dates =
          result.map((currency) => DateTime.parse(currency.historicalDate!));
      expect(dates.first.isAfter(dates.last), isFalse);
      expect(
          result.last.historicalDate, DateTime(2024, 1, 3).toIso8601String());
    });

    test('grava no banco as cotações recebidas', () async {
      await buildRepository(exchangeResponse: ratesResponse)
          .getCurrencyHistoricalData(["USD"], "2024-01-01", "2024-01-31");

      expect(currencyDao.insertedBatches.single, hasLength(3));
    });

    test('não grava cotações com mais de dez anos, mas ainda as devolve',
        () async {
      var oldYear = DateTime.now().year - 11;
      var response = jsonEncode({
        "rates": {
          "$oldYear-01-01": {"USD": 2.0},
          "2024-01-01": {"USD": 5.0},
        }
      });

      var result = await buildRepository(exchangeResponse: response)
          .getCurrencyHistoricalData(["USD"], "2024-01-01", "2024-01-31");

      expect(result, hasLength(2));
      expect(currencyDao.insertedBatches.single, hasLength(1));
      expect(currencyDao.insertedBatches.single.single.value, 5.0);
    });

    test('monta a URL do histórico com o intervalo, a base e os símbolos',
        () async {
      await buildRepository(exchangeResponse: ratesResponse)
          .getCurrencyHistoricalData(
              ["USD", "EUR"], "2024-01-01", "2024-01-31");

      var historyUri =
          requestedUris.firstWhere((uri) => uri.path.contains("history"));
      expect(historyUri.queryParameters["start_at"], "2024-01-01");
      expect(historyUri.queryParameters["end_at"], "2024-01-31");
      expect(historyUri.queryParameters["base"], "USD");
      expect(historyUri.queryParameters["symbols"], "USD, EUR");
    });

    test('usa a moeda base configurada na URL do histórico', () async {
      configurationRepository.configuration = Configuration(1,
          overrideDefaultCurrency: true, selectedOverrideCurrencyCode: "EUR");

      await buildRepository(exchangeResponse: ratesResponse)
          .getCurrencyHistoricalData(["USD"], "2024-01-01", "2024-01-31");

      var historyUri =
          requestedUris.firstWhere((uri) => uri.path.contains("history"));
      expect(historyUri.queryParameters["base"], "EUR");
    });

    test('devolve lista vazia quando a API não traz cotações', () async {
      var result =
          await buildRepository(exchangeResponse: jsonEncode({"rates": {}}))
              .getCurrencyHistoricalData(["USD"], "2024-01-01", "2024-01-31");

      expect(result, isEmpty);
      expect(currencyDao.insertedBatches.single, isEmpty);
    });
  });
}
