import 'dart:convert';

import 'package:cotacao_direta/model/configuration.dart';
import 'package:cotacao_direta/model/currency.dart';
import 'package:cotacao_direta/repository/currency_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../helpers/fakes.dart';

/// Item da AwesomeAPI. Os números vêm como texto e o `bid` está em unidades da
/// contrapartida por uma unidade da moeda cotada (USD-BRL: reais por dólar).
Map<String, String> _quote(
        {String code = "USD",
        String codein = "BRL",
        String name = "Dólar Americano/Real Brasileiro",
        String bid = "5.42",
        String ask = "5.43",
        String? timestamp}) =>
    {
      "code": code,
      "codein": codein,
      "name": name,
      "high": "5.45",
      "low": "5.40",
      "varBid": "-0.0021",
      "pctChange": "-0.04",
      "bid": bid,
      "ask": ask,
      "timestamp":
          timestamp ?? "${DateTime.now().millisecondsSinceEpoch ~/ 1000}",
      "create_date": "2026-07-24 17:00:00"
    };

String _lastResponse(Map<String, Map<String, String>> quotesByPair) =>
    jsonEncode(quotesByPair);

String _unixOf(DateTime date) => "${date.millisecondsSinceEpoch ~/ 1000}";

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

  /// Monta o repositório com um cliente HTTP que responde conforme o caminho da
  /// URL e registra tudo o que foi requisitado.
  CurrencyRepository buildRepository(
      {String? lastResponse,
      String? dailyResponse,
      String? availableResponse}) {
    var client = MockClient((request) async {
      requestedUris.add(request.url);
      var path = request.url.path;
      var body = path.contains("/available/")
          ? (availableResponse ??
              jsonEncode({"USD-BRL": "Dólar Americano/Real Brasileiro"}))
          : path.contains("/daily/")
              ? (dailyResponse ?? "[]")
              : (lastResponse ?? _lastResponse({"USDBRL": _quote()}));
      return http.Response.bytes(utf8.encode(body), 200,
          headers: {"content-type": "application/json; charset=utf-8"});
    });

    return CurrencyRepository.withDependencies(
        currencyDao: currencyDao,
        configurationRepository: configurationRepository,
        networkUtils: networkUtils,
        httpClient: client);
  }

  Uri lastUri() =>
      requestedUris.firstWhere((uri) => uri.path.contains("/last/"));

  Uri dailyUri() =>
      requestedUris.firstWhere((uri) => uri.path.contains("/daily/"));

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
      expect(identical(buildRepository(), CurrencyRepository()), isFalse);
    });
  });

  group('CurrencyRepository: montagem das URLs', () {
    setUp(() => currencyDao.latestCurrency = null);

    test('pede o par da moeda contra o real por padrão', () async {
      await buildRepository().getLatestDataByCurrencyCode("USD");

      expect(lastUri().host, "economia.awesomeapi.com.br");
      expect(lastUri().path, "/json/last/USD-BRL");
    });

    test('pede o par da moeda que foi solicitada, não a das configurações',
        () async {
      await buildRepository(
          lastResponse: _lastResponse({
        "EURBRL": _quote(code: "EUR", name: "Euro/Real Brasileiro", bid: "6.10")
      })).getLatestDataByCurrencyCode("EUR");

      expect(lastUri().path, "/json/last/EUR-BRL");
    });

    test('usa a moeda configurada como contrapartida', () async {
      configurationRepository.configuration = Configuration(1,
          overrideDefaultCurrency: true, selectedOverrideCurrencyCode: "EUR");

      await buildRepository(
          lastResponse: _lastResponse({
        "USDEUR": _quote(codein: "EUR", name: "Dólar Americano/Euro")
      })).getLatestDataByCurrencyCode("USD");

      expect(lastUri().path, "/json/last/USD-EUR");
    });

    test('ignora a moeda selecionada quando o override está desligado',
        () async {
      configurationRepository.configuration = Configuration(1,
          overrideDefaultCurrency: false, selectedOverrideCurrencyCode: "EUR");

      await buildRepository().getLatestDataByCurrencyCode("USD");

      expect(lastUri().path, "/json/last/USD-BRL");
    });

    test('cai no real quando o override está ligado sem moeda escolhida',
        () async {
      configurationRepository.configuration = Configuration(1,
          overrideDefaultCurrency: true, selectedOverrideCurrencyCode: "");

      await buildRepository().getLatestDataByCurrencyCode("USD");

      expect(lastUri().path, "/json/last/USD-BRL");
    });

    test('não consulta a API quando a moeda é a própria contrapartida',
        () async {
      var currency = await buildRepository().getLatestDataByCurrencyCode("BRL");

      expect(requestedUris, isEmpty);
      expect(currency!.value, 1);
    });
  });

  group('CurrencyRepository.getLatestDataByCurrencyCode', () {
    test('inverte o bid para a convenção que o app usa', () async {
      currencyDao.latestCurrency = null;

      var currency = await buildRepository(
              lastResponse: _lastResponse({"USDBRL": _quote(bid: "5.00")}))
          .getLatestDataByCurrencyCode("USD");

      // A tela mostra 1 / value, que precisa dar os 5,00 reais por dólar.
      expect(currency!.value, closeTo(0.2, 1e-9));
      expect(1 / currency.value!, closeTo(5.00, 1e-9));
    });

    test('lê o nome amigável do próprio item da cotação', () async {
      currencyDao.latestCurrency = null;

      var currency = await buildRepository().getLatestDataByCurrencyCode("USD");

      expect(currency!.friendlyName, "Dólar Americano");
      expect(requestedUris.map((uri) => uri.path),
          isNot(contains(contains("/available/"))),
          reason: "o nome vem junto da cotação, sem uma segunda chamada");
    });

    test('usa a data da cotação como historicalDate', () async {
      currencyDao.latestCurrency = null;
      var quoteDate = DateTime(2026, 7, 20, 15, 30);

      var currency = await buildRepository(
              lastResponse: _lastResponse(
                  {"USDBRL": _quote(timestamp: _unixOf(quoteDate))}))
          .getLatestDataByCurrencyCode("USD");

      expect(DateTime.parse(currency!.historicalDate!), quoteDate);
    });

    test('marca o timestamp com o momento da busca, que controla o cache',
        () async {
      currencyDao.latestCurrency = null;

      var currency = await buildRepository().getLatestDataByCurrencyCode("USD");

      expect(
          DateTime.parse(currency!.timestamp!)
              .isAfter(DateTime.now().subtract(Duration(minutes: 1))),
          isTrue);
    });

    test('grava a cotação nova', () async {
      currencyDao.latestCurrency = null;

      await buildRepository().getLatestDataByCurrencyCode("USD");

      expect(currencyDao.inserted.single.id, "USD");
    });

    test('aceita o par com chave fora do padrão', () async {
      currencyDao.latestCurrency = null;

      var currency = await buildRepository(
              lastResponse: _lastResponse({"USD_BRL": _quote(bid: "4.00")}))
          .getLatestDataByCurrencyCode("USD");

      expect(1 / currency!.value!, closeTo(4.00, 1e-9));
    });

    test('mantém a cotação salva quando a API responde com erro', () async {
      currencyDao.latestCurrency = Currency(
          id: "USD",
          value: 0.2,
          timestamp:
              DateTime.now().subtract(Duration(hours: 2)).toIso8601String(),
          historicalDate: "2026-07-01T00:00:00.000",
          friendlyName: "Dólar Americano");

      var currency = await buildRepository(
              lastResponse: jsonEncode(
                  {"status": 404, "code": "CoinNotExists", "message": "erro"}))
          .getLatestDataByCurrencyCode("USD");

      expect(currency!.value, 0.2, reason: "a última cotação boa continua");
      expect(currencyDao.inserted, isEmpty,
          reason: "não pode gravar um registro sem valor por cima");
    });

    test('mantém a cotação salva quando a resposta não é JSON', () async {
      currencyDao.latestCurrency = Currency(
          id: "USD",
          value: 0.2,
          timestamp:
              DateTime.now().subtract(Duration(hours: 2)).toIso8601String(),
          historicalDate: "2026-07-01T00:00:00.000",
          friendlyName: "Dólar Americano");

      var currency = await buildRepository(lastResponse: "<html>erro</html>")
          .getLatestDataByCurrencyCode("USD");

      expect(currency!.value, 0.2);
    });

    test('sem rede, devolve a cotação salva sem chamar a API', () async {
      networkUtils.available = false;
      currencyDao.latestCurrency = Currency(
          id: "USD",
          value: 0.2,
          timestamp: "2020-01-01T00:00:00.000",
          historicalDate: "2020-01-01T00:00:00.000",
          friendlyName: "Dólar Americano");

      var currency = await buildRepository().getLatestDataByCurrencyCode("USD");

      expect(currency!.value, 0.2);
      expect(requestedUris, isEmpty);
    });

    test('com rede e cotação recente, não consulta a API', () async {
      currencyDao.latestCurrency = Currency(
          id: "USD",
          value: 0.2,
          timestamp:
              DateTime.now().subtract(Duration(minutes: 30)).toIso8601String(),
          historicalDate: "2026-07-24T00:00:00.000",
          friendlyName: "Dólar Americano");

      var currency = await buildRepository().getLatestDataByCurrencyCode("USD");

      expect(currency!.value, 0.2);
      expect(requestedUris, isEmpty);
    });

    test('com rede e cotação vencida, busca de novo', () async {
      currencyDao.latestCurrency = Currency(
          id: "USD",
          value: 0.2,
          timestamp:
              DateTime.now().subtract(Duration(hours: 2)).toIso8601String(),
          historicalDate: "2026-07-01T00:00:00.000",
          friendlyName: "Dólar Americano");

      var currency = await buildRepository(
              lastResponse: _lastResponse({"USDBRL": _quote(bid: "6.00")}))
          .getLatestDataByCurrencyCode("USD");

      expect(1 / currency!.value!, closeTo(6.00, 1e-9));
    });

    test('timestamp inválido é tratado como vencido', () async {
      currencyDao.latestCurrency = Currency(
          id: "USD",
          value: 0.2,
          timestamp: "não é uma data",
          historicalDate: "2026-07-01T00:00:00.000",
          friendlyName: "Dólar Americano");

      await buildRepository().getLatestDataByCurrencyCode("USD");

      expect(
          requestedUris.map((uri) => uri.path), contains("/json/last/USD-BRL"));
    });

    test('sem rede e sem cotação salva, devolve null', () async {
      networkUtils.available = false;
      currencyDao.latestCurrency = null;

      expect(
          await buildRepository().getLatestDataByCurrencyCode("USD"), isNull);
      expect(requestedUris, isEmpty);
    });

    test('devolve null quando o código da moeda é nulo', () async {
      currencyDao.latestCurrency = null;

      expect(await buildRepository().getLatestDataByCurrencyCode(null), isNull);
      expect(requestedUris, isEmpty);
    });

    test('busca o nome amigável na lista quando o registro salvo não tem um',
        () async {
      currencyDao.latestCurrency = Currency(
          id: "USD",
          value: 0.2,
          timestamp: DateTime.now().toIso8601String(),
          historicalDate: "2026-07-24T00:00:00.000");

      var currency = await buildRepository().getLatestDataByCurrencyCode("USD");

      expect(currency!.friendlyName, "Dólar Americano");
      expect(currencyDao.inserted.single.friendlyName, "Dólar Americano");
      expect(requestedUris.single.path, "/json/available/uniq");
    });

    test('não estoura quando a lista de nomes vem em formato inesperado',
        () async {
      currencyDao.latestCurrency = Currency(
          id: "USD",
          value: 0.2,
          timestamp: DateTime.now().toIso8601String(),
          historicalDate: "2026-07-24T00:00:00.000");

      var currency = await buildRepository(availableResponse: '{"status": 500}')
          .getLatestDataByCurrencyCode("USD");

      expect(currency!.friendlyName, isNull);
    });
  });

  group('CurrencyRepository.getCurrencyHistoricalData', () {
    var dailyResponse = jsonEncode([
      _quote(bid: "5.00", timestamp: _unixOf(DateTime(2026, 7, 3))),
      _quote(bid: "4.90", timestamp: _unixOf(DateTime(2026, 7, 1))),
    ]);

    test('monta a URL do histórico com o par, o intervalo e o número de dias',
        () async {
      await buildRepository(dailyResponse: dailyResponse)
          .getCurrencyHistoricalData(["USD"], "2026-07-01", "2026-07-05");

      expect(dailyUri().path, "/json/daily/USD-BRL/5");
      expect(dailyUri().queryParameters["start_date"], "20260701");
      expect(dailyUri().queryParameters["end_date"], "20260705");
    });

    test('limita o número de dias ao teto da API', () async {
      await buildRepository(dailyResponse: dailyResponse)
          .getCurrencyHistoricalData(["USD"], "2020-01-01", "2026-07-05");

      expect(dailyUri().path, "/json/daily/USD-BRL/360");
    });

    test('usa a moeda configurada como contrapartida', () async {
      configurationRepository.configuration = Configuration(1,
          overrideDefaultCurrency: true, selectedOverrideCurrencyCode: "EUR");

      await buildRepository(dailyResponse: dailyResponse)
          .getCurrencyHistoricalData(["USD"], "2026-07-01", "2026-07-05");

      expect(dailyUri().path, "/json/daily/USD-EUR/5");
    });

    test('sem datas, pede o máximo e não deixa a URL com "?" solto', () async {
      await buildRepository(dailyResponse: dailyResponse)
          .getCurrencyHistoricalData(["USD"], "", "");

      expect(dailyUri().toString(),
          "https://economia.awesomeapi.com.br/json/daily/USD-BRL/360");
    });

    test('converte cada item da lista, invertendo o bid', () async {
      var result = await buildRepository(dailyResponse: dailyResponse)
          .getCurrencyHistoricalData(["USD"], "2026-07-01", "2026-07-05");

      expect(result, hasLength(2));
      expect(result.map((currency) => currency.id), ["USD", "USD"]);
      expect(1 / result.first.value!, closeTo(4.90, 1e-9));
      expect(result.first.friendlyName, "Dólar Americano");
    });

    test('devolve as cotações da mais antiga para a mais nova', () async {
      var result = await buildRepository(dailyResponse: dailyResponse)
          .getCurrencyHistoricalData(["USD"], "2026-07-01", "2026-07-05");

      expect(
          result.first.historicalDate, DateTime(2026, 7, 1).toIso8601String());
      expect(
          result.last.historicalDate, DateTime(2026, 7, 3).toIso8601String());
    });

    test('grava no banco as cotações recebidas', () async {
      await buildRepository(dailyResponse: dailyResponse)
          .getCurrencyHistoricalData(["USD"], "2026-07-01", "2026-07-05");

      expect(currencyDao.insertedBatches.single, hasLength(2));
    });

    test('não grava cotações com mais de dez anos, mas ainda as devolve',
        () async {
      var oldYear = DateTime.now().year - 11;
      var response = jsonEncode([
        _quote(bid: "2.00", timestamp: _unixOf(DateTime(oldYear, 1, 1))),
        _quote(bid: "5.00", timestamp: _unixOf(DateTime(2026, 7, 1))),
      ]);

      var result = await buildRepository(dailyResponse: response)
          .getCurrencyHistoricalData(["USD"], "2026-07-01", "2026-07-05");

      expect(result, hasLength(2));
      expect(currencyDao.insertedBatches.single, hasLength(1));
      expect(1 / currencyDao.insertedBatches.single.single.value!,
          closeTo(5.00, 1e-9));
    });

    test('consulta um par por moeda pedida', () async {
      await buildRepository(dailyResponse: dailyResponse)
          .getCurrencyHistoricalData(
              ["USD", "EUR"], "2026-07-01", "2026-07-05");

      expect(requestedUris.map((uri) => uri.path),
          ["/json/daily/USD-BRL/5", "/json/daily/EUR-BRL/5"]);
    });

    test('pula a moeda que é a própria contrapartida', () async {
      await buildRepository(dailyResponse: dailyResponse)
          .getCurrencyHistoricalData(
              ["USD", "BRL"], "2026-07-01", "2026-07-05");

      expect(requestedUris.map((uri) => uri.path), ["/json/daily/USD-BRL/5"]);
    });

    test('devolve lista vazia quando a API não traz cotações', () async {
      var result = await buildRepository(dailyResponse: "[]")
          .getCurrencyHistoricalData(["USD"], "2026-07-01", "2026-07-05");

      expect(result, isEmpty);
      expect(currencyDao.insertedBatches.single, isEmpty);
    });

    test('devolve lista vazia quando a resposta não é uma lista', () async {
      var result =
          await buildRepository(dailyResponse: jsonEncode({"status": 404}))
              .getCurrencyHistoricalData(["USD"], "2026-07-01", "2026-07-05");

      expect(result, isEmpty);
    });

    test('sem rede, delega ao DAO com os mesmos parâmetros', () async {
      networkUtils.available = false;
      currencyDao.historicalData = [
        Currency(id: "USD", value: 0.2, historicalDate: "2026-07-01")
      ];

      var result = await buildRepository()
          .getCurrencyHistoricalData(["USD"], "2026-07-01", "2026-07-05");

      expect(result, currencyDao.historicalData);
      expect(currencyDao.historicalDataCalls.single, [
        ["USD"],
        "2026-07-01",
        "2026-07-05"
      ]);
      expect(requestedUris, isEmpty);
    });
  });
}
