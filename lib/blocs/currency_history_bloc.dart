import 'dart:async';

import 'package:cotacao_direta/blocs/base_bloc.dart';
import 'package:flutter/widgets.dart';

class CurrencyHistoryBloc extends BaseBloc {
  var _currencyHistoryFromDateStreamController = StreamController();
  var _currencyHistoryToDateStreamController = StreamController();
  final _currencyHistoryFromDateController = TextEditingController();
  final _currencyHistoryToDateController = TextEditingController();

  Stream get currencyHistoryFromDateStream =>
      _currencyHistoryFromDateStreamController.stream;

  Stream get currencyHistoryToDateStream =>
      _currencyHistoryToDateStreamController.stream;

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

  @override
  void dispose() {
    _currencyHistoryFromDateStreamController.close();
    _currencyHistoryToDateStreamController.close();
  }
}
