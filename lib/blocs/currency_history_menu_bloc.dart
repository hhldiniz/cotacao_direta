import 'dart:async';

import 'package:cotacao_direta/blocs/base_bloc.dart';
import 'package:cotacao_direta/repository/country_names_repository.dart';

class CurrencyHistoryMenuBloc extends BaseBloc {
  CountryNamesRepository _countryNameRepository = CountryNamesRepository();
  StreamController _countryNameController = StreamController();

  get countryNameStream => _countryNameController.stream;

  getCountryNameByCurrencyCode(String currencyCode) async {
    String countryName = await _countryNameRepository.getCountryNameByCurrencyCode(currencyCode);
    _countryNameController.sink.add(countryName);
  }

  @override
  void dispose() {
    _countryNameController.close();
  }
}
