import 'dart:async';

import 'package:cotacao_direta/blocs/base_bloc.dart';
import 'package:cotacao_direta/enums/currency_enum.dart';
import 'package:cotacao_direta/model/currency.dart';
import 'package:cotacao_direta/repository/currency_repository.dart';
import 'package:cotacao_direta/util/string_utils.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

class CurrencyHistoryBloc extends BaseBloc {
  final _currencyHistoryFromDateController = TextEditingController();
  final _currencyHistoryToDateController = TextEditingController();
  final _currencyListStreamController = Map<String, StreamController>();
  final _currencyListValues = Map<String, bool>();
  final _currencyRepository = CurrencyRepository();
  final _historyLineGraphController = StreamController();
  final _dateFormatter = DateFormat("yyyy-MM-dd");
  final _dateParser = DateFormat("dd/MM/yyyy");

  CurrencyHistoryBloc() {
    Currencies.values.forEach((currency) {
      var currencyCode = EnumValueAsString().getEnumValue(currency.toString());
      _currencyListStreamController[currencyCode] =
          StreamController.broadcast();
      _currencyListValues[currencyCode] = false;
    });
  }

  Stream get historyLineGraphController => _historyLineGraphController.stream;

  Stream getCurrencySteam(currencyLabel) =>
      _currencyListStreamController[currencyLabel].stream;

  Stream get historyGraphStream => _historyLineGraphController.stream;

  TextEditingController get currencyHistoryFromDateController =>
      _currencyHistoryFromDateController;

  TextEditingController get currencyHistoryToDateController =>
      _currencyHistoryToDateController;

  _dispatchHistoryGraphSeries(List<Currency> currencyList) {
    _historyLineGraphController.sink.add(currencyList);
  }

  updateFromDateValue(DateTime value) {
    if (_currencyHistoryToDateController.value.text.isNotEmpty) {
      _retrieveHistoryData(
          _currencyListValues.keys
              .where((key) => _currencyListValues[key])
              .toList(),
          _dateFormatter.format(_dateParser
              .parse(currencyHistoryToDateController.value.text)),
          _dateFormatter.format(value))
          .then(_dispatchHistoryGraphSeries);
    }
  }

  updateToDateValue(DateTime value) {
    if (_currencyHistoryFromDateController.value.text.isNotEmpty) {
      _retrieveHistoryData(
          _currencyListValues.keys
              .where((key) => _currencyListValues[key])
              .toList(),
          _dateFormatter.format(_dateParser
              .parse(_currencyHistoryFromDateController.value.text)),
          _dateFormatter.format(value))
          .then(_dispatchHistoryGraphSeries);
    }
  }

  updateCurrencyState(currencyLabel, selected) {
    _currencyListValues[currencyLabel] = selected;
    _currencyListStreamController[currencyLabel].add(selected);
  }

  Future<List<Currency>> _retrieveHistoryData(
      currencyCodeList, initialDate, finalDate) async {
    return _currencyRepository.getCurrencyHistoricalData(
        currencyCodeList, initialDate, finalDate);
  }

  @override
  void dispose() {
    _historyLineGraphController.close();
  }
}
