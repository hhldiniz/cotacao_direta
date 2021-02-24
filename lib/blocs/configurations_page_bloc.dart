import 'dart:async';

import 'package:cotacao_direta/blocs/base_bloc.dart';

class ConfigurationsPageBloc extends BaseBloc {
  StreamController _currencyOptionsStreamController = StreamController();

  StreamController _overrideDefaultCurrencyValueStreamController =
      StreamController.broadcast();

  StreamController _selectedCurrencyCodeStreamController = StreamController();

  Stream get currencyOptionsStream => _currencyOptionsStreamController.stream;

  Stream get overrideDefaultCurrencyValueStream =>
      _overrideDefaultCurrencyValueStreamController.stream;

  Stream get selectedCurrencyCodeStream =>
      _selectedCurrencyCodeStreamController.stream;

  Sink get overrideDefaultCurrencyValueSink =>
      _overrideDefaultCurrencyValueStreamController.sink;

  updateSelectedOverrideCurrency(String currencyController) {
    _selectedCurrencyCodeStreamController.sink.add(currencyController);
  }

  @override
  void dispose() {
    _currencyOptionsStreamController.close();
    _overrideDefaultCurrencyValueStreamController.close();
    _selectedCurrencyCodeStreamController.close();
  }
}
