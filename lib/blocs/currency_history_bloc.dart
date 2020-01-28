import 'dart:async';

import 'package:charts_flutter/flutter.dart';
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
  final _dateFormatter = DateFormat("dd/MM/yyyy");

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

  TextEditingController get currencyHistoryFromDateController =>
      _currencyHistoryFromDateController;

  TextEditingController get currencyHistoryToDateController =>
      _currencyHistoryToDateController;

  _dispatchHistoryGraphSeries(List<Currency> currencyList) {
    List<Series>.generate(
        currencyList.length,
        (index) => Series(
            id: 'Histórico',
            data: currencyList,
            domainFn: (currency, _) => currency.value,
            measureFn: (currency, _) => currency.id
        ));
  }

  updateFromDateValue(DateTime value) {
    if (_currencyHistoryToDateController.value.text.isNotEmpty) {
      _retrieveHistoryData(
              _currencyListValues.keys.where((key) => _currencyListValues[key]).toList(),
              _dateFormatter.parse(_currencyHistoryToDateController.value.text).toIso8601String(),
              value.toIso8601String())
          .then(_dispatchHistoryGraphSeries);
    }
  }

  updateToDateValue(DateTime value) {
    if (_currencyHistoryFromDateController.value.text.isNotEmpty) {
      _retrieveHistoryData(
              _currencyListValues.keys.where((key) => _currencyListValues[key]).toList(),
              _dateFormatter.parse(_currencyHistoryFromDateController.value.text).toIso8601String(),
              value.toIso8601String())
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
