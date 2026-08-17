import 'dart:async';

import 'package:cotacao_direta/blocs/base_bloc.dart';
import 'package:cotacao_direta/model/currency.dart';
import 'package:cotacao_direta/repository/currency_repository.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SelectedCurrencyDetailsBloc extends BaseBloc {
  /// Períodos que os chips da tela oferecem como atalho, em dias.
  static const List<int> quickPeriodOptions = [7, 15, 30, 360];

  /// Período com que a tela abre, antes de qualquer escolha do usuário: os
  /// últimos sete dias, o mesmo horizonte do gráfico da tela de conversão.
  static const int defaultPeriodInDays = 7;

  StreamController<List<Currency>> _selectedCurrencyHistoryDataStreamController =
      StreamController<List<Currency>>.broadcast();

  StreamController<bool> _isLoadingStreamController =
      StreamController<bool>.broadcast();

  final StreamController<int?> _selectedPeriodController =
      StreamController<int?>.broadcast();

  final DateFormat _viewDateFormatter = DateFormat("dd/MM/yyyy");
  final DateFormat _apiDateFormatter = DateFormat("yyyy-MM-dd");

  TextEditingController _initialDateController = TextEditingController();

  TextEditingController _endDateController = TextEditingController();

  String _initialDate = "";

  String _finalDate = "";

  /// Qual chip está marcado, ou nulo quando as datas vieram dos seletores
  /// manuais e não correspondem a nenhum atalho.
  int? _selectedPeriodInDays;

  final CurrencyRepository _currencyRepository;

  SelectedCurrencyDetailsBloc({CurrencyRepository? currencyRepository})
      : _currencyRepository = currencyRepository ?? CurrencyRepository();

  Stream<List<Currency>> get currencyHistoryStream =>
      _selectedCurrencyHistoryDataStreamController.stream;

  Stream<bool> get isLoadingStream => _isLoadingStreamController.stream;

  Stream<int?> get selectedPeriodStream => _selectedPeriodController.stream;

  TextEditingController get initialDateController => _initialDateController;

  TextEditingController get endDateController => _endDateController;

  int? get selectedPeriodInDays => _selectedPeriodInDays;

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

  /// Marca o atalho de [days] dias, ajusta os dois campos de data para o
  /// intervalo correspondente (hoje incluído) e já busca o histórico: um chip
  /// é um filtro rápido, não precisa do botão de buscar para valer.
  Future<void> selectPeriod(int days, String currencyCode) async {
    var today = DateTime.now();
    var start = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: days - 1));
    updateInitialDate(start);
    updateFinalDate(today);
    _selectedPeriodInDays = days;
    _selectedPeriodController.add(days);
    await getCurrencyHistoryData(currencyCode);
  }

  updateInitialDate(dateValue){
    initialDateController.text = _viewDateFormatter.format(dateValue);
    _initialDate = _apiDateFormatter.format(dateValue);
    _clearSelectedPeriod();
  }

  updateFinalDate(dateValue){
    _endDateController.text = _viewDateFormatter.format(dateValue);
    _finalDate = _apiDateFormatter.format(dateValue);
    _clearSelectedPeriod();
  }

  /// Uma data escolhida à mão no seletor deixa de corresponder ao atalho
  /// marcado, que também é chamado por [selectPeriod] antes de marcar o chip
  /// novo — por isso só emite quando havia mesmo um chip para desmarcar.
  void _clearSelectedPeriod() {
    if (_selectedPeriodInDays == null) return;
    _selectedPeriodInDays = null;
    _selectedPeriodController.add(null);
  }

  @override
  void dispose() {
    _selectedCurrencyHistoryDataStreamController.close();
    _isLoadingStreamController.close();
    _selectedPeriodController.close();
    // Os campos de data são ChangeNotifier: sem dispose, os ouvintes ficam
    // presos ao bloc depois que a tela sai.
    _initialDateController.dispose();
    _endDateController.dispose();
  }
}
