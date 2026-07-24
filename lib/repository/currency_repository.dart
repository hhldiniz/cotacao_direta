import 'dart:convert';

import 'package:cotacao_direta/dao/currency_dao.dart';
import 'package:cotacao_direta/enums/currency_enum.dart';
import 'package:cotacao_direta/model/currency.dart';
import 'package:cotacao_direta/repository/configuration_repository.dart';
import 'package:cotacao_direta/util/network_util.dart';
import 'package:cotacao_direta/util/string_utils.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:sprintf/sprintf.dart';
import 'package:xml/xml.dart';

class CurrencyRepository {
  static CurrencyRepository? _instance;
  final CurrencyDao _currencyDao;
  final ConfigurationRepository _configurationRepository;
  final NetworkUtils _networkUtils;
  final http.Client _httpClient;
  /*final String _exchangeRateApi =
      "https://european-exchange-api.herokuapp.com/latest?access_key=%s&symbol=%s";*/
  final String _exchangeRateApi =
      "https://european-exchange-api.herokuapp.com/latest?symbol=%s";
  /*final String _exchangeHistoricalRateApi =
      "https://european-exchange-api.herokuapp.com/history?access_key=%s&start_at=%s&end_at=%s&base=%s&symbols=%s";*/
  final String _exchangeHistoricalRateApi =
      "https://european-exchange-api.herokuapp.com/history?start_at=%s&end_at=%s&base=%s&symbols=%s";
  final _enumValueAsStringUtil = EnumValueAsString();
  final _currencyCodeFriendlyNameApi =
      "https://european-exchange-api.herokuapp.com/currencies";
  //final String? _apiKey = null;

  factory CurrencyRepository() {
    if (_instance == null)
      _instance = CurrencyRepository._internalConstructor();
    return _instance!;
  }

  /// Cria uma instância isolada (fora do singleton) com as dependências
  /// fornecidas pelo chamador. Usado pelos testes.
  factory CurrencyRepository.withDependencies(
          {CurrencyDao? currencyDao,
          ConfigurationRepository? configurationRepository,
          NetworkUtils? networkUtils,
          http.Client? httpClient}) =>
      CurrencyRepository._internalConstructor(
          currencyDao: currencyDao,
          configurationRepository: configurationRepository,
          networkUtils: networkUtils,
          httpClient: httpClient);

  CurrencyRepository._internalConstructor(
      {CurrencyDao? currencyDao,
      ConfigurationRepository? configurationRepository,
      NetworkUtils? networkUtils,
      http.Client? httpClient})
      : _currencyDao = currencyDao ?? CurrencyDao(),
        _configurationRepository =
            configurationRepository ?? ConfigurationRepository(),
        _networkUtils = networkUtils ?? NetworkUtils(),
        _httpClient = httpClient ?? http.Client();

  /// Descarta o singleton para que um teste não vaze estado para o seguinte.
  static void resetInstance() => _instance = null;

  /*Future<String> checkAndRetrieveApiKey() async {
    return _apiKey ??
        jsonDecode(await rootBundle.loadString('assets/secrets/secrets.json'))[
            'exchange_api_key'];
  }*/

  Future<Uri> _resolveExchangeRateApiUri() async {
    // final apiKey = await checkAndRetrieveApiKey();
    final configuration = await _configurationRepository.getConfiguration();
    return Uri.parse(sprintf(_exchangeRateApi, [
      /*apiKey,*/
      configuration.overrideDefaultCurrency
          ? configuration.selectedOverrideCurrencyCode
          : _enumValueAsStringUtil.getEnumValue(Currencies.USD.toString())
    ]));
  }

  Future<Uri> _resolveExchangeHistoricalRateApiUri(
      currencyCodeList, initialDate, finalDate) async {
    //final apiKey = await checkAndRetrieveApiKey();
    final configuration = await _configurationRepository.getConfiguration();
    return Uri.parse(sprintf(_exchangeHistoricalRateApi, [
      /*apiKey,*/
      initialDate,
      finalDate,
      configuration.overrideDefaultCurrency
          ? configuration.selectedOverrideCurrencyCode
          : _enumValueAsStringUtil.getEnumValue(Currencies.USD.toString()),
      currencyCodeList.join(", ")
    ]));
  }

  Future<Map<String?, String?>> _friendlyCurrencyCodeNameList() async {
    var response =
        await _httpClient.get(Uri.parse(_currencyCodeFriendlyNameApi));
    var friendlyCurrencyNamesMap = Map<String?, String?>();
    XmlDocument.parse(response.body)
        .getElement("currencies")!
        .children
        .forEach((child) {
      friendlyCurrencyNamesMap[child.getAttribute("currencycode")] =
          child.getAttribute("name");
    });
    return friendlyCurrencyNamesMap;
  }

