import 'dart:async';

import 'package:charts_flutter/flutter.dart';
import 'package:cotacao_direta/blocs/base_bloc.dart';
import 'package:cotacao_direta/model/currency.dart';
import 'package:cotacao_direta/repository/currency_repository.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SelectedCurrencyDetailsBloc extends BaseBloc {
  StreamController _selectedCurrencyHistoryDataStreamController =
  StreamController();

  TextEditingController _initialDateController = TextEditingController();

  TextEditingController _endDateController = TextEditingController();

  final _currencyRepository = CurrencyRepository();

  get currencyHistoryStream =>
      _selectedCurrencyHistoryDataStreamController.stream;

  get initialDateController => _initialDateController;

  get endDateController => _endDateController;

  getCurrencyHistoryData(String selectedCurrencyCod, String initialDate,
      String finalDate) async {
    var currencyList = await _currencyRepository.getCurrencyHistoricalData(
        [selectedCurrencyCod], initialDate, finalDate);
    _selectedCurrencyHistoryDataStreamController.sink.add(
        Series<Currency, DateTime>(
            id: selectedCurrencyCod,
            data: currencyList,
            domainFn: (Currency currency, _) =>
                DateFormat("yyyy-MM-dd").parse(currency.historicalDate),
            measureFn: (Currency currency, _) => currency.value));
  }

  @override
  void dispose() {
    _selectedCurrencyHistoryDataStreamController.close();
  }
}
