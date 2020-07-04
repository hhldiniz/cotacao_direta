import 'dart:async';

import 'package:cotacao_direta/blocs/base_bloc.dart';
import 'package:cotacao_direta/repository/country_names_repository.dart';

class CurrencyHistoryMenuBloc extends BaseBloc {
  CountryNamesRepository _countryNameRepository = CountryNamesRepository();
  Map _countryNameControllerMap = Map<String, StreamController>();
  Map _savedCountryNamesByCurrencyCod = Map<String, String>();

  void initStreamControllers(List<String> currencyCodList) {
    currencyCodList.forEach((element) {
      _countryNameControllerMap[element] = StreamController();
    });
  }

  Stream getCountryNameController(String currencyCod){
    return _countryNameControllerMap[currencyCod].stream.asBroadcastStream();
  }

  getCountryNameByCurrencyCode(String currencyCode) async {
    if(_savedCountryNamesByCurrencyCod.containsKey(currencyCode)){
      _countryNameControllerMap[currencyCode].sink.add(_savedCountryNamesByCurrencyCod[currencyCode]);
    }
    else{
      String countryName = await _countryNameRepository.getCountryNameByCurrencyCode(currencyCode);
      _countryNameControllerMap[currencyCode].sink.add(countryName);
      _savedCountryNamesByCurrencyCod[currencyCode] = countryName;
    }
  }

  @override
  void dispose() {
    _countryNameControllerMap.forEach((_, value) {
      value.close();
    });
  }
}
