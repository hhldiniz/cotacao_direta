import 'dart:async';

import 'package:cotacao_direta/blocs/base_bloc.dart';
import 'package:cotacao_direta/repository/currency_repository.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SelectedCurrencyDetailsBloc extends BaseBloc {
  StreamController _selectedCurrencyHistoryDataStreamController =
  StreamController();

  final DateFormat _viewDateFormatter = DateFormat("dd/MM/yyyy");
  final DateFormat _apiDateFormatter = DateFormat("yyyy-MM-dd");

  TextEditingController _initialDateController = TextEditingController();

  TextEditingController _endDateController = TextEditingController();

  String _initialDate = "";

  String _finalDate = "";

  final _currencyRepository = CurrencyRepository();

  get currencyHistoryStream =>
      _selectedCurrencyHistoryDataStreamController.stream;

  TextEditingController get initialDateController => _initialDateController;

  TextEditingController get endDateController => _endDateController;

  getCurrencyHistoryData(String selectedCurrencyCod) async {
    // O resultado é descartado por enquanto: o bloco que montava a série do
    // gráfico está comentado abaixo, esperando a troca da biblioteca. A busca
    // continua valendo porque guarda o histórico no banco.
    await _currencyRepository.getCurrencyHistoricalData(
        [selectedCurrencyCod], _initialDate, _finalDate);
    // TODO Replace this block when the chart library gets replaced. O valor
    // devolvido pela chamada acima volta a ser usado como `currencyList`.
    // var dataToAdd = <Series<dynamic, DateTime>>[];
    /*dataToAdd.add(
        Series<Currency, DateTime>(
            id: selectedCurrencyCod,
            data: currencyList,
            domainFn: (Currency currency, _) =>
                DateFormat("yyyy-MM-dd").parse(currency.historicalDate!),
            measureFn: (Currency currency, _) => currency.value)
    );*/
    // _selectedCurrencyHistoryDataStreamController.sink.add(dataToAdd);
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
    // Os campos de data são ChangeNotifier: sem dispose, os ouvintes ficam
    // presos ao bloc depois que a tela sai.
    _initialDateController.dispose();
    _endDateController.dispose();
  }
}