  Future<Currency?> getLatestDataByCurrencyCode(String? currencyCode) async {
    var networkAvailable = await _networkUtils.isNetworkAvailable();
    var savedCurrency =
        await _currencyDao.getLatestDataByCurrencyCode(currencyCode);
    if (networkAvailable &&
        (savedCurrency == null ||
            !_isCurrencyTimestampValid(savedCurrency.timestamp))) {
      var response = await _httpClient.get(await _resolveExchangeRateApiUri());
      var currencyValue = _extractCurrencyValue(response.body, currencyCode);
      var now = DateTime.now().toIso8601String();
      var newCurrency = Currency(
          id: currencyCode,
          value: currencyValue,
          historicalDate: now,
          timestamp: now,
          friendlyName: (await _friendlyCurrencyCodeNameList())[currencyCode]);
      await _currencyDao.insert(newCurrency);
      return newCurrency;
    } else {
      // Sem rede e sem nada salvo não há o que devolver: é o primeiro uso do
      // aplicativo offline.
      if (savedCurrency == null) return null;
      if (savedCurrency.friendlyName?.isNotEmpty != true) {
        savedCurrency.friendlyName =
            (await _friendlyCurrencyCodeNameList())[currencyCode];
        await _currencyDao.insert(savedCurrency);
      }
      return savedCurrency;
    }
  }

  Future<List<Currency>> getCurrencyHistoricalData(
      List<String> currencyCodeList, initialDate, finalDate) async {
    if (await _networkUtils.isNetworkAvailable()) {
      var response = await _httpClient.get(
          await _resolveExchangeHistoricalRateApiUri(
              currencyCodeList, initialDate, finalDate));
      var friendlyNames = await _friendlyCurrencyCodeNameList();
      List<MapEntry> jsonData =
          jsonDecode(response.body)["rates"].entries.toList();
      var currencyListToSave = <Currency>[];
      jsonData.forEach((MapEntry element) {
        var historicalDate = DateFormat("yyyy-MM-dd").parse(element.key);

        element.value.entries.forEach((MapEntry currencyEntry) {
          currencyListToSave.add(Currency(
              id: currencyEntry.key,
              historicalDate: historicalDate.toIso8601String(),
              value: currencyEntry.value,
              timestamp: DateTime.now().toIso8601String(),
              friendlyName: friendlyNames[currencyEntry.key]));
        });
      });
      await _currencyDao.insertMany(currencyListToSave
          .where((currency) =>
              (DateTime.now().year -
                  DateTime.parse(currency.historicalDate!).year) <
              10)
          .toList());
      currencyListToSave.sort((a, b) {
        DateTime dateCurrencyA = DateTime.parse(a.historicalDate!);
        DateTime dateCurrencyB = DateTime.parse(b.historicalDate!);
        if (dateCurrencyA.isBefore(dateCurrencyB)) {
          return -1;
        } else if (dateCurrencyA.isAfter(dateCurrencyB)) {
          return 1;
        } else {
          return 0;
        }
      });
      return currencyListToSave;
    } else
      return await _currencyDao.getHistoricalData(
          currencyCodeList, initialDate, finalDate);
  }

  /// Nomes de campo já usados pela API para carregar a cotação, em ordem de
  /// preferência.
  static const _valueFieldNames = [
    "value",
    "rate",
    "exchange_rate",
    "currency_value"
  ];

  /// A API devolve uma lista de itens identificados por `currency_code`. O nome
  /// do campo com a cotação já mudou entre versões da API, então procuramos os
  /// nomes conhecidos e, se nenhum aparecer, o primeiro campo numérico do item.
  double? _extractCurrencyValue(String responseBody, String? currencyCode) {
    var decoded = jsonDecode(responseBody);
    if (decoded is! List) return null;
    var item = decoded.firstWhere(
        (element) => element is Map && element["currency_code"] == currencyCode,
        orElse: () => null);
    if (item is! Map) return null;

    for (var fieldName in _valueFieldNames) {
      var value = _asDouble(item[fieldName]);
      if (value != null) return value;
    }
    for (var entry in item.entries) {
      if (entry.key == "currency_code") continue;
      var value = _asDouble(entry.value);
      if (value != null) return value;
    }
    return null;
  }

  double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  bool _isCurrencyTimestampValid(String? timeStamp) {
    if (timeStamp == null) return false;
    try {
      var timeStampDate = DateTime.parse(timeStamp);
      return DateTime.now().difference(timeStampDate).inHours < 1;
    } catch (exception) {
      return false;
    }
  }
}
