import 'dart:async';

import 'package:cotacao_direta/blocs/base_bloc.dart';

class ConversionPageBloc extends BaseBloc{

  var _multiplierStreamController = StreamController();
  var _currencyFromStreamController = StreamController();
  var _currencyToStreamController = StreamController();
  var _conversionResultStreamController = StreamController();

  var _multiplierValue = 0;
  var _selectedFromCurrency = "";
  var _selectedToCurrency = "";

  Stream get multiplierStream => _multiplierStreamController.stream;

  Sink get multiplierSink => _multiplierStreamController.sink;

  Stream get currencyFromStream => _currencyFromStreamController.stream;

  Sink get currencyFromSink => _currencyFromStreamController.sink;

  Stream get currencyToStream => _currencyToStreamController.stream;

  Sink get currencyToSink => _currencyToStreamController.sink;

  Stream get conversionResultStream => _conversionResultStreamController.stream;

  Sink get conversionResultSink => _conversionResultStreamController.sink;

  updateMultiplierValue(value){
    _multiplierValue = value;
    multiplierSink.add(_multiplierValue);
  }

  updateFromCurrency(value){
    _selectedFromCurrency = value;
    currencyFromSink.add(value);
  }

  updateToCurrency(value){
    _selectedToCurrency = value;
    currencyToSink.add(value);
  }

  updateResult(){

  }

  @override
  void dispose() {
    _multiplierStreamController.close();
    _currencyFromStreamController.close();
    _currencyToStreamController.close();
    _conversionResultStreamController.close();
  }

}