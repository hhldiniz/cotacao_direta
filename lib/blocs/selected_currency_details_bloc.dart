import 'dart:async';

import 'package:cotacao_direta/blocs/base_bloc.dart';

class SelectedCurrencyDetailsBloc extends BaseBloc {

  StreamController _selectedCurrencyHistoryDataStreamController = StreamController();

  @override
  void dispose() {
    _selectedCurrencyHistoryDataStreamController.close();
  }
}
