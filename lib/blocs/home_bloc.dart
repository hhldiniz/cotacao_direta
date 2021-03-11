import 'dart:async';

import 'package:cotacao_direta/blocs/base_bloc.dart';
import 'package:cotacao_direta/enums/currency_enum.dart';
import 'package:cotacao_direta/model/configuration.dart';
import 'package:cotacao_direta/repository/configuration_repository.dart';
import 'package:cotacao_direta/util/string_utils.dart';

class HomeBloc extends BaseBloc {
  ConfigurationRepository _configurationRepository = ConfigurationRepository();
  StreamController _headsUpTextStreamController = StreamController();

  Stream get headsUpTextStream => _headsUpTextStreamController.stream;

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
