import 'dart:async';

import 'package:cotacao_direta/blocs/base_bloc.dart';
import 'package:cotacao_direta/model/currency.dart';
import 'package:cotacao_direta/repository/currency_repository.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SelectedCurrencyDetailsBloc extends BaseBloc {
  StreamController<List<Currency>> _selectedCurrencyHistoryDataStreamController =
      StreamController<List<Currency>>.broadcast();

  StreamController<bool> _isLoadingStreamController =
      StreamController<bool>.broadcast();

  final DateFormat _viewDateFormatter = DateFormat("dd/MM/yyyy");
  final DateFormat _apiDateFormatter = DateFormat("yyyy-MM-dd");

  TextEditingController _initialDateController = TextEditingController();

  TextEditingController _endDateController = TextEditingController();

  String _initialDate = "";

  String _finalDate = "";

  final _currencyRepository = CurrencyRepository();

  Stream<List<Currency>> get currencyHistoryStream =>
      _selectedCurrencyHistoryDataStreamController.stream;

  Stream<bool> get isLoadingStream => _isLoadingStreamController.stream;

  TextEditingController get initialDateController => _initialDateController;

  TextEditingController get endDateController => _endDateController;

  getCurrencyHistoryData(String selectedCurrencyCod) async {
    _isLoadingStreamController.sink.add(true);
    try {
      var currencyList = await _currencyRepository.getCurrencyHistoricalData(
          [selectedCurrencyCod], _initialDate, _finalDate);
      _selectedCurrencyHistoryDataStreamController.sink.add(currencyList);
    } finally {
      _isLoadingStreamController.sink.add(false);
    }
  }

  updateInitialDate(dateValue){
    initialDateController.text = _viewDateFormatter.format(dateValue);
    _initialDate = _apiDateFormatter.format(dateValue);
  }

  updateFinalDate(dateValue){
    _endDateController.text = _viewDateFormatter.format(dateValue);
    _finalDate = _apiDateFormatter.format(dateValue);
  }

  @override
  void dispose() {
    _selectedCurrencyHistoryDataStreamController.close();
    _isLoadingStreamController.close();
    // Os campos de data são ChangeNotifier: sem dispose, os ouvintes ficam
    // presos ao bloc depois que a tela sai.
    _initialDateController.dispose();
    _endDateController.dispose();
  }
}
