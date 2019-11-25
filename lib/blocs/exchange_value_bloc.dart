import 'dart:async';
import 'dart:convert';

import 'package:cotacao_direta/dao/currency_dao.dart';
import 'package:cotacao_direta/enums/currency_enum.dart';
import 'package:cotacao_direta/model/currency.dart';
import 'package:cotacao_direta/util/string_utils.dart';
import 'package:http/http.dart' as http;

import 'base_bloc.dart';

class ExchangeValueBloc extends BaseBloc
{
  final valueController = StreamController.broadcast();

  final String _exchangeRateApi = "https://api.exchangeratesapi.io/latest?base=BRL";

  Stream get getExchangeValueStream => valueController.stream;

  final _currencyDao = CurrencyDao();

  void updateValue(value){
    valueController.sink.add(value);
  }

  Future<double> retrieveRemoteValue(Currencies currency) async
  {
    String currencyCode = EnumValueAsString().getEnumValue(currency.toString());
    Currency dbCurrency = await _currencyDao.getByCurrencyCode(currencyCode);
    if(dbCurrency != null && isCurrencyTimestampValid(dbCurrency.timestamp))
      return dbCurrency.value;
    else{
      var response =  await http.get(_exchangeRateApi);
      var currencyValue = jsonDecode(response.body)["rates"][currencyCode];
      _currencyDao.insert(Currency(
        id: currencyCode,
        value: currencyValue,
        timestamp: DateTime.now().toIso8601String()
      ));
      return currencyValue;
    }
  }

  bool isCurrencyTimestampValid(String timeStamp){
    try{
      var timeStampDate = DateTime.parse(timeStamp);
      return DateTime.now().difference(timeStampDate).inHours < 1;
    }catch(exception){
      return false;
    }

  }

  @override
  void dispose() {
    valueController.close();
  }

}