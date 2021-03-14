import 'dart:async';

import 'package:cotacao_direta/blocs/base_bloc.dart';
import 'package:cotacao_direta/enums/currency_enum.dart';
import 'package:cotacao_direta/model/configuration.dart';
import 'package:cotacao_direta/repository/configuration_repository.dart';
import 'package:cotacao_direta/util/string_utils.dart';

class HomeBloc extends BaseBloc {
  ConfigurationRepository _configurationRepository = ConfigurationRepository();
  StreamController<String> _headsUpTextStreamController;

  Stream<String> getNextStreamController(){
    if(_headsUpTextStreamController == null){
      _headsUpTextStreamController = StreamController();
      return _headsUpTextStreamController.stream;
    } else if(!_headsUpTextStreamController.hasListener){
      return _headsUpTextStreamController.stream;
    } else {
      _headsUpTextStreamController.close();
      _headsUpTextStreamController = StreamController();
      return _headsUpTextStreamController.stream;
    }
  }

  getSelectedOverrideCurrency() {
    _configurationRepository
        .getConfiguration()
        .then((Configuration configuration) {
      if (configuration.overrideDefaultCurrency) {
        _headsUpTextStreamController.sink
            .add(configuration.selectedOverrideCurrencyCode);
      } else {
        _headsUpTextStreamController.sink
            .add(EnumValueAsString().getEnumValue(Currencies.USD.toString()));
      }
    });
  }

  @override
  void dispose() {
    _headsUpTextStreamController.close();
  }
}
