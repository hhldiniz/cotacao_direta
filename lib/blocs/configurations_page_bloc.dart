import 'dart:async';

import 'package:cotacao_direta/blocs/base_bloc.dart';
import 'package:cotacao_direta/repository/currency_repository.dart';

class ConfigurationsPageBloc extends BaseBloc {
  CurrencyRepository _currencyRepository = CurrencyRepository();

  StreamController _currencyOptionsStreamController = StreamController();

  StreamController _overrideDefaultCurrencyValueStreamController =
      StreamController.broadcast();

  Stream get currencyOptionsStream => _currencyOptionsStreamController.stream;

  Stream get overrideDefaultCurrencyValueStream =>
      _overrideDefaultCurrencyValueStreamController.stream;

  Sink get overrideDefaultCurrencyValueSink =>
      _overrideDefaultCurrencyValueStreamController.sink;

  populateCurrencyOptions() {}

  @override
  void dispose() {
    _currencyOptionsStreamController.close();
    _overrideDefaultCurrencyValueStreamController.close();
  }
}
