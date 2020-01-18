import 'dart:async';

import 'package:cotacao_direta/blocs/base_bloc.dart';
import 'package:cotacao_direta/enums/currency_enum.dart';
import 'package:cotacao_direta/model/currency.dart';
import 'package:cotacao_direta/repository/currency_repository.dart';
import 'package:cotacao_direta/util/string_utils.dart';
import 'package:flutter/widgets.dart';

class CurrencyHistoryBloc extends BaseBloc {
  var _currencyHistoryFromDateStreamController = StreamController();
  var _currencyHistoryToDateStreamController = StreamController();
  final _currencyHistoryFromDateController = TextEditingController();
  final _currencyHistoryToDateController = TextEditingController();
  final _currencyListStreamController = Map<String, StreamController>();
  final _currencyRepository = CurrencyRepository();


  CurrencyHistoryBloc() {
    Currencies.values.forEach((currency) {
      _currencyListStreamController[EnumValueAsString()
          .getEnumValue(currency.toString())] = StreamController.broadcast();
    });
  }

  Stream get currencyHistoryFromDateStream =>
      _currencyHistoryFromDateStreamController.stream;

  Stream get currencyHistoryToDateStream =>
      _currencyHistoryToDateStreamController.stream;

  Stream getCurrencySteam(currencyLabel) => _currencyListStreamController[currencyLabel].stream;

  TextEditingController get currencyHistoryFromDateController =>
      _currencyHistoryFromDateController;

  TextEditingController get currencyHistoryToDateController =>
      _currencyHistoryToDateController;

  updateFromDateValue(value) {
    _currencyHistoryFromDateStreamController.sink.add(value);
  }

  updateToDateValue(value) {
    _currencyHistoryToDateStreamController.sink.add(value);
  }

  updateCurrencyState(currencyLabel, selected){
    _currencyListStreamController[currencyLabel].add(selected);
  }

  Future<List<Currency>> _retriveHistoryData(currencyCodeList, initialDate, finalDate) async{
    return _currencyRepository.getCurrencyHistoricalData(currencyCodeList, initialDate, finalDate);
  }

  @override
  void dispose() {
    _currencyHistoryFromDateStreamController.close();
    _currencyHistoryToDateStreamController.close();
  }
}
