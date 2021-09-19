import 'dart:async';

import 'package:cotacao_direta/blocs/base_bloc.dart';
import 'package:cotacao_direta/model/configuration.dart';
import 'package:cotacao_direta/repository/configuration_repository.dart';
import 'package:cotacao_direta/view/widgets/widget_state_helpers/override_currency_state_helper.dart';

class ConfigurationsPageBloc extends BaseBloc {
  final OverrideCurrencyStateHelper _overrideCurrencyStateHelper =
      OverrideCurrencyStateHelper();
  final ConfigurationRepository _configurationRepository =
      ConfigurationRepository();

  StreamController _currencyOptionsStreamController = StreamController();

  StreamController _overrideDefaultCurrencyValueStreamController =
      StreamController<OverrideCurrencyStateHelper>.broadcast();

  StreamController _selectedCurrencyCodeStreamController = StreamController();

  Stream get currencyOptionsStream => _currencyOptionsStreamController.stream;

  Stream get overrideDefaultCurrencyValueStream =>
      _overrideDefaultCurrencyValueStreamController.stream;

  Sink get overrideDefaultCurrencyValueSink =>
      _overrideDefaultCurrencyValueStreamController.sink;

  OverrideCurrencyStateHelper get overrideCurrencyStateHelper =>
      _overrideCurrencyStateHelper;

  loadCurrentConfiguration() {
    _configurationRepository
        .getConfiguration()
        .then((Configuration configuration) {
      _overrideCurrencyStateHelper.selectedCurrencyOverride =
          configuration.selectedOverrideCurrencyCode;
      _overrideCurrencyStateHelper.enableCurrencyOverride =
          configuration.overrideDefaultCurrency;
      overrideDefaultCurrencyValueSink.add(_overrideCurrencyStateHelper);
    });
  }

  updateSelectedOverrideCurrency(String? currencyCode) {
    _overrideCurrencyStateHelper.selectedCurrencyOverride = currencyCode;
    overrideDefaultCurrencyValueSink.add(_overrideCurrencyStateHelper);
    _configurationRepository
        .getConfiguration()
        .then((Configuration configuration) {
      configuration.selectedOverrideCurrencyCode = currencyCode;
      _configurationRepository.insert(configuration);
    });
  }

  updateOverrideCurrencySwitch(bool enabled) {
    _overrideCurrencyStateHelper.enableCurrencyOverride = enabled;
    overrideDefaultCurrencyValueSink.add(_overrideCurrencyStateHelper);
    _configurationRepository
        .getConfiguration()
        .then((Configuration configuration) {
      configuration.overrideDefaultCurrency = enabled;
      _configurationRepository.insert(configuration);
    });
  }

  @override
  void dispose() {
    _currencyOptionsStreamController.close();
    _overrideDefaultCurrencyValueStreamController.close();
    _selectedCurrencyCodeStreamController.close();
  }
}
