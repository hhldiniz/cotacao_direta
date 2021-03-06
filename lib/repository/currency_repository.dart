import 'dart:convert';

import 'package:cotacao_direta/dao/currency_dao.dart';
import 'package:cotacao_direta/model/currency.dart';
import 'package:cotacao_direta/util/network_util.dart';
import 'package:http/http.dart' as http;


class CurrencyRepository{
  static CurrencyRepository _instance;
  final CurrencyDao _currencyDao = CurrencyDao();
  final NetworkUtils _networkUtils = NetworkUtils();
  final String _exchangeRateApi = "https://api.exchangeratesapi.io/latest?base=BRL";

  factory CurrencyRepository(){
    if(_instance == null) _instance = CurrencyRepository._internalConstructor();
    return _instance;
  }

  CurrencyRepository._internalConstructor();

  Future<Currency> getByCurrencyCode(String currencyCode) async{
    var networkAvailable = await _networkUtils.isNetworkAvailable();
    var savedCurrency = await _currencyDao.getByCurrencyCode(currencyCode);

    if(networkAvailable && (savedCurrency == null || !_isCurrencyTimestampValid(savedCurrency.timestamp))){
      var response =  await http.get(_exchangeRateApi);
      var currencyValue = jsonDecode(response.body)["rates"][currencyCode];
      var newCurrency = Currency(
          id: currencyCode,
          value: currencyValue,
          timestamp: DateTime.now().toIso8601String()
      );
      _currencyDao.insert(newCurrency);
      return newCurrency;
    }
    else
      return savedCurrency;
  }

  bool _isCurrencyTimestampValid(String timeStamp){
    try{
      var timeStampDate = DateTime.parse(timeStamp);
      return DateTime.now().difference(timeStampDate).inHours < 1;
    }catch(exception){
      return false;
    }

  }

}