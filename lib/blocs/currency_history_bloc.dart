import 'dart:async';

import 'package:cotacao_direta/blocs/base_bloc.dart';

class CurrencyHistoryBloc extends BaseBloc{
  var _currencyHistoryFromDateStreamController = StreamController();
  var _currencyHistoryToDateStreamController = StreamController();

  Stream get currencyHistoryFromDateStream => _currencyHistoryFromDateStreamController.stream;

  Stream get currencyHistoryToDateStream => _currencyHistoryToDateStreamController.stream;

  updateFromDateValue(value){
    _currencyHistoryFromDateStreamController.sink.add(value);
  }

  updateToDateValue(value){
    _currencyHistoryToDateStreamController.sink.add(value);
  }

  @override
  void dispose() {
    _currencyHistoryFromDateStreamController.close();
    _currencyHistoryToDateStreamController.close();
  }

}