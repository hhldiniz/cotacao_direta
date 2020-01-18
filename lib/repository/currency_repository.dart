import 'dart:convert';

import 'package:cotacao_direta/dao/currency_dao.dart';
import 'package:cotacao_direta/model/currency.dart';
import 'package:cotacao_direta/util/network_util.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:sprintf/sprintf.dart';

class CurrencyRepository {
  static CurrencyRepository _instance;
  final CurrencyDao _currencyDao = CurrencyDao();
  final NetworkUtils _networkUtils = NetworkUtils();
  final String _exchangeRateApi =
      "https://api.exchangeratesapi.io/latest?base=BRL";
  final String _exchangeHistoricalRateApi =
      "https://api.exchangeratesapi.io/history?start_at=%s&end_at=%s";

  factory CurrencyRepository() {
    if (_instance == null)
      _instance = CurrencyRepository._internalConstructor();
    return _instance;
  }

  CurrencyRepository._internalConstructor();

  Future<Currency> getLatestDataByCurrencyCode(String currencyCode) async {
    var networkAvailable = await _networkUtils.isNetworkAvailable();
    var savedCurrency =
    await _currencyDao.getLatestDataByCurrencyCode(currencyCode);

    if (networkAvailable &&
        (savedCurrency == null ||
            !_isCurrencyTimestampValid(savedCurrency.timestamp))) {
      var response = await http.get(_exchangeRateApi);
      var currencyValue = jsonDecode(response.body)["rates"][currencyCode];
      var now = DateTime.now().toIso8601String();
      var newCurrency = Currency(
          id: currencyCode,
          value: currencyValue,
          historicalDate: now,
          timestamp: now);
      _currencyDao.insert(newCurrency);
      return newCurrency;
    } else
      return savedCurrency;
  }

  Future<List<Currency>> getCurrencyHistoricalData(
      List<String> currencyCodeList, initialDate, finalDate) async {
    var isNetworkAvailable = await _networkUtils.isNetworkAvailable();
    var savedHistoricalDate = await _currencyDao.getHistoricalData(
        currencyCodeList, initialDate, finalDate);
    if (savedHistoricalDate.isNotEmpty)
      return savedHistoricalDate;
    else if (isNetworkAvailable) {
      var response = await http
          .get(sprintf(_exchangeHistoricalRateApi, [initialDate, finalDate]));
      List<Map<String, Map<String, double>>> jsonData =
      jsonDecode(response.body);
      var currencyListToSave = List<Currency>();
      for (var index = 0; index < jsonData.length; index++) {
        var historicalDate = DateFormat("yyyy-MM-dd")
            .parse(jsonData[index].keys.elementAt(index));
        jsonData[index].forEach((key, value) {
          currencyListToSave.add(Currency(
              id: key,
              historicalDate: historicalDate.toIso8601String(),
              value: value[key],
              timestamp: DateTime.now().toIso8601String()));
        });
      }
      _currencyDao.insertMany(currencyListToSave.where((currency) =>
      (DateTime.now().year - DateTime.parse(currency.historicalDate).year) <
          10));
      return currencyListToSave;
    } else
      return Iterable.empty();
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
