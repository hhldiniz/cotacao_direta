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
  static CurrencyRepository _instance;
  final CurrencyDao _currencyDao = CurrencyDao();
  final ConfigurationRepository _configurationRepository =
      ConfigurationRepository();
  final NetworkUtils _networkUtils = NetworkUtils();
  final String _exchangeRateApi =
      "https://api.exchangeratesapi.io/latest?base=%s";
  final String _exchangeHistoricalRateApi =
      "https://api.exchangeratesapi.io/history?start_at=%s&end_at=%s&base=%s&symbols=%s";
  final _enumValueAsStringUtil = EnumValueAsString();
  final _currencyCodeFriendlyNameApi =
      "https://supply-xml.booking.com/hotels/xml/currencies";

  factory CurrencyRepository() {
    if (_instance == null)
      _instance = CurrencyRepository._internalConstructor();
    return _instance;
  }

  CurrencyRepository._internalConstructor();

  Future<Uri> _resolveExchangeRateApiUri() async {
    final configuration = await _configurationRepository.getConfiguration();
    return Uri.parse(sprintf(_exchangeRateApi, [
      configuration.overrideDefaultCurrency
          ? configuration.selectedOverrideCurrencyCode
          : _enumValueAsStringUtil.getEnumValue(Currencies.USD.toString())
    ]));
  }

  Future<Uri> _resolveExchangeHistoricalRateApiUri(
      currencyCodeList, initialDate, finalDate) async {
    final configuration = await _configurationRepository.getConfiguration();
    return Uri.parse(sprintf(_exchangeHistoricalRateApi, [
      initialDate,
      finalDate,
      configuration.overrideDefaultCurrency
          ? configuration.selectedOverrideCurrencyCode
          : _enumValueAsStringUtil.getEnumValue(Currencies.USD.toString()),
      currencyCodeList.join(", ")
    ]));
  }

  Future<Map<String, String>> _friendlyCurrencyCodeNameList() async {
    var response = await http.get(Uri.parse(_currencyCodeFriendlyNameApi));
    var friendlyCurrencyNamesMap = Map<String, String>();
    XmlDocument.parse(response.body)
        .getElement("currencies")
        .children
        .forEach((child) {
      friendlyCurrencyNamesMap[child.getAttribute("currencycode")] =
          child.getAttribute("name");
    });
    return friendlyCurrencyNamesMap;
  }

  Future<Currency> getLatestDataByCurrencyCode(String currencyCode) async {
    var networkAvailable = await _networkUtils.isNetworkAvailable();
    var savedCurrency =
        await _currencyDao.getLatestDataByCurrencyCode(currencyCode);
    if (networkAvailable &&
        (savedCurrency == null ||
            !_isCurrencyTimestampValid(savedCurrency.timestamp))) {
      var response = await http.get(await _resolveExchangeRateApiUri());
      var currencyValue = jsonDecode(response.body)["rates"][currencyCode];
      var now = DateTime.now().toIso8601String();
      var newCurrency = Currency(
          id: currencyCode,
          value: currencyValue,
          historicalDate: now,
          timestamp: now,
          friendlyName: (await _friendlyCurrencyCodeNameList())[currencyCode]);
      _currencyDao.insert(newCurrency);
      return newCurrency;
    } else{
      if(savedCurrency.friendlyName == null){
        savedCurrency.friendlyName = (await _friendlyCurrencyCodeNameList())[currencyCode];
        _currencyDao.insert(savedCurrency);
      }
      return savedCurrency;
    }
  }

  Future<List<Currency>> getCurrencyHistoricalData(
      List<String> currencyCodeList, initialDate, finalDate) async {
    if (await _networkUtils.isNetworkAvailable()) {
      var response = await http.get(await _resolveExchangeHistoricalRateApiUri(
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
      _currencyDao.insertMany(currencyListToSave
          .where((currency) =>
              (DateTime.now().year -
                  DateTime.parse(currency.historicalDate).year) <
              10)
          .toList());
      currencyListToSave.sort((a, b) {
        DateTime dateCurrencyA = DateTime.parse(a.historicalDate);
        DateTime dateCurrencyB = DateTime.parse(b.historicalDate);
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

  bool _isCurrencyTimestampValid(String timeStamp) {
    try {
      var timeStampDate = DateTime.parse(timeStamp);
      return DateTime.now().difference(timeStampDate).inHours < 1;
    } catch (exception) {
      return false;
    }
  }
}
