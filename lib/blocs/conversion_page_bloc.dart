import 'dart:async';

import 'package:cotacao_direta/blocs/base_bloc.dart';
import 'package:cotacao_direta/enums/currency_enum.dart';
import 'package:cotacao_direta/util/string_utils.dart';

import 'exchange_value_bloc.dart';

class ConversionPageBloc extends BaseBloc{

  var _multiplierStreamController = StreamController();
  var _currencyFromStreamController = StreamController();
  var _currencyToStreamController = StreamController();
  var _conversionResultStreamController = StreamController();
  var _currencyLabelStreamController = StreamController();

  final enumAsValueUtil = EnumValueAsString();

  final _exchangeValueBloc = ExchangeValueBloc();

  var _multiplierValue = 0.0;
  Currencies? _selectedFromCurrency = Currencies.BRL;
  Currencies? _selectedToCurrency = Currencies.USD;

  Stream get multiplierStream => _multiplierStreamController.stream;

  Sink get multiplierSink => _multiplierStreamController.sink;

  Stream get currencyFromStream => _currencyFromStreamController.stream;

  Sink get currencyFromSink => _currencyFromStreamController.sink;

  Stream get currencyToStream => _currencyToStreamController.stream;

  Sink get currencyToSink => _currencyToStreamController.sink;

  Stream get conversionResultStream => _conversionResultStreamController.stream;

  Sink get conversionResultSink => _conversionResultStreamController.sink;

  Stream get currencyLabelStream => _currencyLabelStreamController.stream;

  Sink get currencyLabelSink => _currencyLabelStreamController.sink;

  updateMultiplierValue(value){
    _multiplierValue = value == null || value == "" ? 0 : value;
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

  updateResult() async{
    var fromValue = await (_exchangeValueBloc.retrieveCurrencyValue(_selectedFromCurrency) as FutureOr<double>);
    var toValue = await (_exchangeValueBloc.retrieveCurrencyValue(_selectedToCurrency) as FutureOr<double>);
    conversionResultSink.add(_multiplierValue * (toValue / fromValue));
  }

  switchCurrencies() async{
    var currentSelectedToCurrency = _selectedToCurrency;
    var currentSelectedFromCurrency = _selectedFromCurrency;
    updateFromCurrency(currentSelectedToCurrency);
    updateToCurrency(currentSelectedFromCurrency);
  }

  @override
  void dispose() {
    _multiplierStreamController.close();
    _currencyFromStreamController.close();
    _currencyToStreamController.close();
    _conversionResultStreamController.close();
    _currencyLabelStreamController.close();
  }

}